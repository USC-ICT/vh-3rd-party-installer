
@rem this is the default path for NSIS
set NSIS="%ProgramFiles(x86)%\nsis\makensis.exe"


@rem set up path, needed for signtool
call "%VS140COMNTOOLS%\..\..\VC\vcvarsall.bat" x86


@rem generate the ActiveMQ installer
pushd installer
%NSIS% apache-activemq.nsi
popd

@rem sign the installer
signtool sign /t http://timestamp.digicert.com apache-activemq-5.16.8.0.exe


@rem generate the 3rd Party installer
pushd installer
%NSIS% /DTHIRD_PARTY_VERSION=0.1.9 vh-3rd-party-installer.nsi
popd

@rem sign the installer
signtool sign /t http://timestamp.digicert.com vh-3rd-party-installer-0.1.9.exe
