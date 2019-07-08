clear

./qt-unified-windows-x86-3.1.1-online.exe -v --script qt-installer-noninteractive.qs components=`"qt.qt5.5124.win32_msvc2017 qt.qt5.5124.win64_msvc2017_64`" | Tee-Object -FilePath ./full-log.txt | Select-String -Pattern 'choco:info|choco:warn|choco:error'

echo "Result: $? $LastExitCode"