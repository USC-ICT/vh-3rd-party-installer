; apache-activemq.nsi
;--------------------------------

SetCompressor /SOLID lzma

;--------------------------------
;Includes

!include "MUI.nsh"       ; modern UI


;--------------------------------
;General

!define ACTIVEMQ_VERSION  5.16.8
!define INSTALLER_VERSION     0

!define ACTIVEMQ_SOURCE_DIR "..\apache-activemq"
!define JAVA_SOURCE_DIR "..\java"


; The name of the installer and the file to write
Name "ActiveMQ Server"
OutFile "..\apache-activemq-${ACTIVEMQ_VERSION}.${INSTALLER_VERSION}.exe"

; The default installation directory
InstallDir $PROGRAMFILES\ActiveMQ\apache-activemq-${ACTIVEMQ_VERSION}.${INSTALLER_VERSION}\

; Registry key to check for directory (so if you install again, it will overwrite the old one automatically)
;InstallDirRegKey HKLM "Software\ActiveMQ" "Install_Dir"

RequestExecutionLevel admin

ShowInstDetails show

; Version Info
VIProductVersion "${ACTIVEMQ_VERSION}.${INSTALLER_VERSION}"
VIAddVersionKey "ProductName" "ActiveMQ Server Installer"
VIAddVersionKey "Comments" ""
VIAddVersionKey "CompanyName" "ActiveMQ"
VIAddVersionKey "LegalTrademarks" ""
VIAddVersionKey "LegalCopyright" ""
VIAddVersionKey "FileDescription" "ActiveMQ Server Installer"
VIAddVersionKey "FileVersion" "${ACTIVEMQ_VERSION}.${INSTALLER_VERSION}"
VIAddVersionKey "ProductVersion" "${ACTIVEMQ_VERSION}.${INSTALLER_VERSION}"

Caption "ActiveMQ Server Installer"           ; Title Bar Text
BrandingText "ActiveMQ Server Installer ${ACTIVEMQ_VERSION}"  ; Greyed text in lower left
CompletedText "-- ActiveMQ Server Install Complete -----------------------------------"  ; Complete message


!define MUI_ABORTWARNING


;--------------------------------
; Pages

!define MUI_COMPONENTSPAGE_NODESC

!define MUI_WELCOMEPAGE_TITLE "ActiveMQ Server Installer"
!define MUI_WELCOMEPAGE_TEXT "This program will install the ActiveMQ server and start it up as a Win32 service."
!insertmacro MUI_PAGE_WELCOME

!define MUI_DIRECTORYPAGE_VERIFYONLEAVE
!insertmacro MUI_PAGE_DIRECTORY

!insertmacro MUI_PAGE_COMPONENTS

!insertmacro MUI_PAGE_INSTFILES

UninstPage uninstConfirm
UninstPage instfiles


;--------------------------------
;Languages
 
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_RESERVEFILE_LANGDLL ;Language selection dialog


;--------------------------------
; Descriptions

;Language strings
;LangString DESC_SecDummy ${LANG_ENGLISH} "A test section."

;Assign language strings to sections
;!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
;  !insertmacro MUI_DESCRIPTION_TEXT ${SecDummy} $(DESC_SecDummy)
;!insertmacro MUI_FUNCTION_DESCRIPTION_END

LangString TEXT_IO_TITLE ${LANG_ENGLISH} "ActiveMQ Server Install"
LangString TEXT_IO_SUBTITLE ${LANG_ENGLISH} " "



;--------------------------------
; Sections

Section "-Stop Service"
  ; This section is hidden

  ; Stop the server if running so that it can overwrite files if re-installing
  ExecWait '$windir\System32\sc.exe stop ActiveMQ' $0

  ;MessageBox MB_OK 'sc stop result - $0'

  IntOp $5 0 + 0

  loop:

  ExpandEnvStrings $0 %COMSPEC%
  ExecWait '"$0" /C $windir\System32\sc.exe query ActiveMQ | find "STATE" | find "STOPPED"' $1
  ; $1 is 0 if found
  ; $1 is 1 if not found
  ${If} $1 = 0
    goto done
  ${EndIF}

  ; add a timeout to prevent endless loop
  IntOp $5 $5 + 1
  ${If} $5 > 5   ; 5 * 2 seconds == 10 second timeout
    DetailPrint "ERROR: Could not verify that service has been shut down."
    goto done
  ${EndIF}

  Sleep 2000

  goto loop
  done:

SectionEnd


Section "ActiveMQ"
  SetOutPath $INSTDIR
  File /r /x .svn ${ACTIVEMQ_SOURCE_DIR}\*.*

  SetOutPath $INSTDIR\bin\win32\java
  File /r /x .svn ${JAVA_SOURCE_DIR}\*.*
  SetOutPath $INSTDIR

  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\ActiveMQ "Install_Dir" "$INSTDIR"



	;Some of the following values will not be used by older Windows versions.
	;
	;InstallLocation (string) - Installation directory ($INSTDIR) 
	;DisplayIcon (string) - Path, filename and index of the icon that will be displayed next to your application name
	;
	;Publisher (string) - (Company) name of the publisher
	;
	;ModifyPath (string) - Path and filename of the application modify program 
	;InstallSource (string) - Location where the application was installed from
	;
	;ProductID (string) - Product ID of the application 
	;RegOwner (string) - Registered owner of the application 
	;RegCompany (string) - Registered company of the application
	;
	;HelpLink (string) - Link to the support website 
	;HelpTelephone (string) - Telephone number for support
	;
	;URLUpdateInfo (string) - Link to the website for application updates 
	;URLInfoAbout (string) - Link to the application home page
	;
	;DisplayVersion (string) - Displayed version of the application 
	;VersionMajor (DWORD) - Major version number of the application 
	;VersionMinor (DWORD) - Minor version number of the application
	;
	;NoModify (DWORD) - 1 if uninstaller has no option to modify the installed application 
	;NoRepair (DWORD) - 1 if the uninstaller has no option to repair the installation
	;
	;If both NoModify and NoRepair are set to 1, the button displays "Remove" instead of "Modify/Remove".


  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ActiveMQ" "DisplayName" "ActiveMQ"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ActiveMQ" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ActiveMQ" "DisplayVersion" "${ACTIVEMQ_VERSION}.${INSTALLER_VERSION}"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ActiveMQ" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ActiveMQ" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd


Section "Install Win32 Service"
  ; $OUTDIR is used as working dir for ExecWait, we need to modify it temporarily
  Push $OUTDIR
  SetOutPath "$INSTDIR\bin\win32"
  ExecWait '"$INSTDIR\bin\win32\UninstallService.bat"' $0  ; Also stops service if currently running
  ExecWait '"$INSTDIR\bin\win32\InstallService.bat"' $0    ; Adds service to list, sets type to Automatice, does *not* start service
  ;ExecWait 'sc config ActiveMQ start= auto' $0

  ExecWait '$windir\System32\sc.exe start ActiveMQ' $0

  ;MessageBox MB_OK 'sc start result - $0'

  IntOp $5 0 + 0

  loop:

  ExpandEnvStrings $0 %COMSPEC%
  ExecWait '"$0" /C $windir\System32\sc.exe query ActiveMQ | find "STATE" | find "RUNNING"' $1
  ; $1 is 0 if found
  ; $1 is 1 if not found
  ${If} $1 = 0
    goto done
  ${EndIF}

  ; add a timeout to prevent endless loop
  IntOp $5 $5 + 1
  ${If} $5 > 5   ; 5 * 2 seconds == 10 second timeout
    DetailPrint "ERROR: Could not verify that service has been started."
    goto done
  ${EndIF}

  Sleep 2000

  goto loop
  done:


  ;ReadEnvStr $0 COMSPEC
  ;nsExec::ExecToLog 'net start ActiveMQ'
  ;MessageBox MB_OK 'net start ActiveMQ'

  Pop $1
  SetOutPath $1
SectionEnd


;--------------------------------
; Uninstaller

Section "Uninstall"
  ; $OUTDIR is used as working dir for ExecWait, we need to modify it temporarily
  Push $OUTDIR
  SetOutPath "$INSTDIR\bin\win32"
  ExecWait '"$INSTDIR\bin\win32\UninstallService.bat"' $0  ; Also stops service if currently running
  Pop $1
  SetOutPath $1

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ActiveMQ"
  DeleteRegKey HKLM SOFTWARE\ActiveMQ

  RMDir /r /REBOOTOK $INSTDIR
SectionEnd
