@echo off
rem ****************************************************************************
rem  * STM32H573I-DK TF-M flash after regression (Windows)
rem  *
rem  * 1) Run regression.bat (option bytes + erase + OEM-iRoT)
rem  * 2) If present in current dir (or this script's dir), download:
rem  *      bl2.hex                 Intel HEX, address inside the file
rem  *      tfm_s_ns_signed.hex     Intel HEX, S+NS concatenated (S slot)
rem  *      tfm_ns_signed.bin       binary at 0x0C088000 (NS primary)
rem  *
rem  * Usage:
rem  *   tfm_update.bat                  auto-detect (J-Link if listed, else ST-LINK)
rem  *   tfm_update.bat <SN>
rem  *   tfm_update.bat jlink [SN]
rem  *   tfm_update.bat stlink [SN]
rem  *
rem  * SPDX-License-Identifier: BSD-3-Clause
rem  ****************************************************************************
setlocal EnableExtensions

set "EXIT_CODE=0"
set "FAILED_STEP="
set "FLASHED=0"
set "PROBE=stlink"
set "PORT=SWD"
set "SN_ARG="
set "PROBE_FORCED=0"

if /i "%~1"=="jlink" (
    set "PROBE=jlink"
    set "PORT=JLINK"
    set "PROBE_FORCED=1"
    if not "%~2"=="" set "SN_ARG=%~2"
) else if /i "%~1"=="stlink" (
    set "PROBE=stlink"
    set "PORT=SWD"
    set "PROBE_FORCED=1"
    if not "%~2"=="" set "SN_ARG=%~2"
) else if /i "%~1"=="-h" (
    goto :usage
) else if /i "%~1"=="/?" (
    goto :usage
) else if not "%~1"=="" (
    set "SN_ARG=%~1"
)

set "sn_option="
if defined SN_ARG set "sn_option=sn=%SN_ARG%"

rem H573 flash map (secure alias 0x0C00_0000)
set "ADDR_BL2=0x0C00E000"
set "ADDR_S=0x0C038000"
set "ADDR_NS=0x0C088000"

echo.
echo ============================================================
echo  STM32H573I-DK  TF-M UPDATE
echo  cwd: %CD%
echo ============================================================
echo.

if not exist "%~dp0regression.bat" (
    echo [FAIL] regression.bat not found next to this script
    set "FAILED_STEP=locate regression.bat"
    set "EXIT_CODE=1"
    goto :finish
)

echo [1] Locate STM32_Programmer_CLI
set "CUBEPROG="
if exist "%ProgramFiles%\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe" (
    set "CUBEPROG=%ProgramFiles%\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin"
)
if not defined CUBEPROG if exist "%ProgramFiles(x86)%\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe" (
    set "CUBEPROG=%ProgramFiles(x86)%\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin"
)
if defined CUBEPROG set "PATH=%CUBEPROG%;%PATH%"
where STM32_Programmer_CLI >nul 2>&1
if errorlevel 1 (
    echo [FAIL] STM32_Programmer_CLI not found
    set "FAILED_STEP=locate STM32_Programmer_CLI"
    set "EXIT_CODE=1"
    goto :finish
)
echo [ok]   STM32_Programmer_CLI ready
call :detect_probe
echo [info] using probe=%PROBE%  port=%PORT%
echo.

echo [2] Run regression.bat
echo ------------------------------------------------------------
set "TFM_SKIP_PAUSE=1"
if "%PROBE_FORCED%"=="1" (
    if defined SN_ARG (
        call "%~dp0regression.bat" %PROBE% %SN_ARG%
    ) else (
        call "%~dp0regression.bat" %PROBE%
    )
) else (
    if defined SN_ARG (
        call "%~dp0regression.bat" %SN_ARG%
    ) else (
        call "%~dp0regression.bat"
    )
)
set "TFM_SKIP_PAUSE="
if errorlevel 1 (
    echo.
    echo [FAIL] regression.bat failed, skip download
    set "FAILED_STEP=regression.bat"
    set "EXIT_CODE=1"
    goto :finish
)
echo [ok]   regression finished
echo.

set "connect=-c port=%PORT% ap=1 %sn_option% mode=UR"

echo [3] Scan images in current directory
set "FOUND_ANY=0"
call :find_file bl2.hex
if not errorlevel 1 (
    echo        FOUND  bl2.hex                 -^> BL2  %ADDR_BL2%  ^(hex uses file addresses^)
    set "FOUND_ANY=1"
) else (
    echo        skip   bl2.hex                 not found
)
call :find_file tfm_s_ns_signed.hex
if not errorlevel 1 (
    echo        FOUND  tfm_s_ns_signed.hex     -^> S+NS %ADDR_S%    ^(hex uses file addresses^)
    set "FOUND_ANY=1"
) else (
    echo        skip   tfm_s_ns_signed.hex     not found
)
call :find_file tfm_ns_signed.bin
if not errorlevel 1 (
    echo        FOUND  tfm_ns_signed.bin       -^> NS   %ADDR_NS%
    set "FOUND_ANY=1"
) else (
    echo        skip   tfm_ns_signed.bin       not found
)
echo.

if "%FOUND_ANY%"=="0" (
    echo [FAIL] no bl2.hex / tfm_s_ns_signed.hex / tfm_ns_signed.bin in:
    echo        %CD%
    echo        %~dp0
    set "FAILED_STEP=no image files"
    set "EXIT_CODE=1"
    goto :finish
)

echo [4] Download images that exist
echo.

call :find_file tfm_s_ns_signed.hex
if not errorlevel 1 (
    call :flash_hex tfm_s_ns_signed.hex "%FILE%" "S+NS signed"
    if errorlevel 1 goto :finish
)

call :find_file tfm_ns_signed.bin
if not errorlevel 1 (
    call :flash_bin tfm_ns_signed.bin "%FILE%" %ADDR_NS% "NS signed"
    if errorlevel 1 goto :finish
)

call :find_file bl2.hex
if not errorlevel 1 (
    call :flash_hex bl2.hex "%FILE%" "BL2"
    if errorlevel 1 goto :finish
)

echo [5] Reset MCU
echo ------------------------------------------------------------
echo CMD: STM32_Programmer_CLI %connect% -hardRst
echo ------------------------------------------------------------
STM32_Programmer_CLI %connect% -hardRst
if errorlevel 1 (
    echo [FAIL] reset failed
    set "FAILED_STEP=hardRst"
    set "EXIT_CODE=1"
    goto :finish
)
echo [ok]   reset done
echo.

echo ============================================================
echo  ALL STEPS OK  ^(%FLASHED% file(s) downloaded^)  probe=%PROBE%
echo ============================================================
goto :finish

:usage
echo Usage:
echo   tfm_update.bat
echo   tfm_update.bat ^<SN^>
echo   tfm_update.bat jlink [SN]
echo   tfm_update.bat stlink [SN]
echo.
echo With no probe name, J-Link is used if CubeProgrammer lists one.
pause
exit /b 0

:detect_probe
if "%PROBE_FORCED%"=="1" (
    echo [info] probe forced: %PROBE%
    exit /b 0
)
echo [info] Auto-detect probe ^(J-Link if listed, else ST-LINK^)
set "JL_LIST=%TEMP%\tfm_jlink_list.txt"
STM32_Programmer_CLI -l jlink > "%JL_LIST%" 2>&1
findstr /i /c:"JLINK Probe" /c:"J-Link Probe" /c:"JLink Probe" "%JL_LIST%" >nul
if not errorlevel 1 (
    set "PROBE=jlink"
    set "PORT=JLINK"
    echo [ok]   J-Link listed, using port=JLINK
    exit /b 0
)
set "PROBE=stlink"
set "PORT=SWD"
echo [info] No J-Link listed, using ST-LINK port=SWD
echo        Force with:  tfm_update.bat jlink   or   tfm_update.bat stlink
exit /b 0

:find_file
set "FILE="
if exist "%CD%\%~1" (
    set "FILE=%CD%\%~1"
    exit /b 0
)
if exist "%~dp0%~1" (
    set "FILE=%~dp0%~1"
    exit /b 0
)
exit /b 1

:flash_hex
set "STEP_NAME=%~1"
set "STEP_PATH=%~2"
set "STEP_DESC=%~3"
echo ------------------------------------------------------------
echo DOWNLOAD  %STEP_DESC%  [%STEP_NAME%]
echo FILE: %STEP_PATH%
echo CMD:  STM32_Programmer_CLI %connect% -d "%STEP_PATH%" -v
echo ------------------------------------------------------------
STM32_Programmer_CLI %connect% -d "%STEP_PATH%" -v
if errorlevel 1 (
    echo [FAIL] download %STEP_NAME%
    set "FAILED_STEP=download %STEP_NAME%"
    set "EXIT_CODE=1"
    exit /b 1
)
echo [ok]   %STEP_NAME% downloaded
echo.
set /a FLASHED+=1
exit /b 0

:flash_bin
set "STEP_NAME=%~1"
set "STEP_PATH=%~2"
set "STEP_ADDR=%~3"
set "STEP_DESC=%~4"
echo ------------------------------------------------------------
echo DOWNLOAD  %STEP_DESC%  [%STEP_NAME%]
echo FILE: %STEP_PATH%
echo ADDR: %STEP_ADDR%
echo CMD:  STM32_Programmer_CLI %connect% -d "%STEP_PATH%" %STEP_ADDR% -v
echo ------------------------------------------------------------
STM32_Programmer_CLI %connect% -d "%STEP_PATH%" %STEP_ADDR% -v
if errorlevel 1 (
    echo [FAIL] download %STEP_NAME%
    set "FAILED_STEP=download %STEP_NAME%"
    set "EXIT_CODE=1"
    exit /b 1
)
echo [ok]   %STEP_NAME% downloaded @ %STEP_ADDR%
echo.
set /a FLASHED+=1
exit /b 0

:finish
echo.
if not "%EXIT_CODE%"=="0" (
    echo ============================================================
    echo  FAILED at: %FAILED_STEP%
    echo  Window stays open so you can read the log above.
    echo ============================================================
) else (
    echo Window stays open. Press any key to close.
)
echo.
pause
endlocal & exit /b %EXIT_CODE%
