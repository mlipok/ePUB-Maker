# ePUB Maker

ePUB Maker converts saved HTML and MHTML documents to EPUB 3. It also provides a WebView2 browser preview and a separate Base64 resource extraction workflow for Sigil:

```text
output-folder/
  input.html
  _files/
    resource_001.jpg
    resource_002.woff2
```

The application is written in AutoIt and has an English user interface.

## Usage

**Single file** previews local files or web pages, extracts Base64 resources for Sigil, and converts a selected local HTML or MHTML file to EPUB. **Batch processing** converts every HTML or MHTML file in a source folder and its subfolders, mirrors the directory structure in a separate output folder, and shows progress and a conversion summary in the window.

For example, `Archive/Books/Almuric.html` becomes `Archive_EPUB/Books/Almuric.epub`. If the same folder also contains `Almuric.mhtml`, the outputs are `Almuric.html.epub` and `Almuric.mhtml.epub`. Select **Always include the source extension in the EPUB name** to use these qualified names for every file.

Install calibre for EPUB conversion and keep `epub_convert.py` beside `EPUB_Maker.au3` or the compiled executable. For a portable installation, use **Calibre location...** to select `calibre-debug.exe`. The helper uses calibre's embedded Python runtime. See [calibre for Windows](https://calibre-ebook.com/download_windows) and [HOWTO](HOWTO.md).

## WebView2 UDF dependency

The ePUB Maker requires the native WebView2 UDF for AutoIt.

Download the current UDF from:

https://github.com/mlipok/WebView2.au3-NativeAutoIt3-UDF

Copy the required UDF files into the local `UDF` directory of this project.

If the local `UDF` directory is present, it is ignored by Git and is not tracked, published, or synchronized by this repository. The ePUB Maker repository does not contain a copy of the WebView2 UDF. The user is responsible for downloading and updating this dependency separately.

The matching `WebView2Loader.dll` files are also required for the browser preview.

The AutoIt project instructions are maintained separately in [AutoIt3-AGENTS.md](https://github.com/mlipok/AutoIt3-AGENTS.md). Synchronize the current `AGENTS*.md` instructions from that project when setting up or updating this project.

## Scope and limitations

- The file list in **Single file** shows the selected folder. **Batch processing** includes its subfolders and skips junctions and symbolic links.
- EPUB conversion accepts local `.html`, `.htm`, `.mhtml` and `.mht` files. MHTML conversion restores the main HTML page and captured stylesheets, images and fonts. Embedded frames and scripts are excluded from the MHTML conversion.
- Existing EPUBs are skipped. The separate HTML resource extraction workflow can overwrite files with matching names in its output folder.

## License

The ePUB Maker source code and original project documentation are licensed under the MIT License. See [LICENSE](LICENSE).

The copied `AGENTS*.md` files are shared AutoIt project instructions from [AutoIt3-AGENTS.md](https://github.com/mlipok/AutoIt3-AGENTS.md). They must retain their original attribution, source links and licensing notices. Original material from that project is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), as described by its [LICENSE.md](https://github.com/mlipok/AutoIt3-AGENTS.md/blob/main/LICENSE.md).

The following copied documents are excluded from the CC BY 4.0 grant and remain subject to their original terms:

- `AGENTS_AutoIt3_Best_coding_practices.md` — AutoIt Wiki source and its original terms;
- `AGENTS_AutoIt3_Function_notes.md` — AutoIt documentation and the AutoIt EULA;
- `AGENTS_AutoIt3_UDF-spec.md` — AutoIt Wiki source and its original terms.

When redistributing these instruction files, preserve the notices and source links. The accompanying [AutoIt-EULA.md](AutoIt-EULA.md) is retained for the AutoIt documentation covered by the EULA. Using the instructions does not relicense the ePUB Maker source or any independent project code under CC BY 4.0.
