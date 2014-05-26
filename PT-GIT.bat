@ECHO OFF
SETLOCAL EnableDelayedExpansion

TITLE POPCORN-TIME BAKER

:: POPCORN-TIME BAKER
:: VERSION: 0.1

:: NODEJS VERSION
SET nodejsVersion=0.10.28
SET nodejsArch=x86

:: POPCORN VERSION
SET PT_VERSION=0.3.1

:: MOVE INSTALLERS TO CLOUD OR FOLDER
SET PUB=C:\POPCORN-TIME-BUILDS

:: PATHS NSIS - http://nsis.sourceforge.net/Main_Page
SET makeNsis=C:\PROGRA~2\NSIS

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
SET INSTMAST="%nodejsWork%\popcorn-app-master\dist\windows"
SET INSTDEV="%nodejsWork%\popcorn-app-dev-0.3\dist\windows"

:: Check if the menu selection is provided as a command line parameter
IF NOT "%nodejsTask%"=="" GOTO ACTION

::::::::::::::::::::::::::::::::::::::::
:MENU
::::::::::::::::::::::::::::::::::::::::
IF EXIST "%TEMP%" RMDIR /s /q "%TEMP%"
IF EXIST "%nodejsWork%" RMDIR /s /q "%nodejsWork%"

CLS
ECHO.
ECHO # POPCORN BAKER
ECHO.
ECHO  1 - Build Popcorn-Time Master
ECHO  2 - Build Popcorn-Time Dev-0.3
ECHO  9 - Exit
ECHO.
SET /P nodejsTask=Choose a task:
ECHO.

::::::::::::::::::::::::::::::::::::::::
:ACTION
::::::::::::::::::::::::::::::::::::::::
IF %nodejsTask% == 1 GOTO POPCORN-MASTER
IF %nodejsTask% == 2 GOTO POPCORN-DEV
IF %nodejsTask% == 9 GOTO EXIT
IF %nodejsTask% == 0 GOTO INSTALL-NODE
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
:POPCORN-MASTER
::::::::::::::::::::::::::::::::::::::::
IF NOT EXIST "%nodejsPath%\node.exe" ECHO Node.js is not installed... Please install first... && GOTO MENU

:: CREATE TEMP DIR
SET TEMP=%nodejsPath%\tmp
IF NOT EXIST "%TEMP%" MKDIR "%TEMP%"

:: DOWNLOAD LATEST VERSION
git clone https://github.com/popcorn-official/popcorn-app.git "%nodejsWork%\popcorn-app-master"

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
"cd "%nodejsWork%" && "%nodejsPath%\nodevars.bat" && "%nodejsPath%\npm" config set globalconfig "%npmGlobalConfigFilePath%" --global"

:: PREPARE INSTALL SCRIPT NODE MODULES
ECHO @ECHO OFF >%installMod1%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod1%
ECHO cd "%nodejsWork%\popcorn-app-master\" >>%installMod1%
ECHO npm install -g grunt-cli bower >>%installMod1%

ECHO @ECHO OFF >%installMod2%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod2%
ECHO cd "%nodejsWork%\popcorn-app-master" >>%installMod2%
ECHO npm install >>%installMod2%

ECHO @ECHO OFF >%installMod3%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod3%
ECHO cd "%nodejsWork%\popcorn-app-master\" >>%installMod3%
ECHO grunt build >>%installMod3%

:: INSTALL NODE MODULES
CALL %installMod1%
CALL %installMod2%
CALL %installMod3%

:: BUILD
IF EXIST "%INSTMAST%\installer.nsi" "%makeNsis%\makensis.exe" /V0 "%INSTMAST%\installer.nsi"
IF EXIST "%INSTMAST%\updater.nsi" "%makeNsis%\makensis.exe" /V0 "%INSTMAST%\updater.nsi"

:: CREATE DIR TO MOVE POPCORN
IF NOT EXIST "%PUB%\" MKDIR "%PUB%"

:: INSTALLER
IF EXIST "%INSTMAST%\Popcorn-Time-%PT_VERSION%-Win-32.exe" MOVE /Y "%INSTMAST%\Popcorn-Time-%PT_VERSION%-Win-32.exe" "%PUB%\"
:: UPDATER
IF EXIST "%INSTMAST%\Updater-Popcorn-Time-%PT_VERSION%-Win-32.exe" MOVE /Y "%INSTMAST%\Updater-Popcorn-Time-%PT_VERSION%-Win-32.exe" "%PUB%\"
GOTO MENU

::::::::::::::::::::::::::::::::::::::::
:POPCORN-DEV
::::::::::::::::::::::::::::::::::::::::
IF NOT EXIST "%nodejsPath%\node.exe" ECHO Node.js is not installed... Please install first... && GOTO MENU

:: CREATE TEMP DIR
SET TEMP=%nodejsPath%\tmp
IF NOT EXIST "%TEMP%" MKDIR "%TEMP%"

:: DOWNLOAD LATEST VERSION
git clone https://github.com/popcorn-official/popcorn-app.git -b dev-0.3 "%nodejsWork%\popcorn-app-dev-0.3"

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
"cd "%nodejsWork%" && "%nodejsPath%\nodevars.bat" && "%nodejsPath%\npm" config set globalconfig "%npmGlobalConfigFilePath%" --global"

:: PREPARE INSTALL SCRIPT NODE MODULES
ECHO @ECHO OFF >%installMod1%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod1%
ECHO cd "%nodejsWork%\popcorn-app-dev-0.3\" >>%installMod1%
ECHO npm install -g grunt-cli bower >>%installMod1%

ECHO @ECHO OFF >%installMod2%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod2%
ECHO cd "%nodejsWork%\popcorn-app-dev-0.3" >>%installMod2%
ECHO npm install >>%installMod2%

ECHO @ECHO OFF >%installMod3%
ECHO SETLOCAL EnableDelayedExpansion >>%installMod3%
ECHO cd "%nodejsWork%\popcorn-app-dev-0.3\" >>%installMod3%
ECHO grunt build >>%installMod3%

:: INSTALL NODE MODULES
CALL %installMod1%
CALL %installMod2%
CALL %installMod3%

:: BUILD
IF EXIST "%INSTDEV%\installer.nsi" "%makeNsis%\makensis.exe" /V0 "%INSTDEV%\installer.nsi"
IF EXIST "%INSTDEV%\updater.nsi" "%makeNsis%\makensis.exe" /V0 "%INSTDEV%\updater.nsi"

:: CREATE DIR TO MOVE POPCORN
IF NOT EXIST "%PUB%\" MKDIR "%PUB%"

:: DEV-INSTALLER
IF EXIST "%INSTDEV%\Popcorn-Time-%PT_VERSION%-Win-32.exe" RENAME "%INSTDEV%\Popcorn-Time-%PT_VERSION%-Win-32.exe" "Popcorn-Time-dev-0.3.exe"
IF EXIST "%INSTDEV%\Popcorn-Time-dev-0.3.exe" MOVE /Y "%INSTDEV%\Popcorn-Time-dev-0.3.exe" "%PUB%\"

:: DEV-UPDATER
IF EXIST "%INSTDEV%\Updater-Popcorn-Time-%PT_VERSION%-Win-32.exe" RENAME "%INSTDEV%\Updater-Popcorn-Time-%PT_VERSION%-Win-32.exe" "Updater-Popcorn-Time-dev-0.3.exe" 
IF EXIST "%INSTDEV%\Updater-Popcorn-Time-dev-0.3.exe" MOVE /Y "%INSTDEV%\Updater-Popcorn-Time-dev-0.3.exe" "%PUB%\"
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