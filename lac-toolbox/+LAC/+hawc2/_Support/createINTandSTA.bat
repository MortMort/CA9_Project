
echo "Running createINTandSTA on %filename%" >> ..\log\createINTandSTA.log

cd ..
cd res


setlocal enableextensions enabledelayedexpansion
set /a count=0
for /f "tokens=*" %%i in (HAWC2postprepinput.txt ) do (
set /a count=count+1
set /a cnt2=count
echo %count%
echo !count!
echo %%i>> %filename%post.txt
if !count!==6 goto skipRestOfLines
)

:skipRestOfLines


echo ^1>> %filename%post.txt
echo %filename%.int>>  %filename%post.txt

HAWC2ConvertSensorFile_beta16.exe -overwrite %filename%post.txt > ..\log\%filename%post.log

rem If not ok, then retry
if %ERRORLEVEL% EQU 0 goto CONVERTSUCCESS 
echo "Error when converting int file %filename%, Error: %ERRORLEVEL%" >> ..\log\createINTandSTA.log
echo "Retrying to convert int file %filename%" >> ..\log\createINTandSTA.log
HAWC2ConvertSensorFile_beta16.exe -overwrite %filename%post.txt > ..\log\%filename%post.log
echo "Done second run of int file conversion on %filename%, returned error level %ERRORLEVEL%" >> ..\log\createINTandSTA.log

if %ERRORLEVEL% NEQ 0 goto THEEND


:CONVERTSUCCESS
echo "Done running converting to INT file on %filename%, returned error level %ERRORLEVEL%" >> ..\log\createINTandSTA.log

del %filename%post.txt

cd ..
cd int

statist2 %filename%.int ..\sta\%filename%.sta
echo "Done running statist on %filename%, returned error level %ERRORLEVEL%" >> ..\log\createINTandSTA.log


:THEEND
echo "Done running createINTandSTA on %filename%, returned error level %ERRORLEVEL%" >> ..\log\createINTandSTA.log
cd ..
cd inputs

