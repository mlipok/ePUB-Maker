#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <FileConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <ListViewConstants.au3>
#include <MsgBoxConstants.au3>
#include <APIGdiConstants.au3>
#include <WinAPIGdi.au3>
#include <WindowsConstants.au3>
#include <WindowsNotifsConstants.au3>
#include <AutoItConstants.au3>
#include <EditConstants.au3>

#include "UDF\WebView2.au3"

Opt("MustDeclareVars", 1)

Global Const $g_sApplicationName = "ePUB Maker"
Global Const $g_sVersion = "0.2.0"
Global Const $g_iMainBackgroundColor = 0xC0C0C0
Global Const $g_iButtonBackgroundColor = 0xD6D6D6
Global Const $g_iEditBackgroundColor = 0xF7F7F7
Global $g_iWebView = -1
Global $g_bLayoutPending = True
Global $g_asListedFiles[1] = [0]

Main()

Func Main()
	Local $hGUI = GUICreate($g_sApplicationName & " " & $g_sVersion, 1300, 800, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local Const $iBrowserLeft = 452, $iBrowserTop = 102, $iMargin = 12
	Local $iPreviousResizeMode = Opt("GUIResizeMode", $GUI_DOCKALL)
	Local $idCalibre = GUICtrlCreateButton("Calibre location...", 220, 3, 130, 24)
	Local $idTabs = GUICtrlCreateTab(4, 4, 1292, 792)
	GUICtrlSetResizing($idTabs, $GUI_DOCKBORDERS)
	GUICtrlCreateTabItem("Single file")
	GUICtrlCreateLabel("Local HTML input", 12, 42, 320, 22)
	GUICtrlCreateLabel("Input HTML / MHTML file:", 12, 72, 190, 22)
	Local $idInput = GUICtrlCreateInput("", 12, 96, 245, 24)
	Local $idInputBrowse = GUICtrlCreateButton("Browse...", 264, 96, 75, 24)
	GUICtrlCreateLabel("Output folder:", 12, 132, 105, 22)
	Local $idOutput = GUICtrlCreateInput("", 12, 156, 245, 24)
	Local $idOutputBrowse = GUICtrlCreateButton("Browse...", 264, 156, 75, 24)
	Local $idProcess = GUICtrlCreateButton("Extract local file", 12, 196, 130, 30)
	Local $idExtractPage = GUICtrlCreateButton("Extract current page", 148, 196, 150, 30)
	Local $idConvertSingle = GUICtrlCreateButton("Convert to EPUB", 304, 196, 136, 30)
	Local $idLoadFolder = GUICtrlCreateButton("Load HTML / MHTML folder", 12, 244, 220, 28)
	Local $idExportSelected = GUICtrlCreateButton("Export selected item", 240, 244, 200, 28)
	Local $idFileList = GUICtrlCreateListView("File|Type|Size", 12, 280, 428, 434, BitOR($LVS_REPORT, $LVS_SINGLESEL, $LVS_SHOWSELALWAYS))
	GUICtrlSendMsg($idFileList, $LVM_SETCOLUMNWIDTH, 0, 270)
	GUICtrlSendMsg($idFileList, $LVM_SETCOLUMNWIDTH, 1, 65)
	GUICtrlSendMsg($idFileList, $LVM_SETCOLUMNWIDTH, 2, 80)
	Local $idStatus = GUICtrlCreateLabel("Choose a local file, load a folder, or navigate to a URL.", 12, 724, 428, 30)
	Local $idClose = GUICtrlCreateButton("Close", 12, 762, 100, 26)
	GUICtrlCreateLabel("Browser preview", $iBrowserLeft, 42, 320, 22)
	Local $idBack = GUICtrlCreateButton("Back", $iBrowserLeft, 68, 55, 26)
	Local $idForward = GUICtrlCreateButton("Forward", $iBrowserLeft + 60, 68, 65, 26)
	Local $idReload = GUICtrlCreateButton("Reload", $iBrowserLeft + 130, 68, 60, 26)
	Local $idStop = GUICtrlCreateButton("Stop", $iBrowserLeft + 195, 68, 55, 26)
	Local Const $iUrlLeft = $iBrowserLeft + 255
	Local $idURL = GUICtrlCreateInput("https://example.com/", $iUrlLeft, 68, 80, 26)
	Local $idGo = GUICtrlCreateButton("Go", $iUrlLeft + 88, 68, 64, 26)

	GUICtrlCreateTabItem("Batch processing")
	GUICtrlCreateLabel("Source folder (includes subfolders)", 16, 42, 360, 20)
	Local $idBatchSource = GUICtrlCreateInput("", 16, 64, 620, 24)
	Local $idBatchBrowseSource = GUICtrlCreateButton("Browse...", 644, 64, 80, 24)
	GUICtrlCreateLabel("Output folder (mirrors the source folder structure)", 16, 100, 500, 20)
	Local $idBatchOutput = GUICtrlCreateInput("", 16, 122, 620, 24)
	Local $idBatchBrowseOutput = GUICtrlCreateButton("Browse...", 644, 122, 80, 24)
	Local $idKeepExtension = GUICtrlCreateCheckbox("Always include the source extension in the EPUB name", 16, 158, 475, 24)
	GUICtrlCreateLabel("When cleared, the source extension is added only if names conflict.", 16, 186, 650, 22)
	Local $idConvertBatch = GUICtrlCreateButton("Convert folder to EPUB", 16, 218, 190, 30)
	Local $idProgress = GUICtrlCreateProgress(16, 264, 1268, 24)
	Local $idBatchStatus = GUICtrlCreateLabel("Choose source and output folders.", 16, 296, 1268, 30)
	Local $idBatchDetails = GUICtrlCreateEdit("", 16, 332, 1268, 452, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetResizing($idProgress, BitOR($GUI_DOCKLEFT, $GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKHEIGHT))
	GUICtrlSetResizing($idBatchStatus, BitOR($GUI_DOCKLEFT, $GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKHEIGHT))
	GUICtrlSetResizing($idBatchDetails, $GUI_DOCKBORDERS)
	GUICtrlCreateTabItem("")

	Local $iMessage
	Local $sCalibre = __EpubMaker_FindCalibre()
	Local $iWorker = 0, $idWorkerStatus = $idStatus, $iLastPercent = -1
	Local $sWorkerBuffer = "", $sWorkerDetails = "", $sWorkerResult = ""
	Opt("GUIResizeMode", $iPreviousResizeMode)

	; Keep the native controls aligned with the WebView2 bounds as the client area changes.
	GUICtrlSetResizing($idFileList, BitOR($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKBOTTOM, $GUI_DOCKWIDTH))
	GUICtrlSetResizing($idStatus, BitOR($GUI_DOCKLEFT, $GUI_DOCKBOTTOM, $GUI_DOCKSIZE))
	GUICtrlSetResizing($idClose, BitOR($GUI_DOCKLEFT, $GUI_DOCKBOTTOM, $GUI_DOCKSIZE))

	GUISetBkColor($g_iMainBackgroundColor, $hGUI)
	Local Const $iRedrawFlags = BitOR($RDW_INVALIDATE, $RDW_ERASE, $RDW_FRAME, $RDW_ALLCHILDREN)
	GUICtrlSetBkColor($idInput, $g_iEditBackgroundColor)
	GUICtrlSetBkColor($idOutput, $g_iEditBackgroundColor)
	GUICtrlSetBkColor($idFileList, 0xFFFFFF)
	GUICtrlSetBkColor($idInputBrowse, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idOutputBrowse, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idProcess, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idExtractPage, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idLoadFolder, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idExportSelected, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idBack, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idForward, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idReload, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idStop, $g_iButtonBackgroundColor)
	GUICtrlSetBkColor($idGo, $g_iButtonBackgroundColor)

	Local Const $iGetMinMaxInfo = 0x0024
	GUIRegisterMsg($iGetMinMaxInfo, "__EpubMaker_GetMinMaxInfo")
	GUIRegisterMsg($WM_SIZE, "__EpubMaker_OnSize")
	GUISetState(@SW_SHOW, $hGUI)
	Local $aClientSize = WinGetClientSize($hGUI)
	If IsArray($aClientSize) Then __EpubMaker_LayoutAddressBar($aClientSize[0], $iUrlLeft, $idURL, $idGo)
	Local $sProfile = @LocalAppDataDir & "\ePUB Maker\WebView2"
	If _WebView2_Init(Default, $sProfile) Then
		Local $aInitialClient = WinGetClientSize($hGUI)
		$g_iWebView = _WebView2_Create($hGUI, $iBrowserLeft, $iBrowserTop, $aInitialClient[0] - $iBrowserLeft - $iMargin, $aInitialClient[1] - $iBrowserTop - $iMargin)
		If @error Or $g_iWebView < 0 Then
			$g_iWebView = -1
			GUICtrlSetData($idStatus, "WebView2 could not be created. Local extraction remains available.")
		Else
			_WebView2_Navigate($g_iWebView, GUICtrlRead($idURL))
		EndIf
	Else
		GUICtrlSetData($idStatus, "WebView2 is unavailable. Local extraction remains available.")
	EndIf
	$g_bLayoutPending = True

	While True
		$iMessage = GUIGetMsg()
		If $iWorker Then
			Local $sChunk = StdoutRead($iWorker)
			Local $bWorkerEnded = @error <> 0
			$sWorkerBuffer &= $sChunk
			Local $iNewline = StringInStr($sWorkerBuffer, @LF, 1)
			While $iNewline
				Local $sLine = StringStripCR(StringLeft($sWorkerBuffer, $iNewline - 1))
				$sWorkerBuffer = StringTrimLeft($sWorkerBuffer, $iNewline)
				Local $aProgress = StringRegExp($sLine, "^EPUBMAKER\|(status|detail|result)\|(\d{1,3})\|([0-9a-f]*)$", 1)
				If IsArray($aProgress) Then
					Local $sProgress = BinaryToString(Binary("0x" & $aProgress[2]), 4)
					If $aProgress[0] = "detail" Then
						$sWorkerDetails &= $sProgress & @CRLF
					Else
						GUICtrlSetData($idWorkerStatus, $sProgress)
						$iLastPercent = Number($aProgress[1])
						If $aProgress[0] = "result" Then $sWorkerResult = $sProgress
					EndIf
				EndIf
				$iNewline = StringInStr($sWorkerBuffer, @LF, 1)
			WEnd
			If $idWorkerStatus = $idBatchStatus And $iLastPercent >= 0 Then
				GUICtrlSetData($idProgress, $iLastPercent)
				$iLastPercent = -1
			EndIf
			If $bWorkerEnded Then
				$iWorker = 0
				If $sWorkerResult = "" Then $sWorkerResult = "The conversion process ended without reporting a result."
				GUICtrlSetData($idWorkerStatus, $sWorkerResult)
				If $idWorkerStatus = $idBatchStatus Then
					GUICtrlSetData($idBatchDetails, $sWorkerDetails)
				ElseIf $sWorkerDetails <> "" Then
					MsgBox($MB_ICONINFORMATION, $g_sApplicationName, $sWorkerResult & @CRLF & $sWorkerDetails, 0, $hGUI)
				EndIf
				GUICtrlSetState($idConvertSingle, $GUI_ENABLE)
				GUICtrlSetState($idConvertBatch, $GUI_ENABLE)
			EndIf
		EndIf
		If $g_bLayoutPending Then
			$g_bLayoutPending = False
			$aClientSize = WinGetClientSize($hGUI)
			If IsArray($aClientSize) And Not BitAND(WinGetState($hGUI), 16) Then
				Local $iBrowserWidth = $aClientSize[0] - $iBrowserLeft - $iMargin
				Local $iBrowserHeight = $aClientSize[1] - $iBrowserTop - $iMargin
				If $iBrowserWidth > 0 And $iBrowserHeight > 0 Then
					__EpubMaker_LayoutAddressBar($aClientSize[0], $iUrlLeft, $idURL, $idGo)
					If $g_iWebView >= 0 Then _WebView2_SetBounds($g_iWebView, $iBrowserLeft, $iBrowserTop, $iBrowserWidth, $iBrowserHeight)
					_WinAPI_RedrawWindow($hGUI, 0, 0, $iRedrawFlags)
				EndIf
			EndIf
		EndIf
		Switch $iMessage
			Case $GUI_EVENT_CLOSE, $idClose
				If $iWorker Then
					MsgBox($MB_ICONINFORMATION, $g_sApplicationName, "Wait for the conversion to finish before closing.", 0, $hGUI)
					ContinueLoop
				EndIf
				ExitLoop
			Case $idTabs
				If $g_iWebView >= 0 Then _WebView2_SetVisible($g_iWebView, GUICtrlRead($idTabs) = 0)
				$g_bLayoutPending = True
			Case $idCalibre
				Local $sSelectedCalibre = FileOpenDialog("Select calibre-debug.exe", @ProgramFilesDir, "Calibre conversion tool (calibre-debug.exe)", $FD_FILEMUSTEXIST)
				If Not @error Then $sCalibre = $sSelectedCalibre
			Case $idBatchBrowseSource, $idBatchBrowseOutput
				Local $sBatchFolder = FileSelectFolder("Select a folder", "", 1, "", $hGUI)
				If @error Then ContinueLoop
				Local $idBatchField = ($iMessage = $idBatchBrowseSource) ? $idBatchSource : $idBatchOutput
				GUICtrlSetData($idBatchField, $sBatchFolder)
			Case $idConvertSingle, $idConvertBatch
				If $iWorker Then ContinueLoop
				Local $sMode = "single", $sNaming = "conflict"
				Local $sConversionSource = GUICtrlRead($idInput), $sConversionOutput = GUICtrlRead($idOutput)
				$idWorkerStatus = $idStatus
				If $iMessage = $idConvertBatch Then
					$sMode = "batch"
					$sConversionSource = GUICtrlRead($idBatchSource)
					$sConversionOutput = GUICtrlRead($idBatchOutput)
					If GUICtrlRead($idKeepExtension) = $GUI_CHECKED Then $sNaming = "always"
					$idWorkerStatus = $idBatchStatus
					GUICtrlSetData($idProgress, 0)
					GUICtrlSetData($idBatchDetails, "")
				EndIf
				Local $sStartError = ""
				$iWorker = __EpubMaker_StartConversion($sCalibre, $sMode, $sConversionSource, $sConversionOutput, $sNaming, $sStartError)
				If Not $iWorker Then
					GUICtrlSetData($idWorkerStatus, $sStartError)
					MsgBox($MB_ICONWARNING, $g_sApplicationName, $sStartError, 0, $hGUI)
					ContinueLoop
				EndIf
				$sWorkerBuffer = ""
				$sWorkerDetails = ""
				$sWorkerResult = ""
				$iLastPercent = -1
				GUICtrlSetData($idWorkerStatus, "Starting conversion...")
				GUICtrlSetState($idConvertSingle, $GUI_DISABLE)
				GUICtrlSetState($idConvertBatch, $GUI_DISABLE)
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
		EndSwitch
	WEnd

	If $g_iWebView >= 0 Then $g_iWebView = -1
	_WebView2_Cleanup()
	GUIDelete($hGUI)
EndFunc   ;==>Main

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __EpubMaker_FindCalibre
; Description ...: Finds the calibre command-line runtime.
; Syntax.........: __EpubMaker_FindCalibre()
; Parameters ....: None.
; Return values .: Full executable path, or an empty string when not found.
; Author ........:
; Modified.......:
; Remarks .......: EPUB_MAKER_CALIBRE may point to a portable calibre-debug.exe.
; Related .......:
; Link ..........:
; Example .......:
; ===============================================================================================================================
Func __EpubMaker_FindCalibre()
	Local $sConfigured = EnvGet("EPUB_MAKER_CALIBRE")
	If $sConfigured <> "" And FileExists($sConfigured) Then Return _PathFull($sConfigured)
	Local $asProgramFiles[2] = [EnvGet("ProgramW6432"), @ProgramFilesDir]
	For $sFolder In $asProgramFiles
		If $sFolder = "" Then ContinueLoop
		Local $sExe = $sFolder & "\Calibre2\calibre-debug.exe"
		If FileExists($sExe) Then Return $sExe
	Next
	Return ""
EndFunc   ;==>__EpubMaker_FindCalibre

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __EpubMaker_StartConversion
; Description ...: Starts the calibre worker for a file or a folder tree.
; Syntax.........: __EpubMaker_StartConversion($sCalibre, $sMode, $sSource, $sOutput, $sNaming, ByRef $sMessage)
; Parameters ....: $sCalibre - Full path to calibre-debug.exe.
;                  $sMode    - "single" or "batch".
;                  $sSource  - Source file or folder.
;                  $sOutput  - Destination folder.
;                  $sNaming  - "always" or "conflict".
;                  $sMessage - Receives an explanation if the worker cannot start.
; Return values .: Worker PID on success, or 0 on failure.
; Author ........:
; Modified.......:
; Remarks .......: The worker reports progress and details through its captured stdout pipe.
; Related .......:
; Link ..........:
; Example .......:
; ===============================================================================================================================
Func __EpubMaker_StartConversion($sCalibre, $sMode, $sSource, $sOutput, $sNaming, ByRef $sMessage)
	If Not StringRegExp($sCalibre, "(?i)[\\/]calibre-debug\.exe$") Or Not FileExists($sCalibre) Then
		$sMessage = "Install calibre or use Calibre location... to select calibre-debug.exe."
		Return 0
	EndIf
	Local $sHelper = @ScriptDir & "\epub_convert.py"
	If Not FileExists($sHelper) Then
		$sMessage = "epub_convert.py must be in the same folder as ePUB Maker."
		Return 0
	EndIf
	If $sSource = "" Or $sOutput = "" Or StringInStr($sSource & $sOutput, '"') Or Not FileExists($sSource) Or Not StringInStr(FileGetAttrib($sOutput), "D") Then
		$sMessage = "Select an existing source and an existing output folder."
		Return 0
	EndIf
	$sSource = _PathFull($sSource)
	$sOutput = _PathFull($sOutput)
	; A trailing backslash before a closing quote must be escaped on Windows.
	If StringRight($sSource, 1) = "\" Then $sSource &= "\"
	If StringRight($sOutput, 1) = "\" Then $sOutput &= "\"
	Local $sCommand = '"' & $sCalibre & '" -e "' & $sHelper & '" -- ' & $sMode & ' "' & $sSource & '" "' & $sOutput & '" --naming ' & $sNaming
	Local $iPID = Run($sCommand, @ScriptDir, @SW_HIDE, BitOR($STDOUT_CHILD, $STDERR_MERGED))
	If Not $iPID Then $sMessage = "Unable to start calibre conversion."
	Return $iPID
EndFunc   ;==>__EpubMaker_StartConversion

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __EpubMaker_OnSize
; Description ...: Schedules a layout update when Windows resizes the client area.
; Syntax.........: __EpubMaker_OnSize()
; Parameters ....: None.
; Return values .: $GUI_RUNDEFMSG to preserve native control docking.
; Author ........:
; Modified.......:
; Remarks .......: The GUI loop updates WebView2 outside the window message callback.
; Related .......:
; Link ..........:
; Example .......:
; ===============================================================================================================================
Func __EpubMaker_OnSize()
	$g_bLayoutPending = True
	Return $GUI_RUNDEFMSG
EndFunc   ;==>__EpubMaker_OnSize

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __EpubMaker_LayoutAddressBar
; Description ...: Fits the URL field and Go button to the current client width.
; Syntax.........: __EpubMaker_LayoutAddressBar($iClientWidth, $iUrlLeft, $idURL, $idGo)
; Parameters ....: $iClientWidth - Current width of the main window's client area.
;                  $iUrlLeft     - Left edge of the URL field.
;                  $idURL       - URL field control ID.
;                  $idGo        - Go button control ID.
; Return values .: None.
; Author ........:
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......:
; ===============================================================================================================================
Func __EpubMaker_LayoutAddressBar($iClientWidth, $iUrlLeft, $idURL, $idGo)
	Local Const $iTop = 68, $iHeight = 26, $iGoWidth = 64, $iRightMargin = 24, $iGap = 8
	Local $iGoLeft = $iClientWidth - $iRightMargin - $iGoWidth
	Local $iUrlWidth = $iGoLeft - $iGap - $iUrlLeft
	If $iUrlWidth <= 0 Then Return
	GUICtrlSetPos($idURL, $iUrlLeft, $iTop, $iUrlWidth, $iHeight)
	GUICtrlSetPos($idGo, $iGoLeft, $iTop, $iGoWidth, $iHeight)
EndFunc   ;==>__EpubMaker_LayoutAddressBar

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __EpubMaker_GetMinMaxInfo
; Description ...: Keeps both panes usable when the main window is resized.
; Syntax.........: __EpubMaker_GetMinMaxInfo($hWnd, $iMsg, $wParam, $lParam)
; Parameters ....: $hWnd, $iMsg, $wParam - Unused window message parameters.
;                  $lParam - Pointer to the system MINMAXINFO structure.
; Return values .: 0 after updating the minimum tracking size.
; Author ........:
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......:
; ===============================================================================================================================
Func __EpubMaker_GetMinMaxInfo($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam
	Local $tLimits = DllStructCreate("long Reserved[2];long MaxSize[2];long MaxPosition[2];long MinTrackWidth;long MinTrackHeight;long MaxTrackSize[2]", $lParam)
	DllStructSetData($tLimits, "MinTrackWidth", 900)
	DllStructSetData($tLimits, "MinTrackHeight", 440)
	Return 0
EndFunc   ;==>__EpubMaker_GetMinMaxInfo

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
