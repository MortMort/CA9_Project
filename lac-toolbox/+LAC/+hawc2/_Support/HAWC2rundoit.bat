::HAWC2V05.exe %DirPath%\inputs\%masfile% %filename%
::HAWC2mb ..\htcfiles\%filename%.htc
if %ERRORLEVEL% NEQ 0 goto THEEND
echo Simulation executed successfully >> ..\log\%filename%.log
echo Simulation executed successfully >> ..\int\%filename%.int
createINTandSTA.bat
exit /b
:THEEND
if %ERRORLEVEL% NEQ 47 goto THEEND2
echo Simulation terminated with errorlevel: %ERRORLEVEL%, HAWC2 may have finished, but choked on creating the sensor file. Retrying >> ..\log\%filename%.log
createINTandSTA.bat
::echo Simulation terminated with errorlevel3: %ERRORLEVEL% >> ..\log2\%filename%.log

:THEEND2
echo Simulation and processing finished with errorlevel: %ERRORLEVEL% >> ..\log\%filename%.log
::echo Simulation terminated with errorlevel4: %ERRORLEVEL% >> ..\log2\%filename%.log
