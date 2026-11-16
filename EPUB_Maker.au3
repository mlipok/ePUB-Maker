#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <FileConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <ListViewConstants.au3>
#include <MsgBoxConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

#include "UDF\WebView2.au3"

Opt("MustDeclareVars", 1)

Global Const $g_sApplicationName = "ePUB Maker - Base64 resource extractor"
Global Const $g_sVersion = "0.1.0"
Global Const $g_iMainBackgroundColor = 0xC0C0C0
Global Const $g_iButtonBackgroundColor = 0xD6D6D6
Global Const $g_iEditBackgroundColor = 0xF7F7F7
Global $g_iWebView = -1
Global $g_asListedFiles[1] = [0]

Main()

Func Main()
	Local $hGUI = GUICreate($g_sApplicationName & " " & $g_sVersion, 1300, 800, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local $iLeftWidth = 430
	GUICtrlCreateLabel("Local HTML input", 12, 12, 320, 22)
	GUICtrlCreateLabel("Input HTML file:", 12, 42, 105, 22)
	Local $idInput = GUICtrlCreateInput("", 12, 66, 245, 24)
	Local $idInputBrowse = GUICtrlCreateButton("Browse...", 264, 66, 75, 24)
	GUICtrlCreateLabel("Output folder:", 12, 102, 105, 22)
	Local $idOutput = GUICtrlCreateInput("", 12, 126, 245, 24)
	Local $idOutputBrowse = GUICtrlCreateButton("Browse...", 264, 126, 75, 24)
	Local $idProcess = GUICtrlCreateButton("Extract local file", 12, 166, 160, 30)
	Local $idExtractPage = GUICtrlCreateButton("Extract current page", 180, 166, 159, 30)
	Local $idLoadFolder = GUICtrlCreateButton("Load HTML / MHTML folder", 12, 214, 220, 28)
	Local $idExportSelected = GUICtrlCreateButton("Export selected item", 240, 214, 200, 28)
	Local $idFileList = GUICtrlCreateListView("File|Type|Size", 12, 250, 428, 470, BitOR($LVS_REPORT, $LVS_SINGLESEL, $LVS_SHOWSELALWAYS))
	GUICtrlSendMsg($idFileList, $LVM_SETCOLUMNWIDTH, 0, 270)
	GUICtrlSendMsg($idFileList, $LVM_SETCOLUMNWIDTH, 1, 65)
	GUICtrlSendMsg($idFileList, $LVM_SETCOLUMNWIDTH, 2, 80)
	Local $idStatus = GUICtrlCreateLabel("Choose a local file, load a folder, or navigate to a URL.", 12, 730, 428, 40, $SS_SUNKEN)
	Local $idClose = GUICtrlCreateButton("Close", 12, 770, 100, 26)
	GUICtrlCreateLabel("Browser preview", $iLeftWidth + 20, 12, 320, 22)
	Local $idBack = GUICtrlCreateButton("Back", $iLeftWidth + 20, 38, 55, 26)
	Local $idForward = GUICtrlCreateButton("Forward", $iLeftWidth + 80, 38, 65, 26)
	Local $idReload = GUICtrlCreateButton("Reload", $iLeftWidth + 150, 38, 60, 26)
	Local $idStop = GUICtrlCreateButton("Stop", $iLeftWidth + 215, 38, 55, 26)
	Local $idURL = GUICtrlCreateInput("https://example.com/", $iLeftWidth + 275, 38, 505, 26)
	Local $idGo = GUICtrlCreateButton("Go", $iLeftWidth + 790, 38, 55, 26)
	Local $iMessage

	GUISetBkColor($g_iMainBackgroundColor, $hGUI)
	GUICtrlSetBkColor($idInput, $g_iEditBackgroundColor)
	GUICtrlSetBkColor($idOutput, $g_iEditBackgroundColor)
	GUICtrlSetBkColor($idURL, $g_iEditBackgroundColor)
	GUICtrlSetBkColor($idFileList, 0xFFFFFF)
	GUICtrlSetBkColor($idInputBrowse, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idOutputBrowse, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idProcess, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idExtractPage, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idLoadFolder, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idExportSelected, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idClose, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idBack, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idForward, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idReload, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idStop, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idGo, $g_iButtonBackgroundColor)

	GUISetState(@SW_SHOW, $hGUI)
	Local $sProfile = @LocalAppDataDir & "\ePUB Maker\WebView2"
	If _WebView2_Init(Default, $sProfile) Then
		Local $aInitialClient = WinGetClientSize($hGUI)
		$g_iWebView = _WebView2_Create($hGUI, $iLeftWidth + 20, 72, $aInitialClient[0] - $iLeftWidth - 32, $aInitialClient[1] - 84)
		If @error Or $g_iWebView < 0 Then
			$g_iWebView = -1
			GUICtrlSetData($idStatus, "WebView2 could not be created. Local extraction remains available.")
		Else
			_WebView2_Navigate($g_iWebView, GUICtrlRead($idURL))
		EndIf
	Else
		GUICtrlSetData($idStatus, "WebView2 is unavailable. Local extraction remains available.")
	EndIf

	While True
		$iMessage = GUIGetMsg()
		Switch $iMessage
			Case $GUI_EVENT_CLOSE, $idClose
				ExitLoop
			Case $idInputBrowse
				Local $sInput = FileOpenDialog("Select an HTML or MHTML file", @ScriptDir, "HTML/MHTML files (*.html;*.htm;*.mht;*.mhtml)|All files (*.*)", $FD_FILEMUSTEXIST)
				If Not @error Then GUICtrlSetData($idInput, $sInput)
			Case $idOutputBrowse
				Local $sOutput = FileSelectFolder("Select the output folder", @ScriptDir)
				If Not @error Then GUICtrlSetData($idOutput, $sOutput)
			Case $idLoadFolder
				Local $sFolder = FileSelectFolder("Select a folder containing HTML or MHTML files", @ScriptDir)
				If Not @error Then
					Local $iLoaded = _EpubMaker_LoadFolder($sFolder, $idFileList)
					GUICtrlSetData($idStatus, "Loaded files: " & $iLoaded)
				EndIf
			Case $idFileList
				Local $iSelected = _GUICtrlListView_GetNextItem(GUICtrlGetHandle($idFileList), -1, $LVNI_SELECTED)
				If $iSelected >= 0 Then
					Local $sSelected = $g_asListedFiles[$iSelected + 1]
					GUICtrlSetData($idInput, $sSelected)
					If $g_iWebView >= 0 Then _WebView2_Navigate($g_iWebView, __EpubMaker_FileUri($sSelected))
				EndIf
			Case $idExportSelected
				Local $iSelectedForExport = _GUICtrlListView_GetNextItem(GUICtrlGetHandle($idFileList), -1, $LVNI_SELECTED)
				If $iSelectedForExport < 0 Then
					MsgBox($MB_ICONWARNING, $g_sApplicationName, "Select an HTML or MHTML item first.")
					ContinueLoop
				EndIf
				Local $sSelectedForExport = $g_asListedFiles[$iSelectedForExport + 1]
				Local $sSelectedOutput = GUICtrlRead($idOutput)
				Local $iSelectedExtracted = _EpubMaker_ExtractSelected($sSelectedForExport, $sSelectedOutput, $g_iWebView)
				If @error Then
					GUICtrlSetData($idStatus, "Selected item export failed. Error code: " & @error)
					MsgBox($MB_ICONERROR, $g_sApplicationName, "Selected item export failed." & @CRLF & "Error code: " & @error)
				Else
					GUICtrlSetData($idStatus, "Selected item exported. Resources: " & $iSelectedExtracted)
				EndIf
			Case $idProcess
				Local $sInputPath = GUICtrlRead($idInput)
				Local $sOutputPath = GUICtrlRead($idOutput)
				Local $iExtracted = _EpubMaker_ExtractResources($sInputPath, $sOutputPath)
				If @error Then
					GUICtrlSetData($idStatus, "Extraction failed. Error code: " & @error)
					MsgBox($MB_ICONERROR, $g_sApplicationName, "Extraction failed." & @CRLF & "Error code: " & @error)
				Else
					GUICtrlSetData($idStatus, "Finished. Extracted resources: " & $iExtracted)
					MsgBox($MB_ICONINFORMATION, $g_sApplicationName, "Finished." & @CRLF & _
							"Extracted resources: " & $iExtracted & @CRLF & _
							"Output HTML: " & $sOutputPath)
				EndIf
			Case $idExtractPage
				Local $sPageOutput = GUICtrlRead($idOutput)
				Local $iPageExtracted = _EpubMaker_ExtractCurrentPage($g_iWebView, $sPageOutput)
				If @error Then
					GUICtrlSetData($idStatus, "Current page extraction failed. Error code: " & @error)
					MsgBox($MB_ICONERROR, $g_sApplicationName, "Current page extraction failed." & @CRLF & "Error code: " & @error)
				Else
					GUICtrlSetData($idStatus, "Current page extracted resources: " & $iPageExtracted)
					MsgBox($MB_ICONINFORMATION, $g_sApplicationName, "Finished." & @CRLF & _
							"Extracted resources: " & $iPageExtracted & @CRLF & _
							"Output HTML: " & $sPageOutput & "\page.html")
				EndIf
			Case $idBack
				If $g_iWebView >= 0 And _WebView2_CanGoBack($g_iWebView) Then _WebView2_GoBack($g_iWebView)
			Case $idForward
				If $g_iWebView >= 0 And _WebView2_CanGoForward($g_iWebView) Then _WebView2_GoForward($g_iWebView)
			Case $idReload
				If $g_iWebView >= 0 Then _WebView2_Reload($g_iWebView)
			Case $idStop
				If $g_iWebView >= 0 Then _WebView2_Stop($g_iWebView)
			Case $idGo
				If $g_iWebView >= 0 Then _WebView2_Navigate($g_iWebView, GUICtrlRead($idURL))
			Case $GUI_EVENT_RESIZED, $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE
				If $g_iWebView >= 0 Then
					Local $aSize = WinGetClientSize($hGUI)
					If IsArray($aSize) Then _WebView2_SetBounds($g_iWebView, $iLeftWidth + 20, 72, $aSize[0] - $iLeftWidth - 32, $aSize[1] - 84)
				EndIf
		EndSwitch
	WEnd

	If $g_iWebView >= 0 Then $g_iWebView = -1
	_WebView2_Cleanup()
	GUIDelete($hGUI)
EndFunc   ;==>Main

Func _EpubMaker_LoadFolder($sFolder, $idListView)
	If Not FileExists($sFolder) Or Not StringInStr(FileGetAttrib($sFolder), "D") Then Return SetError(1, 0, 0)
	_GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($idListView))
	ReDim $g_asListedFiles[1]
	$g_asListedFiles[0] = 0

	Local $hSearch = FileFindFirstFile($sFolder & "\*")
	If $hSearch = -1 Then Return 0
	Local $sName, $sExtension, $sPath, $iCount = 0
	While True
		$sName = FileFindNextFile($hSearch)
		If @error Then ExitLoop
		If StringInStr(FileGetAttrib($sFolder & "\" & $sName), "D") Then ContinueLoop
		$sExtension = StringLower(StringRegExpReplace($sName, ".*\.", ""))
		If $sExtension <> "html" And $sExtension <> "htm" And $sExtension <> "mht" And $sExtension <> "mhtml" Then ContinueLoop
		$iCount += 1
		ReDim $g_asListedFiles[$iCount + 1]
		$sPath = $sFolder & "\" & $sName
		$g_asListedFiles[$iCount] = $sPath
		GUICtrlCreateListViewItem($sName & "|" & StringUpper($sExtension) & "|" & __EpubMaker_FormatBytes(FileGetSize($sPath)), $idListView)
	WEnd
	FileClose($hSearch)
	$g_asListedFiles[0] = $iCount
	Return $iCount
EndFunc   ;==>_EpubMaker_LoadFolder

; #FUNCTION# ====================================================================================================================
; Name...........: _EpubMaker_ExtractSelected
; Description ...: Exports a selected HTML or MHTML file using the original file or the current browser page.
; Syntax.........: _EpubMaker_ExtractSelected($sInputPath, $sOutputFolder, $iWebView)
; Parameters ....: $sInputPath    - Selected HTML or MHTML path.
;                  $sOutputFolder - Existing destination folder.
;                  $iWebView      - WebView2 instance used for MHTML page extraction.
; Return values .: On Success - Number of resources written.
;                  On Failure - 0 and sets @error.
; Author ........: Michał Lipok
; Modified.......:
; Remarks .......: HTML files retain their original Base64 source. MHTML files use the page currently displayed in WebView2.
; Related .......: _EpubMaker_ExtractResources, _EpubMaker_ExtractCurrentPage
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _EpubMaker_ExtractSelected($sInputPath, $sOutputFolder, $iWebView)
	If StringRegExp($sInputPath, "(?i)\.mhtml?$") Then
		If $iWebView < 0 Then Return SetError(1, 0, 0)
		_WebView2_Navigate($iWebView, __EpubMaker_FileUri($sInputPath))
		Local $sOutputName = StringRegExpReplace(StringRegExpReplace($sInputPath, ".*[\\/]", ""), "(?i)\.(mhtml?)$", ".html")
		Return _EpubMaker_ExtractCurrentPage($iWebView, $sOutputFolder, $sOutputName)
	EndIf
	Return _EpubMaker_ExtractResources($sInputPath, $sOutputFolder)
EndFunc   ;==>_EpubMaker_ExtractSelected

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __EpubMaker_FileUri
; Description ...: Converts a local Windows path to a file URI.
; Syntax.........: __EpubMaker_FileUri($sPath)
; Parameters ....: $sPath - Absolute local file path.
; Return values .: On Success - File URI.
;                  On Failure - Empty string.
; Author ........: Michał Lipok
; Modified.......:
; Remarks .......: This basic conversion is sufficient for local paths selected through the Windows dialogs.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __EpubMaker_FileUri($sPath)
	If $sPath = "" Then Return ""
	Return "file:///" & StringReplace(StringReplace($sPath, "\", "/"), " ", "%20")
EndFunc   ;==>__EpubMaker_FileUri

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __EpubMaker_FormatBytes
; Description ...: Formats a file size for the list view.
; Syntax.........: __EpubMaker_FormatBytes($iBytes)
; Parameters ....: $iBytes - File size in bytes.
; Return values .: On Success - Human-readable size string.
;                  On Failure - 0 B.
; Author ........: Michał Lipok
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __EpubMaker_FormatBytes($iBytes)
	If $iBytes < 1024 Then Return $iBytes & " B"
	If $iBytes < 1048576 Then Return Round($iBytes / 1024, 1) & " KB"
	Return Round($iBytes / 1048576, 1) & " MB"
EndFunc   ;==>__EpubMaker_FormatBytes

; #FUNCTION# ====================================================================================================================
; Name...........: _EpubMaker_ExtractCurrentPage
; Description ...: Reads the current WebView2 page and extracts its Base64 resources.
; Syntax.........: _EpubMaker_ExtractCurrentPage($iWebView, $sOutputFolder[, $sOutputName = "page.html"])
; Parameters ....: $iWebView      - WebView2 instance identifier.
;                  $sOutputFolder - Existing destination folder.
;                  $sOutputName   - Output HTML file name; default is page.html.
; Return values .: On Success - Number of resources written.
;                  On Failure - 0 and sets @error.
; Author ........: Michał Lipok
; Modified.......:
; Remarks .......: The current page is first written to a temporary HTML file.
; Related .......: _EpubMaker_ExtractResources, _WebView2_GetHtmlSource
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _EpubMaker_ExtractCurrentPage($iWebView, $sOutputFolder, $sOutputName = "page.html")
	If $iWebView < 0 Or Not FileExists($sOutputFolder) Or Not StringInStr(FileGetAttrib($sOutputFolder), "D") Then Return SetError(1, 0, 0)
	Local $sHTML = _WebView2_GetHtmlSource($iWebView)
	If @error Or $sHTML = "" Then Return SetError(2, @extended, 0)

	Local $sTempPath = @TempDir & "\ePUB_Maker_" & @AutoItPID & ".html"
	If Not __EpubMaker_WriteUtf8($sTempPath, $sHTML) Then Return SetError(3, 0, 0)
	Local $iExtracted = _EpubMaker_ExtractResources($sTempPath, $sOutputFolder)
	Local $iError = @error, $iExtended = @extended
	If $iError Then
		FileDelete($sTempPath)
		Return SetError($iError, $iExtended, 0)
	EndIf

	Local $sTempOutput = $sOutputFolder & "\ePUB_Maker_" & @AutoItPID & ".html"
	Local $sTargetOutput = $sOutputFolder & "\" & $sOutputName
	If Not FileMove($sTempOutput, $sTargetOutput, 1) Then
		FileDelete($sTempPath)
		Return SetError(4, 0, 0)
	EndIf
	FileDelete($sTempPath)
	Return $iExtracted
EndFunc   ;==>_EpubMaker_ExtractCurrentPage

; #FUNCTION# ====================================================================================================================
; Name...........: _EpubMaker_ExtractResources
; Description ...: Extracts Base64 data URLs from an HTML file and writes a Sigil-friendly HTML resource folder.
; Syntax.........: _EpubMaker_ExtractResources($sInputPath, $sOutputFolder)
; Parameters ....: $sInputPath    - Existing UTF-8 HTML input file.
;                  $sOutputFolder - Existing folder where the HTML copy and the _files folder are created.
; Return values .: On Success - Number of unique resources written.
;                  On Failure - 0 and sets @error:
;                    1 = Invalid input path or output folder.
;                    2 = Unable to read the HTML file.
;                    3 = Unable to create the resource folder.
;                    4 = Invalid Base64 data URL.
;                    5 = Unable to decode a resource.
;                    6 = Unable to write a resource or the output HTML.
; Author ........: Michał Lipok
; Modified.......:
; Remarks .......: The output HTML is named after the input file and references resources as _files/resource_N.ext.
;                  Existing files with the same names are overwritten in the selected output folder.
; Related .......: __EpubMaker_Base64DecodeBinary
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _EpubMaker_ExtractResources($sInputPath, $sOutputFolder)
	If Not FileExists($sInputPath) Or StringRegExp($sInputPath, "(?i)\.(html?|xhtml)$") = 0 Then Return SetError(1, 0, 0)
	If Not FileExists($sOutputFolder) Or Not StringInStr(FileGetAttrib($sOutputFolder), "D") Then Return SetError(1, 0, 0)

	Local $hInput = FileOpen($sInputPath, $FO_READ + $FO_UTF8)
	If $hInput = -1 Then Return SetError(2, 0, 0)
	Local $sHTML = FileRead($hInput)
	FileClose($hInput)
	If @error Then Return SetError(2, 0, 0)

	Local $sFilesFolder = $sOutputFolder & "\_files"
	If Not DirCreate($sFilesFolder) And Not FileExists($sFilesFolder) Then Return SetError(3, 0, 0)

	Local $aDataUrls = StringRegExp($sHTML, "(?i)data:[^;,\s]+;base64,[A-Za-z0-9+/=_-]+", 3)
	If @error Or Not IsArray($aDataUrls) Then
		Local $sOutputPathNoResources = $sOutputFolder & "\" & StringRegExpReplace(StringRegExpReplace($sInputPath, ".*[\\/]", ""), "(?i)\.(html?|xhtml)$", ".html")
		If Not __EpubMaker_WriteUtf8($sOutputPathNoResources, $sHTML) Then Return SetError(6, 0, 0)
		Return 0
	EndIf

	Local $iResourceCount = 0
	Local $sDataURL, $aParts, $sMime, $sBase64, $sRelativePath, $sResourcePath, $bData, $sFileName
	For $sDataURL In $aDataUrls
		$aParts = StringRegExp($sDataURL, "(?i)^data:([^;,\s]+);base64,(.+)$", 1)
		If @error Or UBound($aParts) <> 2 Then Return SetError(4, 0, 0)

		$sMime = $aParts[0]
		$sBase64 = StringRegExpReplace($aParts[1], "\s", "")
		$bData = __EpubMaker_Base64DecodeBinary($sBase64)
		If @error Then Return SetError(5, @extended, 0)

		$iResourceCount += 1
		$sFileName = "resource_" & StringFormat("%03d", $iResourceCount) & "." & __EpubMaker_ExtensionFromMime($sMime)
		$sResourcePath = $sFilesFolder & "\" & $sFileName
		If Not __EpubMaker_WriteBinary($sResourcePath, $bData) Then Return SetError(6, 0, 0)
		$sRelativePath = "_files/" & $sFileName
		$sHTML = StringReplace($sHTML, $sDataURL, $sRelativePath)
	Next

	Local $sOutputName = StringRegExpReplace(StringRegExpReplace($sInputPath, ".*[\\/]", ""), "(?i)\.(html?|xhtml)$", ".html")
	Local $sOutputPath = $sOutputFolder & "\" & $sOutputName
	If Not __EpubMaker_WriteUtf8($sOutputPath, $sHTML) Then Return SetError(6, 0, 0)
	Return $iResourceCount
EndFunc   ;==>_EpubMaker_ExtractResources

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __EpubMaker_Base64DecodeBinary
; Description ...: Decodes Base64 text into an AutoIt Binary value through Crypt32.dll.
; Syntax.........: __EpubMaker_Base64DecodeBinary($sBase64)
; Parameters ....: $sBase64 - Base64-encoded payload.
; Return values .: On Success - Binary resource data.
;                  On Failure - Empty binary and sets @error to 1.
; Author ........: Michał Lipok
; Modified.......:
; Remarks .......: CryptStringToBinaryW accepts the standard Base64 alphabet used by data URLs.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __EpubMaker_Base64DecodeBinary($sBase64)
	Local $aSize = DllCall("Crypt32.dll", "bool", "CryptStringToBinaryW", "wstr", $sBase64, "dword", 0, "dword", 1, "ptr", 0, "dword*", 0, "ptr", 0, "ptr", 0)
	If @error Or Not IsArray($aSize) Or Not $aSize[0] Or $aSize[5] <= 0 Then Return SetError(1, 0, Binary(""))
	Local $tBuffer = DllStructCreate("byte[" & $aSize[5] & "]")
	Local $iSize = $aSize[5]
	Local $aData = DllCall("Crypt32.dll", "bool", "CryptStringToBinaryW", "wstr", $sBase64, "dword", 0, "dword", 1, "struct*", $tBuffer, "dword*", $iSize, "ptr", 0, "ptr", 0)
	If @error Or Not IsArray($aData) Or Not $aData[0] Then Return SetError(1, 0, Binary(""))
	Return BinaryMid(DllStructGetData($tBuffer, 1), 1, $iSize)
EndFunc   ;==>__EpubMaker_Base64DecodeBinary

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __EpubMaker_WriteBinary
; Description ...: Writes binary data to a file.
; Syntax.........: __EpubMaker_WriteBinary($sPath, $bData)
; Parameters ....: $sPath - Destination path.
;                  $bData - Binary data.
; Return values .: On Success - True.
;                  On Failure - False.
; Author ........: Michał Lipok
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __EpubMaker_WriteBinary($sPath, $bData)
	Local $hFile = FileOpen($sPath, $FO_OVERWRITE + $FO_BINARY)
	If $hFile = -1 Then Return False
	Local $iWritten = FileWrite($hFile, $bData)
	FileClose($hFile)
	Return $iWritten > 0
EndFunc   ;==>__EpubMaker_WriteBinary

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __EpubMaker_WriteUtf8
; Description ...: Writes UTF-8 text without a BOM.
; Syntax.........: __EpubMaker_WriteUtf8($sPath, $sText)
; Parameters ....: $sPath - Destination path.
;                  $sText - Text to write.
; Return values .: On Success - True.
;                  On Failure - False.
; Author ........: Michał Lipok
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __EpubMaker_WriteUtf8($sPath, $sText)
	Local $hFile = FileOpen($sPath, $FO_OVERWRITE + $FO_UTF8_NOBOM)
	If $hFile = -1 Then Return False
	Local $iWritten = FileWrite($hFile, $sText)
	FileClose($hFile)
	Return $iWritten > 0
EndFunc   ;==>__EpubMaker_WriteUtf8

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __EpubMaker_ExtensionFromMime
; Description ...: Maps a data URL MIME type to a safe resource extension.
; Syntax.........: __EpubMaker_ExtensionFromMime($sMime)
; Parameters ....: $sMime - MIME type from the data URL.
; Return values .: On Success - Resource extension without a dot.
;                  On Failure - bin.
; Author ........: Michał Lipok
; Modified.......:
; Remarks .......: Unknown MIME types are kept as .bin so the original bytes are not discarded.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __EpubMaker_ExtensionFromMime($sMime)
	Switch StringLower($sMime)
		Case "image/jpeg", "image/jpg"
			Return "jpg"
		Case "image/png"
			Return "png"
		Case "image/gif"
			Return "gif"
		Case "image/svg+xml"
			Return "svg"
		Case "image/webp"
			Return "webp"
		Case "image/x-icon", "image/vnd.microsoft.icon"
			Return "ico"
		Case "font/woff"
			Return "woff"
		Case "font/woff2"
			Return "woff2"
		Case "font/ttf", "application/x-font-ttf"
			Return "ttf"
		Case "font/otf", "application/vnd.ms-opentype"
			Return "otf"
		Case "text/css"
			Return "css"
		Case "application/javascript", "text/javascript"
			Return "js"
	EndSwitch
	Return "bin"
EndFunc   ;==>__EpubMaker_ExtensionFromMime
