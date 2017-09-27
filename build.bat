
set NSIS="%ProgramFiles(x86)%\nsis\makensis.exe"


pushd installer
%NSIS% apache-activemq.nsi
popd
