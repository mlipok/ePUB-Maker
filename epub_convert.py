"""Convert saved pages using the Python runtime supplied by calibre."""

import argparse
from collections import Counter
from email import policy
from email.parser import BytesParser
import mimetypes
import os
from pathlib import Path
import re
from tempfile import TemporaryDirectory
from urllib.parse import urldefrag, urljoin
from zipfile import ZipFile


HTML = {".html", ".htm"}
MHTML = {".mhtml", ".mht"}
SUPPORTED = HTML | MHTML
CSS_URL = re.compile(r"""url\(\s*(?:"([^"]*)"|'([^']*)'|([^)]*?))\s*\)""", re.I)
CSS_IMPORT = re.compile(r"""(@import\s+)(["'])(.*?)\2""", re.I)
MEDIA_SUFFIXES = {
    "text/css": ".css", "image/svg+xml": ".svg", "image/jpeg": ".jpg",
    "font/woff": ".woff", "font/woff2": ".woff2", "font/ttf": ".ttf",
    "font/otf": ".otf", "application/font-woff": ".woff",
}


def report(kind, percent, message):
    # ASCII framing keeps Unicode paths intact across the AutoIt stdout pipe.
    encoded = message.encode("utf-8", errors="replace").hex()
    print(f"EPUBMAKER|{kind}|{percent}|{encoded}", flush=True)


def unpack_mhtml(source, folder):
    """Restore the main HTML and the captured CSS, images and fonts."""
    from lxml import etree, html

    with source.open("rb") as stream:
        archive = BytesParser(policy=policy.default).parse(stream)
    parts = [part for part in archive.walk() if not part.is_multipart()]
    html_parts = [part for part in parts if part.get_content_type() == "text/html"]
    if not html_parts:
        raise ValueError("MHTML contains no HTML document.")
    start = archive.get_param("start")
    main = next((part for part in html_parts if start and part["Content-ID"] == start),
                html_parts[0])
    document_url = str(main["Content-Location"] or archive["Content-Location"]
                       or archive["Snapshot-Content-Location"] or "")
    resources = {}
    assets = []
    for part in parts:
        mime = part.get_content_type()
        suffix = MEDIA_SUFFIXES.get(mime)
        if suffix is None and mime.startswith(("image/", "font/")):
            suffix = mimetypes.guess_extension(mime, strict=False)
        if not suffix:
            continue
        payload = part.get_payload(decode=True)
        if not payload:
            continue
        location = str(part["Content-Location"] or "")
        content_id = str(part["Content-ID"] or "").strip("<>")
        name = f"asset-{len(assets) + 1}{suffix}"
        if location:
            resources.setdefault(urldefrag(urljoin(document_url, location))[0], name)
        if content_id:
            resources.setdefault("cid:" + content_id, name)
        assets.append((part, payload, name, urljoin(document_url, location)))

    def reference(value, base):
        target = value.strip()
        if not target or target.startswith("#") or target.lower().startswith("data:"):
            return target
        absolute, fragment = urldefrag(urljoin(base, target))
        if absolute in resources:
            return resources[absolute] + ("#" + fragment if fragment else "")
        if absolute.lower().startswith(("https://", "http://")):
            return urljoin(base, target)
        return ""

    def css(text, base):
        text = CSS_IMPORT.sub(
            lambda match: '@import "' + reference(match[3], base).replace('"', "%22") + '"',
            text,
        )
        return CSS_URL.sub(
            lambda match: 'url("' + reference(next(x for x in match.groups() if x is not None),
                                               base).replace('"', "%22") + '")',
            text,
        )

    for part, payload, name, base in assets:
        if part.get_content_type() == "text/css":
            text = payload.decode(part.get_content_charset() or "utf-8", errors="replace")
            text = re.sub(r"""^\s*@charset\s+["'][^"']*["']\s*;""", "", text, flags=re.I)
            payload = css(text, base).encode("utf-8")
        (folder / name).write_bytes(payload)

    payload = main.get_payload(decode=True)
    if not payload:
        raise ValueError("The main MHTML document is empty.")
    parser = html.HTMLParser(encoding=main.get_content_charset())
    document = html.document_fromstring(payload, parser=parser)
    base = urljoin(document_url, document.xpath("string(//base[1]/@href)"))
    for element in document.xpath("//base|//script|//iframe|//object|//embed|"
                                  "//meta[translate(@http-equiv,'REFSH','refsh')='refresh']"):
        element.drop_tree()
    for element in document.iter(etree.Element):
        for attr in list(element.attrib):
            if attr.lower().startswith("on"):
                del element.attrib[attr]
        for attr in ("src", "href", "poster", "background", "xlink:href"):
            if attr in element.attrib:
                value = reference(element.get(attr), base)
                if value:
                    element.set(attr, value)
                else:
                    del element.attrib[attr]
        # Preserve the primary image and ordinary archived srcset candidates.
        srcset = element.get("srcset")
        if srcset and not re.search(r"\bdata:", srcset, re.I):
            candidates = []
            for candidate in srcset.split(","):
                fields = candidate.split()
                if fields:
                    value = reference(fields[0], base)
                    if value:
                        candidates.append(" ".join([value, *fields[1:]]))
            element.set("srcset", ", ".join(candidates))
        if "style" in element.attrib:
            element.set("style", css(element.get("style"), base))
        if element.tag == "style" and element.text:
            element.text = css(element.text, base)
    restored = folder / (source.stem + ".html")
    restored.write_bytes(html.tostring(document, encoding="utf-8", include_meta_content_type=True))
    return restored


def convert(source, destination):
    from calibre.ebooks.conversion.cli import main as calibre_convert

    if destination.exists():
        raise FileExistsError(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory(prefix=".epub-maker-", dir=destination.parent) as scratch:
        scratch = Path(scratch)
        staged = scratch / "result.epub"
        input_file = unpack_mhtml(source, scratch) if source.suffix.lower() in MHTML else source
        if calibre_convert(["ebook-convert", str(input_file), str(staged), "--epub-version", "3"]):
            raise ValueError("calibre conversion failed.")
        with ZipFile(staged) as epub:
            if epub.read("mimetype") != b"application/epub+zip" or not epub.read("META-INF/container.xml"):
                raise ValueError("The converter did not produce an EPUB package.")
        # Publish a complete EPUB and preserve an output created by another run.
        if os.name == "nt":
            staged.rename(destination)
        else:
            os.link(staged, destination)


def batch_plan(source, output, naming, errors):
    plan = []
    for folder, subdirs, files in os.walk(source, onerror=errors.append):
        parent = Path(folder)
        subdirs[:] = sorted((name for name in subdirs if not is_link(parent / name)), key=str.casefold)
        inputs = sorted((parent / name for name in files
                         if Path(name).suffix.lower() in SUPPORTED and not is_link(parent / name)),
                        key=lambda path: path.name.casefold())
        counts = Counter(path.stem.casefold() for path in inputs)
        qualified = {path for path in inputs if naming == "always" or counts[path.stem.casefold()] > 1}
        reserved = {(path.name + ".epub").casefold() for path in qualified}
        # A qualified name can itself collide with another file's plain name.
        for path in sorted(inputs, key=lambda item: len(item.name)):
            if (path.stem + ".epub").casefold() in reserved:
                qualified.add(path)
                reserved.add((path.name + ".epub").casefold())
        target_folder = output / parent.relative_to(source)
        for path in inputs:
            name = (path.name if path in qualified else path.stem) + ".epub"
            plan.append((path, target_folder / name))
    return plan


def is_link(path):
    try:
        return bool(getattr(path.lstat(), "st_file_attributes", 0) & 0x400) or path.is_symlink()
    except OSError:
        return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["single", "batch"])
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--naming", choices=["always", "conflict"], default="conflict")
    args = parser.parse_args()
    source, output = args.source.resolve(), args.output.resolve()
    errors = []
    if not output.is_dir():
        raise ValueError("Choose an existing output folder.")
    if args.mode == "single":
        if not source.is_file() or source.suffix.lower() not in SUPPORTED:
            raise ValueError("Select an existing HTML or MHTML file.")
        plan = [(source, output / (source.stem + ".epub"))]
    else:
        if not source.is_dir():
            raise ValueError("Choose an existing source folder.")
        if source.is_relative_to(output) or output.is_relative_to(source):
            raise ValueError("Choose a separate output folder outside the source tree.")
        report("status", 0, "Scanning the source folder and subfolders...")
        plan = batch_plan(source, output, args.naming, errors)
    for error in errors:
        report("detail", 0, str(error))
    converted = skipped = failed = 0
    total = len(plan)
    for index, (path, destination) in enumerate(plan, 1):
        label = str(path.relative_to(source)) if args.mode == "batch" else path.name
        report("status", (index - 1) * 100 // total, f"{index}/{total}  {label}")
        try:
            if destination.parent.resolve() != destination.parent:
                raise ValueError("The output path contains a folder link.")
            convert(path, destination)
        except FileExistsError:
            skipped += 1
            report("detail", 0, f"Skipped {label}: {destination.name} already exists.")
        except (Exception, SystemExit) as error:
            failed += 1
            report("detail", 0, f"Failed {label}: {error}")
        else:
            converted += 1
    if total or errors:
        summary = f"Converted: {converted}  |  Skipped: {skipped}  |  Failed: {failed}"
        if errors:
            summary += f"  |  Scan errors: {len(errors)}"
    else:
        summary = "No HTML or MHTML files found."
    report("result", 100 if total else 0, summary)


if __name__ == "__main__":
    try:
        main()
    except (Exception, SystemExit) as error:
        report("detail", 0, str(error))
        report("result", 0, "Conversion could not start. See details.")
        raise SystemExit(1)
