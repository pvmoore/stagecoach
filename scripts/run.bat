@echo off
cls
chcp 65001

if "%1"=="" (
    set PROJECT=examples
) else (
    set PROJECT=examples\%1
) 

rem cd ..


del /Q .target\*.*

if not exist "stagecoach.exe" goto COMPILE
del stagecoach.exe

:COMPILE
dub build --parallel --build=debug --config=test --arch=x86_64 --compiler=dmd


if not exist "stagecoach.exe" goto FAIL
stagecoach.exe %PROJECT%


if not exist ".target\test.exe" goto FAIL
call getfilesize.bat .target\test.exe
echo.
echo Running [.target\test.exe] (%filesize% bytes)
echo.
.target\test.exe
IF %ERRORLEVEL% NEQ 0 (
  echo.
  echo.
  echo !! Exit code was %ERRORLEVEL%
)
echo.
goto END


:FAIL


:END

echo. 
