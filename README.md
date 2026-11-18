# ePUB Maker

The first prototype shows a WebView2 browser preview on the right and extracts Base64-embedded resources from HTML or MHTML sources into a Sigil-friendly result:

```text
output-folder/
  input.html
  _files/
    resource_001.jpg
    resource_002.woff2
```

The application is written in AutoIt and has an English user interface. It currently handles standard `data:<mime>;base64,...` URLs found in HTML, CSS and related inline content. It does not yet create an EPUB package.

## Usage

1. Run or compile `EPUB_Maker.au3` with AutoIt 3.
2. Navigate to a URL in the right-hand browser, or load a folder containing HTML/MHTML files.
3. Select a loaded file to preview it in the browser.
4. Select an output folder.
5. Click **Extract selected item** or **Extract current page**.
6. Import the generated HTML file and its `_files` folder into Sigil.

The output folder is intentionally selected separately from the source folder. Existing files with generated names are overwritten in that selected output folder.

## WebView2 UDF dependency

The ePUB Maker requires the native WebView2 UDF for AutoIt.

Download the current UDF from:

https://github.com/mlipok/WebView2.au3-NativeAutoIt3-UDF

Copy the required UDF files into the local `UDF` directory of this project.

If the local `UDF` directory is present, it is ignored by Git and is not tracked, published, or synchronized by this repository. The ePUB Maker repository does not contain a copy of the WebView2 UDF. The user is responsible for downloading and updating this dependency separately.

The matching `WebView2Loader.dll` files are also required for the browser preview.

The AutoIt project instructions are maintained separately in [AutoIt3-AGENTS.md](https://github.com/mlipok/AutoIt3-AGENTS.md). Synchronize the current `AGENTS*.md` instructions from that project when setting up or updating this project.

## Scope and limitations

- Only Base64 data URLs are extracted in this version.
- External URLs and ordinary relative files are left unchanged.
- The tool does not validate the HTML or EPUB structure.
- A loaded folder is currently scanned non-recursively.
- MHTML preview/export uses the HTML source exposed by WebView2 after navigation.
- Duplicate detection is not yet content-based; repeated identical URLs are processed in the same run as separate occurrences.
- MHTML input and direct EPUB creation are planned for later versions.

## License

The ePUB Maker source code and original project documentation are licensed under the MIT License. See [LICENSE](LICENSE).

The copied `AGENTS*.md` files are shared AutoIt project instructions from [AutoIt3-AGENTS.md](https://github.com/mlipok/AutoIt3-AGENTS.md). They must retain their original attribution, source links and licensing notices. Original material from that project is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), as described by its [LICENSE.md](https://github.com/mlipok/AutoIt3-AGENTS.md/blob/main/LICENSE.md).

The following copied documents are excluded from the CC BY 4.0 grant and remain subject to their original terms:

- `AGENTS_AutoIt3_Best_coding_practices.md` — AutoIt Wiki source and its original terms;
- `AGENTS_AutoIt3_Function_notes.md` — AutoIt documentation and the AutoIt EULA;
- `AGENTS_AutoIt3_UDF-spec.md` — AutoIt Wiki source and its original terms.

When redistributing these instruction files, preserve the notices and source links. The accompanying [AutoIt-EULA.md](AutoIt-EULA.md) is retained for the AutoIt documentation covered by the EULA. Using the instructions does not relicense the ePUB Maker source or any independent project code under CC BY 4.0.
