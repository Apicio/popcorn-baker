@ECHO OFF
SETLOCAL EnableDelayedExpansion

TITLE POPCORN-TIME BAKER

:: NODEJS VERSION
SET nodejsVersion=0.10.28
SET nodejsArch=x86

:: POPCORN VERSION
SET PT_REPO=master

:: MOVE INSTALLERS TO CLOUD OR FOLDER
SET PUB=C:\POPCORN-TIME-BUILDS

:: PATH NSIS (no edits necessary)
SET WHEREISNSIS=
IF /i NOT "%PROCESSOR_ARCHITECTURE%"=="x86" SET WHEREISNSIS=\Wow6432Node
FOR /F "tokens=2*" %%F in ('REG QUERY HKLM\SOFTWARE%WHEREISNSIS%\Microsoft\Windows\CurrentVersion\Uninstall\NSIS /v InstallLocation') DO SET makeNsis=%%G
SET makeNsis=%makeNsis%

:: POPCORN APP DOWNLOAD (no edits necessary)
SET popcornUrl=https://github.com/popcorn-official/popcorn-app/archive/%PT_REPO%.zip
SET popcornZip=popcorn-app.zip

:: NODEJS VARS (no edits necessary)
SET nodejsPath=%~dp0
SET nodejsPath=!nodejsPath:~0,-1!
SET nodejsWork=%nodejsPath%\work
SET nodejsModules=%nodejsPath%\node_modules
SET npmPath=%nodejsPath%\node_modules\npm
SET npmGlobalConfigFilePath=%npmPath%\npmrc
SET nodejsMsiPackage=node-v%nodejsVersion%-%nodejsArch%.msi
IF %nodejsArch%==x64 SET nodejsUrl=http://nodejs.org/dist/v%nodejsVersion%/x64/%nodejsMsiPackage%
IF %nodejsArch%==x86 SET nodejsUrl=http://nodejs.org/dist/v%nodejsVersion%/%nodejsMsiPackage%

:: VBS SCRIPTS (no edits necessary)
SET UnzipVbs=%TEMP%\unzip.vbs
SET popcornVbs=%TEMP%\popcorn_install.vbs
SET nodejsInstallVbs=%TEMP%\nodejs_install.vbs

:: BAT SCRIPTS (no edits necessary)
SET installMod1="%nodejsWork%\installMod1.bat"
SET installMod2="%nodejsWork%\installMod2.bat"
SET installMod3="%nodejsWork%\installMod3.bat"

:: OTHER POPCORN VARS (no edits necessary)
SET INSTALLERWIN="%nodejsWork%\popcorn-app-%PT_REPO%\dist\windows"

CLS
GOTO INSTALL

::::::::::::::::::::::::::::::::::::::::
:INSTALL
::::::::::::::::::::::::::::::::::::::::

:: IS NODEJS INSTALLED?
IF EXIST "%nodejsPath%\node.exe" ECHO Node.js is already installed... && GOTO POPCORN-INSTALL

:: CREATE TEMP DIR
SET TEMP=%nodejsPath%\tmp
IF NOT EXIST "%TEMP%" MKDIR "%TEMP%"

:: PREPARE CSCRIPT
ECHO WScript.StdOut.Write "Download " ^& "%nodejsUrl%" ^& " ">%nodejsInstallVbs%
ECHO dim http: set http = createobject("WinHttp.WinHttpRequest.5.1") >>%nodejsInstallVbs%
ECHO dim bStrm: set bStrm = createobject("Adodb.Stream") >>%nodejsInstallVbs%
ECHO http.Open "GET", "%nodejsUrl%", True >>%nodejsInstallVbs%
ECHO http.Send >>%nodejsInstallVbs%
ECHO while http.WaitForResponse(0) = 0 >>%nodejsInstallVbs%
ECHO   WScript.StdOut.Write "." >>%nodejsInstallVbs%
ECHO   WScript.Sleep 1000 >>%nodejsInstallVbs%
ECHO wend >>%nodejsInstallVbs%
ECHO WScript.StdOut.WriteLine " [HTTP " ^& http.Status ^& " " ^& http.StatusText ^& "]" >>%nodejsInstallVbs%
ECHO with bStrm >>%nodejsInstallVbs%
ECHO .type = 1 '//binary >>%nodejsInstallVbs%
ECHO .open >>%nodejsInstallVbs%
ECHO .write http.responseBody >>%nodejsInstallVbs%
ECHO .savetofile "%TEMP%\%nodejsMsiPackage%", 2 >>%nodejsInstallVbs%
ECHO end with >>%nodejsInstallVbs%

:: DOWNLOAD LATEST VERSION
cscript.exe /NoLogo %nodejsInstallVbs%

:: EXTRACT THE MSI
ECHO Install node.js in %nodejsPath%...
msiexec /a "%TEMP%\%nodejsMsiPackage%" /qn TARGETDIR="%nodejsPath%"
XCOPY "%nodejsPath%\nodejs" "%nodejsPath%" /s /e /i /h /y

:: CLEANUP
IF EXIST "%nodejsPath%\nodejs" RMDIR /s /q "%nodejsPath%\nodejs"
IF EXIST "%TEMP%" RMDIR /s /q "%TEMP%"
IF EXIST "%nodejsPath%\%nodejsMsiPackage%" DEL "%nodejsPath%\%nodejsMsiPackage%"

:: FINISH INSTALLATION
ECHO.
IF EXIST "%nodejsPath%\node.exe" ECHO Node.js successfully installed in '%nodejsPath%'
IF NOT EXIST "%nodejsPath%\node.exe" ECHO An error occurred during the installation.
GOTO POPCORN-INSTALL

::::::::::::::::::::::::::::::::::::::::
:POPCORN-INSTALL
::::::::::::::::::::::::::::::::::::::::
IF NOT EXIST "%nodejsPath%\node.exe" ECHO Node.js is not installed... Please install first... && GOTO EOF

:: CREATE TEMP DIR
SET TEMP=%nodejsPath%\tmp
IF NOT EXIST "%TEMP%" MKDIR "%TEMP%"

:: PREPARE CSCRIPT DOWNLOAD
ECHO WScript.StdOut.Write "Download " ^& "%popcornUrl%" ^& " ">%popcornVbs%
ECHO dim http: set http = createobject("WinHttp.WinHttpRequest.5.1") >>%popcornVbs%
ECHO dim bStrm: set bStrm = createobject("Adodb.Stream") >>%popcornVbs%
ECHO http.Open "GET", "%popcornUrl%", True >>%popcornVbs%
ECHO http.Send >>%popcornVbs%
ECHO while http.WaitForResponse(0) = 0 >>%popcornVbs%
ECHO   WScript.StdOut.Write "." >>%popcornVbs%
ECHO   WScript.Sleep 1000 >>%popcornVbs%
ECHO wend >>%popcornVbs%
ECHO WScript.StdOut.WriteLine " [HTTP " ^& http.Status ^& " " ^& http.StatusText ^& "]" >>%popcornVbs%
ECHO with bStrm >>%popcornVbs%
ECHO .type = 1 '//binary >>%popcornVbs%
ECHO .open >>%popcornVbs%
ECHO .write http.responseBody >>%popcornVbs%
ECHO .savetofile "%TEMP%\%popcornZip%", 2 >>%popcornVbs%
ECHO end with >>%popcornVbs%

:: DOWNLOAD LATEST VERSION
cscript.exe /NoLogo %popcornVbs%

:: IF EXIST, CLEAN UP FIRST
IF EXIST "%nodejsWork%\popcorn-app-%PT_REPO%" RMDIR /S /Q "%nodejsWork%\popcorn-app-%PT_REPO%"

:: PREPARE CSCRIPT EXTRACT
ECHO ZipFile="%TEMP%\%popcornZip%" >%UnzipVbs%
ECHO ExtractTo="%nodejsPath%\work\" >>%UnzipVbs%
ECHO Set fso = CreateObject("Scripting.FileSystemObject") >>%UnzipVbs%
ECHO If NOT fso.FolderExists(ExtractTo) Then >>%UnzipVbs%
ECHO fso.CreateFolder(ExtractTo) >>%UnzipVbs%
ECHO End If >>%UnzipVbs%
ECHO set objShell = CreateObject("Shell.Application") >>%UnzipVbs%
ECHO set FilesInZip=objShell.NameSpace(ZipFile).items >>%UnzipVbs%
ECHO objShell.NameSpace(ExtractTo).CopyHere(FilesInZip) >>%UnzipVbs%
ECHO Set fso = Nothing >>%UnzipVbs%
ECHO Set objShell = Nothing >>%UnzipVbs%

:: EXTRACT POPCORN
cscript.exe /NoLogo %UnzipVbs%

:: RELOCATE AND EDIT NPM
ECHO prefix = %nodejsPath%\ >%npmGlobalConfigFilePath%
ECHO globalconfig = %npmPath%\npmrc >>%npmGlobalConfigFilePath%
ECHO globalignorefile = %npmPath%\npmignore >>%npmGlobalConfigFilePath%
ECHO init-module = %npmPath%\init.js >>%npmGlobalConfigFilePath%
ECHO cache = %npmPath%\cache >>%npmGlobalConfigFilePath%
IF NOT EXIST "%nodejsWork%" MKDIR "%nodejsWork%"
IF NOT EXIST "%npmPath%\npmignore" ECHO. 2>"%npmPath%\npmignore"
IF NOT EXIST "%npmPath%\init.js" ECHO. 2>"%npmPath%\init.js"
IF NOT EXIST "%npmPath%\cache" MKDIR "%npmPath%\cache"

:: Init node vars
cmd.exe /c "cd "%nodejsWork%" && "%nodejsPath%\nodevars.bat" && "%nodejsPath%\npm" config set globalconfig "%npmGlobalConfigFilePath%" --global"

:: SET TEMPORARY NODE.JS PATH
set PATH=%PATH%;%nodejsPath%

:: WHERE IS GIT? SET TEMPORARY PATH
SET WHEREISGIT=
IF /i NOT "%PROCESSOR_ARCHITECTURE%"=="x86" SET WHEREISGIT=\Wow6432Node
FOR /F "tokens=2*" %%F in ('REG QUERY HKLM\SOFTWARE%WHEREISGIT%\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1 /v InstallLocation') DO SET GIT=%%G
SET PATH=%PATH%;%GIT%cmd;

:: PREPARE INSTALL SCRIPT NODE MODULES
ECHO @ECHO OFF >%installMod1%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod1%
ECHO cd "%nodejsWork%\popcorn-app-%PT_REPO%\" >>%installMod1%
ECHO npm install -g grunt-cli bower >>%installMod1%

ECHO @ECHO OFF >%installMod2%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod2%
ECHO cd "%nodejsWork%\popcorn-app-%PT_REPO%" >>%installMod2%
ECHO npm install >>%installMod2%

ECHO @ECHO OFF >%installMod3%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod3%
ECHO cd "%nodejsWork%\popcorn-app-%PT_REPO%\" >>%installMod3%
ECHO grunt build >>%installMod3%

:: INSTALL NODE MODULES
CALL %installMod1%
CALL %installMod2%
CALL %installMod3%

:: BUILD
ECHO Creating installer...
IF EXIST "%INSTALLERWIN%\installer.nsi" "%makeNsis%\makensis.exe" /V0 "%INSTALLERWIN%\installer.nsi"
ECHO Creating updater...
IF EXIST "%INSTALLERWIN%\updater.nsi" "%makeNsis%\makensis.exe" /V0 "%INSTALLERWIN%\updater.nsi"

:: CREATE DIR TO MOVE POPCORN
IF NOT EXIST "%PUB%\" MKDIR "%PUB%"

:: INSTALLER
IF EXIST "%INSTALLERWIN%\Popcorn-Time-*.exe" MOVE /Y "%INSTALLERWIN%\Popcorn-Time-*.exe" "%PUB%\"
:: UPDATER
IF EXIST "%INSTALLERWIN%\Updater-Popcorn-Time-*.exe" MOVE /Y "%INSTALLERWIN%\Updater-Popcorn-Time-*.exe" "%PUB%\"

:: CLEANUP
IF EXIST "%TEMP%" RMDIR /s /q "%TEMP%"
IF EXIST "%nodejsWork%" RMDIR /s /q "%nodejsWork%"

::::::::::::::::::::::::::::::::::::::::
:EOF
::::::::::::::::::::::::::::::::::::::::
ECHO.
ECHO YUMMIE... LETS HAVE SOME POPCORN!
ping 1.1.1.1 -n 1 -w 3000 > nul
ECHO.

::::::::::::::::::::::::::::::::::::::::
:EXIT
::::::::::::::::::::::::::::::::::::::::
ENDLOCAL
