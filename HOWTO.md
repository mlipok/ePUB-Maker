# HOWTO

## Convert a single saved file to EPUB

1. Install calibre and keep `epub_convert.py` beside the app. Select `calibre-debug.exe` with **Calibre location...** if the standard installation is not detected.
2. Open **Single file** and choose an HTML or MHTML file, or select it from the file list.
3. Choose an output folder and click **Convert to EPUB**.

## Convert a folder tree to EPUB

1. Open **Batch processing** and choose the source folder and a separate, existing output folder.
2. Choose the naming rule. The default produces `Almuric.epub` for a unique source name. If `Almuric.html` and `Almuric.mhtml` are in the same folder, the outputs are `Almuric.html.epub` and `Almuric.mhtml.epub`. Select **Always include the source extension in the EPUB name** to apply that naming rule to every file.
3. Click **Convert folder to EPUB**. Use the progress bar and the summary to follow the work and review skipped or failed files.

For example, `Archive\Books\Almuric.html` can produce `Archive_EPUB\Books\Almuric.epub`. Existing EPUBs are skipped, including when you run the same job again.

## Extract resources for Sigil

1. Start `EPUB_Maker.au3` with AutoIt 3, or run the compiled executable.
2. Enter a URL in the browser address field and select **Go**, or use **Load HTML / MHTML folder**.
3. Select an item in the list to preview it in the right-hand browser panel.
4. Choose an empty or dedicated output folder.
5. Select **Export selected item**, or use **Extract current page** for the currently displayed page.
6. Open the generated HTML file in Sigil together with the `_files` folder.

The prototype writes files such as `_files/resource_001.jpg` and replaces matching embedded data URLs in the copied HTML with relative paths. It preserves the original source file. Folder loading is non-recursive in this version.

## Reproducing a problem

For each test case, keep:

- the original single HTML file;
- the exact Sigil error message;
- the Sigil version;
- the generated HTML file and `_files` folder;
- the URL from which the page was saved, if it is available.

For EPUB conversion issues, also include the source file type, the calibre version and the details shown by ePUB Maker.

## Project instructions and local WebView2 UDF copy

The shared AutoIt project instructions are maintained in [AutoIt3-AGENTS.md](https://github.com/mlipok/AutoIt3-AGENTS.md). Synchronize the current `AGENTS*.md` files from that repository when preparing or maintaining this project.

The `UDF` directory is a local synchronized copy of the WebView2 UDF and is not intended for GitHub publication. Keep it synchronized with the separately maintained WebView2 UDF source used for local development. The matching WebView2Loader files are also local-only runtime dependencies.

## Development checks

For AutoIt source changes, use the local tools documented by the AutoIt project instructions:

```text
Z:\AutoItPortable\App\SciTE\Tidy\Tidy.exe
Z:\AutoItPortable\App\Au3Check.exe
```

The source file must remain UTF-8 without BOM and use CRLF line endings.

## Licensing

The ePUB Maker source code and original project documentation are licensed under MIT; see [LICENSE](LICENSE).

The copied AutoIt instruction files come from [AutoIt3-AGENTS.md](https://github.com/mlipok/AutoIt3-AGENTS.md). Retain their attribution, source links and licensing notices. The original material from that repository is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

`AGENTS_AutoIt3_Best_coding_practices.md`, `AGENTS_AutoIt3_Function_notes.md` and `AGENTS_AutoIt3_UDF-spec.md` are excluded from that CC BY 4.0 grant and remain subject to their original terms. Keep [AutoIt-EULA.md](AutoIt-EULA.md) with the copied AutoIt documentation and do not treat these reference files as MIT-licensed ePUB Maker code.
