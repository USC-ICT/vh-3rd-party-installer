; vh.nsh


;--------------------------------
; General

!define VHBUILD_PATH "..\"
!define AMQ_PATH     "apache-activemq-5.16.8.0.exe"
!define NET35_PATH   "net35\dotNetFx35setup.exe"
!define DX_PATH      "dxsdk"
!define DX_EXE       "DXSETUP.exe"
!define VS2015_PATH  "vsredist2015\vcredist_x86_vs2015u2.exe"

!define AMQ_DESC     "ActiveMQ Server (5.16.8.0)"
!define NET35_DESC   ".NET Framework Redistributable (3.5)"
!define DX_DESC      "DirectX Redistributable (August 2009)"
!define VS2015_DESC  "Visual Studio 2015 Update 2 Redistributable"


!define VHTOOLKIT_REG_SUBKEY "Software\ICT\VHToolkit"
!define VHTOOLKIT_REG_INSTALL "InstallFolder"


ShowInstDetails show

VIAddVersionKey "Comments" ""
VIAddVersionKey "CompanyName" "ICT"
VIAddVersionKey "LegalTrademarks" ""
VIAddVersionKey "LegalCopyright" ""

!define MUI_ABORTWARNING


;--------------------------------
; Macros

; Macro to check if there were errors in other sections, and if so, skip this section
!macro VHCheckErrors
  ${If} $VH_ERROR = 1
    DetailPrint "   <Skipping due to previous errors in the installation>"
    Return
  ${EndIF}
!macroend
!define VHCheckErrors "!insertmacro VHCheckErrors"


; This function adds the size of the section to $VH_SECTION_SIZE if the section is selected
!macro AddSectionSizeIfSelected SECTION
  Push ${SECTION}
  Call AddSectionSizeIfSelected
!macroend
!define AddSectionSizeIfSelected "!insertmacro AddSectionSizeIfSelected"


!macro VHSetEvironment KEY_NAME VALUE
  ; taken from http://nsis.sourceforge.net/Setting_Environment_Variables
  WriteRegExpandStr HKCU "Environment" ${KEY_NAME} ${VALUE}
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
!macroend
!define VHSetEvironment "!insertmacro VHSetEvironment"


!macro GetTimeModifiedCall _FILE _OPTION _R1 _R2 _R3 _R4 _R5 _R6 _R7
  Push `${_FILE}`
  Push `${_OPTION}`
  Call GetTimeModified
  Pop ${_R1}
  Pop ${_R2}
  Pop ${_R3}
  Pop ${_R4}
  Pop ${_R5}
  Pop ${_R6}
  Pop ${_R7}
!macroend
!define GetTimeModified `!insertmacro GetTimeModifiedCall`


;--------------------------------
; 3rd Party Macros

!insertmacro DriveSpace  ; FileFunc.nsh


;--------------------------------
; Variables

Var VH_SECTION_SIZE


;--------------------------------------
; Functions

; This function adds the size of the section to $VH_SECTION_SIZE if the section is selected
Function AddSectionSizeIfSelected
  Pop $R0
  !insertmacro SectionFlagIsSet $R0 ${SF_SELECTED} "" skipAddSectionSizeIfSelected
    SectionGetSize $R0 $0
    IntOp $VH_SECTION_SIZE $VH_SECTION_SIZE + $0
  skipAddSectionSizeIfSelected:
FunctionEnd


;--------------------------------
; 3rd Party Functions

Function GetTimeModified
    Exch $1
    Exch
    Exch $0
    Exch
    Push $2
    Push $3
    Push $4
    Push $5
    Push $6
    ClearErrors

    StrCmp $1 'L' gettime
    System::Call '*(i,l,l,l,i,i,i,i,&t260,&t14) i .r2'
    System::Call 'kernel32::FindFirstFileA(t,i)i(r0,r2) .r3'
    IntCmp $3 -1 error
    System::Call 'kernel32::FindClose(i)i(r3)'

    gettime:
    System::Call '*(&i2,&i2,&i2,&i2,&i2,&i2,&i2,&i2) i .r0'
    StrCmp $1 'L' 0 filetime
    System::Call 'kernel32::GetLocalTime(i)i(r0)'
    goto convert

    filetime:
    System::Call '*$2(i,l,l,l,i,i,i,i,&t260,&t14)i(,.r6,.r5,.r4)'
    StrCmp $1 'A' 0 +3
    StrCpy $4 $5
    goto +5
    StrCmp $1 'C' 0 +3
    StrCpy $4 $6
    goto +2
    StrCmp $1 'M' 0 error
    System::Call 'kernel32::FileTimeToLocalFileTime(*l,*l)i(r4,.r3)'
    System::Call 'kernel32::FileTimeToSystemTime(*l,i)i(r3,r0)'

    convert:
    System::Call '*$0(&i2,&i2,&i2,&i2,&i2,&i2,&i2,&i2)i\
    (.r5,.r6,.r4,.r0,.r3,.r2,.r1,)'

    IntCmp $0 9 0 0 +2
    StrCpy $0 '0$0'
    IntCmp $1 9 0 0 +2
    StrCpy $1 '0$1'
    IntCmp $2 9 0 0 +2
    StrCpy $2 '0$2'
    IntCmp $3 9 0 0 +2    ; EDF - added zero padding to hour
    StrCpy $3 '0$3'
    IntCmp $6 9 0 0 +2
    StrCpy $6 '0$6'

    StrCmp $4 0 0 +3
    StrCpy $4 Sunday
    goto end
    StrCmp $4 1 0 +3
    StrCpy $4 Monday
    goto end
    StrCmp $4 2 0 +3
    StrCpy $4 Tuesday
    goto end
    StrCmp $4 3 0 +3
    StrCpy $4 Wednesday
    goto end
    StrCmp $4 4 0 +3
    StrCpy $4 Thursday
    goto end
    StrCmp $4 5 0 +3
    StrCpy $4 Friday
    goto end
    StrCmp $4 6 0 error
    StrCpy $4 Saturday
    goto end

    error:
    StrCpy $0 ''
    StrCpy $1 ''
    StrCpy $2 ''
    StrCpy $3 ''
    StrCpy $4 ''
    StrCpy $5 ''
    StrCpy $6 ''
    SetErrors

    end:
    Exch $6
    Exch
    Exch $5
    Exch 2
    Exch $4
    Exch 3
    Exch $3
    Exch 4
    Exch $2
    Exch 5
    Exch $1
    Exch 6
    Exch $0
FunctionEnd


Function GetRoot
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4

  StrCpy $1 $0 2
  StrCmp $1 "\\" UNC
    StrCpy $0 $1
    Goto done

UNC:
  StrCpy $2 3
  StrLen $3 $0
  loop:
    IntCmp $2 $3 "" "" loopend
    StrCpy $1 $0 1 $2
    IntOp $2 $2 + 1
    StrCmp $1 "\" loopend loop
  loopend:
    StrCmp $4 "1" +3
      StrCpy $4 1
      Goto loop
    IntOp $2 $2 - 1
    StrCpy $0 $0 $2

done:
  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Exch $0
FunctionEnd


; http://nsis.sourceforge.net/Get_Windows_version
; GetWindowsVersion 4.1 (2014-10-01)
;
; Based on Yazno's function, http://yazno.tripod.com/powerpimpit/
; Update by Joost Verburg
; Update (Macro, Define, Windows 7 detection) - John T. Haller of PortableApps.com - 2008-01-07
; Update (Windows 8 detection) - Marek Mizanin (Zanir) - 2013-02-07
; Update (Windows 8.1 detection) - John T. Haller of PortableApps.com - 2014-04-04
; Update (Windows 10 TP detection) - John T. Haller of PortableApps.com - 2014-10-01
;
; Usage: ${GetWindowsVersion} $R0
;
; $R0 contains: 95, 98, ME, NT x.x, 2000, XP, 2003, Vista, 7, 8, 8.1, 10.0 or '' (for unknown)

Function GetWindowsVersion

  Push $R0
  Push $R1

  ClearErrors

  ReadRegStr $R0 HKLM \
  "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion

  IfErrors 0 lbl_winnt

  ; we are not NT
  ReadRegStr $R0 HKLM \
  "SOFTWARE\Microsoft\Windows\CurrentVersion" VersionNumber

  StrCpy $R1 $R0 1
  StrCmp $R1 '4' 0 lbl_error

  StrCpy $R1 $R0 3

  StrCmp $R1 '4.0' lbl_win32_95
  StrCmp $R1 '4.9' lbl_win32_ME lbl_win32_98

  lbl_win32_95:
    StrCpy $R0 '95'
  Goto lbl_done

  lbl_win32_98:
    StrCpy $R0 '98'
  Goto lbl_done

  lbl_win32_ME:
    StrCpy $R0 'ME'
  Goto lbl_done

  lbl_winnt:

  StrCpy $R1 $R0 1

  StrCmp $R1 '3' lbl_winnt_x
  StrCmp $R1 '4' lbl_winnt_x

  StrCpy $R1 $R0 3

  StrCmp $R1 '5.0' lbl_winnt_2000
  StrCmp $R1 '5.1' lbl_winnt_XP
  StrCmp $R1 '5.2' lbl_winnt_2003
  StrCmp $R1 '6.0' lbl_winnt_vista
  StrCmp $R1 '6.1' lbl_winnt_7
  StrCmp $R1 '6.2' lbl_winnt_8
  StrCmp $R1 '6.3' lbl_winnt_81
  StrCmp $R1 '6.4' lbl_winnt_10 lbl_error

  lbl_winnt_x:
    StrCpy $R0 "NT $R0" 6
  Goto lbl_done

  lbl_winnt_2000:
    Strcpy $R0 '2000'
  Goto lbl_done

  lbl_winnt_XP:
    Strcpy $R0 'XP'
  Goto lbl_done

  lbl_winnt_2003:
    Strcpy $R0 '2003'
  Goto lbl_done

  lbl_winnt_vista:
    Strcpy $R0 'Vista'
  Goto lbl_done

  lbl_winnt_7:
    Strcpy $R0 '7'
  Goto lbl_done

  lbl_winnt_8:
    Strcpy $R0 '8'
  Goto lbl_done

  lbl_winnt_81:
    ReadRegStr $R2 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentMajorVersionNumber
    ReadRegStr $R3 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentMinorVersionNumber

    ${If} $R2 == "10"
        Strcpy $R0 '10.0'
    ${Else}
        Strcpy $R0 '8.1'
    ${EndIF}
  Goto lbl_done

  lbl_winnt_10:
    ; doesn't work, need to check additional values in registry.  see above in 8.1 section
    Strcpy $R0 '10.0'
  Goto lbl_done

  lbl_error:
    Strcpy $R0 ''
  lbl_done:

  Pop $R1
  Exch $R0

FunctionEnd

!macro GetWindowsVersion OUTPUT_VALUE
	Call GetWindowsVersion
	Pop `${OUTPUT_VALUE}`
!macroend

!define GetWindowsVersion '!insertmacro "GetWindowsVersion"'


; http://nsis.sourceforge.net/WMI_Macro
/*  Macro to remove leading and trailing white spaces from a string.
    Derived from the function originally posted by Iceman_K at: 
    http://nsis.sourceforge.net/Remove_leading_and_trailing_whitespaces_from_a_string
    --------------------------------------------------------------------------------- */
!ifmacrondef _Trim
    !macro _Trim _UserVar _OriginalString
        !define Trim_UID ${__LINE__}

        Push $R1
        Push $R2
        Push `${_OriginalString}`
        Pop $R1

        Loop_${Trim_UID}:
            StrCpy $R2 "$R1" 1
            StrCmp "$R2" " " TrimLeft_${Trim_UID}
            StrCmp "$R2" "$\r" TrimLeft_${Trim_UID}
            StrCmp "$R2" "$\n" TrimLeft_${Trim_UID}
            StrCmp "$R2" "$\t" TrimLeft_${Trim_UID}
            GoTo Loop2_${Trim_UID}
        TrimLeft_${Trim_UID}:   
            StrCpy $R1 "$R1" "" 1
            Goto Loop_${Trim_UID}

        Loop2_${Trim_UID}:
            StrCpy $R2 "$R1" 1 -1
            StrCmp "$R2" " " TrimRight_${Trim_UID}
            StrCmp "$R2" "$\r" TrimRight_${Trim_UID}
            StrCmp "$R2" "$\n" TrimRight_${Trim_UID}
            StrCmp "$R2" "$\t" TrimRight_${Trim_UID}
            GoTo Done_${Trim_UID}
        TrimRight_${Trim_UID}:  
            StrCpy $R1 "$R1" -1
            Goto Loop2_${Trim_UID}

        Done_${Trim_UID}:
            Pop $R2
            Exch $R1
            Pop ${_UserVar}
        !undef Trim_UID
    !macroend
    !ifndef Trim
        !define Trim `!insertmacro _Trim`
    !endif
!endif

/*  WMIC - Retrieves a single property value from a WMI Class
--------------------------------------------------------- */
!ifmacrondef _WMIC
!macro _WMIC _USERVAR _CLASSNAME _PROPERTY
    !define WMIC_UID ${__LINE__}
    ClearErrors

    Push $0
    Push $1
    Push $2

    Push ${_USERVAR}
    Push ${_CLASSNAME}
    Push ${_PROPERTY}

    Pop $2 ; _PROPERTY
    Pop $1 ; _CLASSNAME
    Pop $0 ; _USERVAR

    nsExec::ExecToStack /OEM 'WMIC $1 Get $2 /FORMAT:textvaluelist.xsl'
    Pop $0

    StrCmp $0 0 0 Else_${WMIC_UID}
        Pop $0
        ${Trim} $0 $0
        StrLen $1 $2
        IntOp $1 $1 + 1
        StrCpy $0 $0 ${NSIS_MAX_STRLEN} $1
        Goto End_${WMIC_UID}
    Else_${WMIC_UID}:
        SetErrors
        StrCpy $0 ""
    End_${WMIC_UID}:

    Pop  $2
    Pop  $1
    Exch $0
    Pop ${_USERVAR}

    !undef WMIC_UID
!macroend
!ifndef WMIC
    !define WMIC "!insertmacro _WMIC"
!endif
!endif
