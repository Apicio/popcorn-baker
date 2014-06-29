@ECHO OFF
SETLOCAL EnableDelayedExpansion

TITLE POPCORN-TIME BAKER

:: NODEJS VERSION
SET nodejsVersion=0.10.29
SET nodejsArch=x86

:: POPCORN VERSION
SET PT_REPO1=master
SET PT_REPO2=stable

:: MOVE INSTALLERS TO CLOUD OR FOLDER
SET PUB=C:\POPCORN-TIME-BUILDS

:: ACTION AFTER BUILD (run setup = r, open explorer = o, exit = e) 
SET setupTask=o

:: PATH NSIS (no edits necessary)
SET WHEREISNSIS=
IF /i NOT "%PROCESSOR_ARCHITECTURE%"=="x86" SET WHEREISNSIS=\Wow6432Node
FOR /F "tokens=2*" %%F in ('REG QUERY HKLM\SOFTWARE%WHEREISNSIS%\Microsoft\Windows\CurrentVersion\Uninstall\NSIS /v InstallLocation') DO SET makeNsis=%%G
SET makeNsis=%makeNsis%

:: NODEJS VARS (no edits necessary)
SET nodejsTask=0
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
SET nodejsInstallVbs=%TEMP%\nodejs_install.vbs

:: BAT SCRIPTS (no edits necessary)
SET installMod1="%nodejsWork%\installMod1.bat"
SET installMod2="%nodejsWork%\installMod2.bat"
SET installMod3="%nodejsWork%\installMod3.bat"

:: OTHER POPCORN VARS (no edits necessary)
SET INST1=%nodejsWork%\popcorn-app-%PT_REPO1%\dist\windows
SET INST2=%nodejsWork%\popcorn-app-%PT_REPO2%\dist\windows
SET MOVEFROM1=%nodejsWork%\popcorn-app-%PT_REPO1%\dist\windows
SET MOVEFROM2=%nodejsWork%\popcorn-app-%PT_REPO2%\build\releases\Popcorn-Time\win
SET VERBOSE=0

:: Check if the menu selection is provided as a command line parameter
IF NOT "%nodejsTask%"=="" GOTO ACTION

::::::::::::::::::::::::::::::::::::::::
:MENU
::::::::::::::::::::::::::::::::::::::::
IF EXIST "%TEMP%" RMDIR /s /q "%TEMP%"
IF EXIST "%nodejsWork%" RMDIR /s /q "%nodejsWork%"

CLS
ECHO.
ECHO  # POPCORN BAKER
ECHO.
ECHO  1 - Build Popcorn-Time %PT_REPO1%
ECHO  2 - Build Popcorn-Time %PT_REPO2% 
ECHO.
ECHO  9 - Exit
ECHO.
SET /P nodejsTask=Choose a task:
ECHO.

::::::::::::::::::::::::::::::::::::::::
:ACTION
::::::::::::::::::::::::::::::::::::::::
IF %nodejsTask% == 1 GOTO POPCORN1
IF %nodejsTask% == 2 GOTO POPCORN2
IF %nodejsTask% == 9 GOTO EXIT
IF %nodejsTask% == 0 GOTO INSTALL-NODE

:: ACTION AFTER BUILD 
IF %setupTask% == o GOTO OPENEXPLORER
IF %setupTask% == r GOTO RUNSETUP
IF %setupTask% == e GOTO EOF

GOTO MENU
::::::::::::::::::::::::::::::::::::::::
:INSTALL-NODE
::::::::::::::::::::::::::::::::::::::::

:: IS NODEJS INSTALLED?
IF EXIST "%nodejsPath%\node.exe" ECHO Node.js is already installed... && GOTO MENU

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
GOTO MENU

::::::::::::::::::::::::::::::::::::::::
:POPCORN1
::::::::::::::::::::::::::::::::::::::::
IF NOT EXIST "%nodejsPath%\node.exe" ECHO Node.js is not installed... Please install first... && GOTO MENU

:: CREATE TEMP DIR
SET TEMP=%nodejsPath%\tmp
IF NOT EXIST "%TEMP%" MKDIR "%TEMP%"

:: WHERE IS GIT? SET TEMPORARY PATH
SET WHEREISGIT=
IF /i NOT "%PROCESSOR_ARCHITECTURE%"=="x86" SET WHEREISGIT=\Wow6432Node
FOR /F "tokens=2*" %%F in ('REG QUERY HKLM\SOFTWARE%WHEREISGIT%\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1 /v InstallLocation') DO SET GIT=%%G
SET PATH=%PATH%;%GIT%cmd;

:: DOWNLOAD LATEST VERSION
git clone https://github.com/popcorn-official/popcorn-app.git "%nodejsWork%\popcorn-app-%PT_REPO1%"

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

:: PREPARE INSTALL SCRIPT NODE MODULES
ECHO @ECHO OFF >%installMod1%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod1%
ECHO cd "%nodejsWork%\popcorn-app-%PT_REPO1%\" >>%installMod1%
ECHO npm install -g grunt-cli bower >>%installMod1%

ECHO @ECHO OFF >%installMod2%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod2%
ECHO cd "%nodejsWork%\popcorn-app-%PT_REPO1%" >>%installMod2%
ECHO npm install >>%installMod2%

ECHO @ECHO OFF >%installMod3%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod3%
ECHO cd "%nodejsWork%\popcorn-app-%PT_REPO1%\" >>%installMod3%
ECHO grunt build >>%installMod3%

:: INSTALL NODE MODULES
CALL %installMod1%
CALL %installMod2%
CALL %installMod3%

:: CREATE DIR TO MOVE POPCORN
IF NOT EXIST "%PUB%\" MKDIR "%PUB%"

:: INSTALLER
ECHO Creating Popcorn Time %PT_REPO1% - Installer...
IF EXIST "%INST1%\installer.nsi" "%makeNsis%\makensis.exe" /V%VERBOSE% "%INST1%\installer.nsi"
IF EXIST "%MOVEFROM1%\PopcornTime*.exe" RENAME "%MOVEFROM1%\PopcornTime*.exe" "PopcornTime-%PT_REPO1%.exe"
IF EXIST "%MOVEFROM1%\PopcornTime-%PT_REPO1%.exe" MOVE /Y "%MOVEFROM1%\PopcornTime-%PT_REPO1%.exe" "%PUB%"

:OPENEXPLORER
explorer %PUB% 

:RUNSETUP
START "" "%PUB%\PopcornTime-%PT_REPO1%.exe" >NUL 2>&1

GOTO MENU

::::::::::::::::::::::::::::::::::::::::
:POPCORN2
::::::::::::::::::::::::::::::::::::::::
IF NOT EXIST "%nodejsPath%\node.exe" ECHO Node.js is not installed... Please install first... && GOTO MENU

:: CREATE TEMP DIR
SET TEMP=%nodejsPath%\tmp
IF NOT EXIST "%TEMP%" MKDIR "%TEMP%"

:: WHERE IS GIT? SET TEMPORARY PATH
SET WHEREISGIT=
IF /i NOT "%PROCESSOR_ARCHITECTURE%"=="x86" SET WHEREISGIT=\Wow6432Node
FOR /F "tokens=2*" %%F in ('REG QUERY HKLM\SOFTWARE%WHEREISGIT%\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1 /v InstallLocation') DO SET GIT=%%G
SET PATH=%PATH%;%GIT%cmd;

:: DOWNLOAD LATEST VERSION
git clone https://github.com/popcorn-official/popcorn-app.git -b %PT_REPO2% "%nodejsWork%\popcorn-app-%PT_REPO2%"

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

:: PREPARE INSTALL SCRIPT NODE MODULES
ECHO @ECHO OFF >%installMod1%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod1%
ECHO cd "%nodejsWork%\popcorn-app-%PT_REPO2%\" >>%installMod1%
ECHO npm install -g grunt-cli bower >>%installMod1%

ECHO @ECHO OFF >%installMod2%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod2%
ECHO cd "%nodejsWork%\popcorn-app-%PT_REPO2%" >>%installMod2%
ECHO npm install >>%installMod2%

ECHO @ECHO OFF >%installMod3%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod3%
ECHO cd "%nodejsWork%\popcorn-app-%PT_REPO2%\" >>%installMod3%
ECHO grunt build >>%installMod3%

:: INSTALL NODE MODULES
CALL %installMod1%
CALL %installMod2%
CALL %installMod3%

:: CREATE DIR TO MOVE POPCORN
IF NOT EXIST "%PUB%" MKDIR "%PUB%"

:: INSTALLER
ECHO Creating Popcorn Time %PT_REPO2% - Installer...
IF EXIST "%INST2%\installer.nsi" "%makeNsis%\makensis.exe" /V%VERBOSE% "%INST2%\installer.nsi"
IF EXIST "%MOVEFROM2%\Popcorn-Time-*.exe" RENAME "%MOVEFROM2%\Popcorn-Time-*.exe" "PopcornTime-%PT_REPO2%.exe"
IF EXIST "%MOVEFROM2%\PopcornTime-%PT_REPO2%.exe" MOVE /Y "%MOVEFROM2%\PopcornTime-%PT_REPO2%.exe" "%PUB%"

:OPENEXPLORER
explorer %PUB% 

:RUNSETUP
START "" "%PUB%\PopcornTime-%PT_REPO2%.exe" >NUL 2>&1

GOTO MENU

::::::::::::::::::::::::::::::::::::::::
:EOF
::::::::::::::::::::::::::::::::::::::::
ping 1.1.1.1 -n 1 -w 3000 > nul
ECHO.

::::::::::::::::::::::::::::::::::::::::
:EXIT
::::::::::::::::::::::::::::::::::::::::
ENDLOCAL
