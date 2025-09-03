@echo off
rem run from window with double click or from cmd.exe or Powershell

rem the following line tests if express is installed and valid (tree is not empty)
node -e "try{require('express');process.exit(0);}catch(e){process.exit(1);}"
if errorlevel 1 (
    rem for convenience, install express locally if not already installed
    echo "installing express (see folder node_modules) ..."
    call npm install express
)

npm start
