; vh-3rd-party-installer.nsi

SetCompressor /SOLID zlib

;--------------------------------
; Includes

!include "nsDialogs.nsh" ; modern UI 2 beta (use MUI2.nsh when all dialogs are merged over)
!include "MUI.nsh"       ; modern UI
!include "Sections.nsh"  ; helper functions for managing sections
!include "LogicLib.nsh"  ; helper functions for logic control statements (if, switch, etc)
!include "FileFunc.nsh"
!include "WinVer.nsh"
!include "x64.nsh"
!include "vh.nsh"


!ifdef THIRD_PARTY_VERSION
!define THIRDPARTY_INSTALLER_VERSION  ${THIRD_PARTY_VERSION}
!else
!define THIRDPARTY_INSTALLER_VERSION  0.1.0
!endif


;--------------------------------
; General

RequestExecutionLevel admin

; The name of the installer and the file to write
Name "Virtual Human - 3rd Party Component(s)"
OutFile "..\vh-3rd-party-installer-${THIRDPARTY_INSTALLER_VERSION}.exe"

;Default installation folder
InstallDir "$Temp"

; Version Info
VIProductVersion "${THIRDPARTY_INSTALLER_VERSION}.0"
VIAddVersionKey "ProductName" "Virtual Human - 3rd Party Installer"
VIAddVersionKey "FileDescription" "Virtual Human - 3rd party installer"
VIAddVersionKey "FileVersion" "${THIRDPARTY_INSTALLER_VERSION}.0"

Caption "Virtual Human - 3rd Party Installer ${THIRDPARTY_INSTALLER_VERSION}"           ; Title Bar Text
BrandingText "3rd Party Installer ${THIRDPARTY_INSTALLER_VERSION}"  ; Greyed text in lower left
CompletedText "-- 3rd Party installation complete -----------------------------------"  ; Complete message


;--------------------------------
; Pages

!define MUI_COMPONENTSPAGE_NODESC

Page custom PageWelcome PageWelcomeLeave


!define MUI_PAGE_CUSTOMFUNCTION_PRE Pre3rdPartyComponents
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE Leave3rdPartyComponents
!define MUI_PAGE_HEADER_TEXT "Choose 3rd Party Components"
!define MUI_PAGE_HEADER_SUBTEXT "Choose the 3rd Party Components you want to install. Select all if this is the first time installing these components, or if it has been a long time since installing any of these. Installing these components will usually not break anything, but will take more time.Only programmers need to install the components in the Programmer section."
!define MUI_COMPONENTSPAGE_TEXT_TOP "NOTE: if any of these components require a reboot, the installer will *not* continue.  You will have to restart the installer, and select everything that did not complete."
!insertmacro MUI_PAGE_COMPONENTS

!define MUI_PAGE_CUSTOMFUNCTION_PRE PreInstFiles
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE LeaveInstFiles
!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_TITLE "Virtual Human - 3rd Party Installer setup"
!define MUI_FINISHPAGE_TITLE_3LINES
!define MUI_FINISHPAGE_TEXT "The 3rd Party setup have completed successfully."
!define MUI_FINISHPAGE_BUTTON "Finish"

!insertmacro MUI_PAGE_FINISH


;--------------------------------
; Languages

!insertmacro MUI_LANGUAGE "English"


;--------------------------------
; Reserve Files

;These files should be inserted before other files in the data block
;Keep these lines before any File command
;Only for solid compression (by default, solid compression is enabled for BZIP2 and LZMA)
!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS


;--------------------------------
; Variables

Var HEADLINE_FONT  ; used in custom page

Var VH_ERROR

Var PageWelcomeDialog
Var PageWelcomeText
Var PageWelcomeHeadline
Var PageWelcomeImage
Var PageWelcomeImageCtl

Var CurrentActiveMQVersion


;--------------------------------
; Sections

Section "${AMQ_DESC}$CurrentActiveMQVersion" s3rdAMQ
  AddSize 22000

  SetOutPath "$INSTDIR\temp3rdPartySW"

  File ${VHBUILD_PATH}${AMQ_PATH}

  DetailPrint "-- ${AMQ_DESC} - ${s3rdAMQ} -------------------"
  ${VHCheckErrors}
  ExecWait '"$INSTDIR\temp3rdPartySW\${AMQ_PATH}"' $0
  ${If} $0 != 0
    DetailPrint "ActiveMQ installer returned $0"
  ${EndIF}

  RMDir /r "$INSTDIR\temp3rdPartySW"
SectionEnd


Section "${NET35_DESC}" s3rdNET35
  AddSize 200000

  SetOutPath "$INSTDIR\temp3rdPartySW"

  File ${VHBUILD_PATH}${NET35_PATH}

  DetailPrint "-- ${NET35_DESC} - ${s3rdNET35} -------------------"
  ${VHCheckErrors}


  ; when on the ICT domain, we need to install .NET 3.5 framework internally.
  ; also, sources are different depending on if we're on Win8 or Win10.
  ; Here's the pseudocode:

  ;    if (win8 or higher)
  ;        if connected to ICT domain
  ;            wmic computersystem get domain
  ;                Domain
  ;                ict.usc.edu
  ;            if (win8)
  ;                DISM /online /enable-feature /featurename:NetFX3 /ALL /Source:\\netapp2\public\netframework3.5\W8 /LimitAccess
  ;            else if (win10)
  ;                DISM /online /enable-feature /featurename:NetFX3 /ALL /Source:\\netapp2\public\netframework3.5\W10 /LimitAccess
  ;        else
  ;            run normally
  ;    else
  ;        run normally

  ; $3 = 0   ; install normally
  ; $3 = 1   ; install internally
  ; $4 = W8  ; internally using win8 sources
  ; $4 = W10 ; internally using win10 sources

  ${GetWindowsVersion} $1

  ; MessageBox MB_OK "OS: $1"  ; 8.0, 8.1, 10.0  higher is not detected

  StrCpy $3 0
  StrCpy $4 "W8"

  ${If} $1 == "8.0"
  ${OrIf} $1 == "8.1"
  ${OrIf} $1 == "10.0"
    ${WMIC} $2 ComputerSystem Domain

    ; MessageBox MB_OK "Domain: $2" ; looking for ict.usc.edu

    ${If} $2 == "ict.usc.edu"
      StrCpy $3 1
      ${If} $1 == "10.0"
        StrCpy $4 "W10"
      ${EndIf}
    ${EndIf}
  ${EndIf}

  ${If} $3 = 0
    ; normal
    ;MessageBox MB_OK "$INSTDIR\temp3rdPartySW\${NET35_PATH}"
    ExecWait '"$INSTDIR\temp3rdPartySW\${NET35_PATH}" /passive' $0
  ${Else}

    ; this makes sure we call 64-bit version of dism.  otherwise, dism fails
    ${DisableX64FSRedirection}

    ;MessageBox MB_OK "DISM /online /enable-feature /featurename:NetFX3 /ALL /Source:\\netapp2\public\netframework3.5\$4 /LimitAccess"
    ;DetailPrint "DISM /online /enable-feature /featurename:NetFX3 /ALL /Source:\\netapp2\public\netframework3.5\$4 /LimitAccess"
    ExecWait 'DISM /online /enable-feature /featurename:NetFX3 /ALL /Source:\\netapp2\public\netframework3.5\$4 /LimitAccess' $0

    ${EnableX64FSRedirection}

  ${EndIf}

  ${If} $0 != 0
    DetailPrint ".NET Framework Redist returned $0"
  ${EndIF}

  RMDir /r "$INSTDIR\temp3rdPartySW"
SectionEnd


Section "${DX_DESC}" s3rdDX
  AddSize 80000

  SetOutPath "$INSTDIR\temp3rdPartySW"

  File /r ${VHBUILD_PATH}${DX_PATH}

  DetailPrint "-- ${DX_DESC} - ${s3rdDX} -------------------"
  ${VHCheckErrors}
  ExecWait '"$INSTDIR\temp3rdPartySW\${DX_PATH}\${DX_EXE}"' $0
  ${If} $0 != 0
    DetailPrint "DirectX Redistributable returned $0"
  ${EndIF}

  RMDir /r "$INSTDIR\temp3rdPartySW"
SectionEnd


Section "${VS2015_DESC}" s3rdVS2015
  AddSize 2000

  SetOutPath "$INSTDIR\temp3rdPartySW"

  File ${VHBUILD_PATH}${VS2015_PATH}

  DetailPrint "-- ${VS2015_DESC} - ${s3rdVS2015} -------------------"
  ${VHCheckErrors}
  ExecWait '"$INSTDIR\temp3rdPartySW\${VS2015_PATH}" /passive' $0
  ${If} $0 != 0
    DetailPrint "VS2015 Redist returned $0"
  ${EndIF}

  RMDir /r "$INSTDIR\temp3rdPartySW"
SectionEnd


Section "-FinalStep"
  ${If} $VH_ERROR = 1
    DetailPrint "** ERRORS ** Installer finished with errors"
    MessageBox MB_OK "There were errors in the install.  Please review the output."
  ${EndIF}
SectionEnd


;--------------------------------
; Descriptions

;Language strings

LangString TEXT_IO_TITLE ${LANG_ENGLISH} "3rd Party install"
LangString TEXT_IO_SUBTITLE ${LANG_ENGLISH} " "


;--------------------------------
; Installer Functions

Function .onInit

  CreateFont $HEADLINE_FONT "$(^Font)" "14" "700"

  InitPluginsDir
  File /oname=$PLUGINSDIR\installerapp.bmp installerapp.bmp

  IntOp $VH_ERROR 0 + 0

  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ActiveMQ" "DisplayVersion"
  ${If} $0 != ""
    StrCpy $CurrentActiveMQVersion " - ($0 currently installed)"
  ${EndIf}

FunctionEnd


;--------------------------------
; Page Functions

Function PageWelcome

  nsDialogs::Create /NOUNLOAD 1044
  Pop $PageWelcomeDialog


  nsDialogs::CreateControl /NOUNLOAD STATIC ${WS_VISIBLE}|${WS_CHILD}|${WS_CLIPSIBLINGS}|${SS_BITMAP} 0 0 0 109u 193u ""
  Pop $PageWelcomeImageCtl

  StrCpy $0 $PLUGINSDIR\installerapp.bmp
  System::Call 'user32::LoadImage(i 0, t r0, i ${IMAGE_BITMAP}, i 0, i 0, i ${LR_LOADFROMFILE}) i.s'
  Pop $PageWelcomeImage

  SendMessage $PageWelcomeImageCtl ${STM_SETIMAGE} ${IMAGE_BITMAP} $PageWelcomeImage

  StrCpy $0 "Welcome to the 3rd Party Installer for Virtual Human Projects."
  nsDialogs::CreateControl /NOUNLOAD STATIC ${WS_VISIBLE}|${WS_CHILD}|${WS_CLIPSIBLINGS} 0 120u 10u -130u 50u $0
  Pop $PageWelcomeHeadline

  SendMessage $PageWelcomeHeadline ${WM_SETFONT} $HEADLINE_FONT 0

  StrCpy $0 "Please click next to continue."
  nsDialogs::CreateControl /NOUNLOAD STATIC ${WS_VISIBLE}|${WS_CHILD}|${WS_CLIPSIBLINGS} 0 130u 75u -160u 50u $0
  Pop $PageWelcomeText


  SetCtlColors $PageWelcomeDialog "" 0xffffff
  SetCtlColors $PageWelcomeHeadline "" 0xffffff
  SetCtlColors $PageWelcomeText "" 0xffffff

  nsDialogs::Show

  System::Call gdi32::DeleteObject(i$PageWelcomeImage)


FunctionEnd


Function PageWelcomeLeave
FunctionEnd


Function Pre3rdPartyComponents
FunctionEnd


Function Leave3rdPartyComponents
  GetInstDirError $0
  ${Switch} $0
    ${Case} 0
      ${Break}
    ${Case} 1
      MessageBox MB_OK "Invalid installation directory!"
      Abort
      ${Break}
    ${Case} 2
      ;MessageBox MB_YESNO|MB_ICONQUESTION "Not enough free space, Continue Install?" IDYES ContinueNotEnoughSpace
      ;Abort
      ;ContinueNotEnoughSpace:
      ${Break}
  ${EndSwitch}

FunctionEnd


Function PreInstFiles
FunctionEnd


Function LeaveInstFiles
FunctionEnd


Function .onInstSuccess
FunctionEnd
