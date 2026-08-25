@echo off
rem Tiny J-Link smoke test. Save to Desktop, double-click.
rem If this works, CubeProgrammer CLI can talk to your J-Link.
echo ============================================================
echo  J-Link smoke test   file: %~f0
echo ============================================================
set "PATH=D:\ST\STM32CubeProgrammer\bin;%PATH%"
for /d %%D in ("%ProgramFiles%\SEGGER\JLink*") do (
    if exist "%%~D\JLinkARM.dll" set "PATH=%%~D;%PATH%"
)
echo CMD: STM32_Programmer_CLI -c port=JLINK ap=1 mode=UR
echo.
STM32_Programmer_CLI -c port=JLINK ap=1 mode=UR
echo.
echo If you saw "Connecting to J-Link Probe", CLI J-Link works.
echo If "Library not found", copy JLinkARM.dll into:
echo   D:\ST\STM32CubeProgrammer\bin\
pause
