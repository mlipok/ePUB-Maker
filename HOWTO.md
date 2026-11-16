# HOWTO

## First prototype workflow

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

The first prototype is a resource extractor, not yet a complete web-to-EPUB converter. It does not process MHTML or create the EPUB container, package metadata, XHTML spine, or table of contents.

## Local WebView2 UDF copy

The `UDF` directory is a local synchronized copy and is not intended for GitHub publication. Refresh it from:

```text
Z:\!!!_SVN_AU3\UDF_AI\WebView2\
```

## Development checks

For AutoIt source changes, use the local tools documented by the AutoIt project instructions:

```text
Z:\AutoItPortable\App\SciTE\Tidy\Tidy.exe
Z:\AutoItPortable\App\Au3Check.exe
```

The source file must remain UTF-8 without BOM and use CRLF line endings.
