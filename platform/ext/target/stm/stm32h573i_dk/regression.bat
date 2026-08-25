@echo off
rem ****************************************************************************
rem  * STM32H573I-DK TF-M option-byte regression (Windows)
rem  * Same steps as regression.sh: PRODUCT_STATE / TZEN, wipe protections,
rem  * erase flash, restore default secure option bytes.
rem  *
rem  * Usage:
rem  *   regression.bat              connect the first ST-LINK
rem  *   regression.bat <SN>         connect a specific probe (STM32_Programmer_CLI sn=)
rem  *
rem  * Requires STM32CubeProgrammer. Typical path:
rem  *   C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin
rem  *
rem  * SPDX-License-Identifier: BSD-3-Clause
rem  ****************************************************************************
setlocal EnableExtensions

echo regression script started

set "sn_option="
if not "%~1"=="" set "sn_option=sn=%~1"

rem Prefer PATH, then the default CubeProgrammer install locations
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
    echo ERROR: STM32_Programmer_CLI not found.
    echo Install STM32CubeProgrammer, or add its bin directory to PATH.
    exit /b 1
)

set "connect=-c port=SWD ap=1 %sn_option% mode=UR"
set "connect_no_reset=-c port=SWD ap=1 %sn_option% mode=HotPlug"

set "product_state=-ob PRODUCT_STATE=0xED TZEN=0xB4"
set "remove_bank1_protect=-ob SECWM1_STRT=127 SECWM1_END=0 WRPSGn1=0xffffffff"
set "remove_bank2_protect=-ob SECWM2_STRT=127 SECWM2_END=0 WRPSGn2=0xffffffff"
set "erase_all=-e all"
set "remove_hdp_protection=-ob HDP1_END=0 HDP2_END=0"
set "default_ob1=-ob SECBOOTADD=0xC0100 HDP1_STRT=1 HDP1_END=0 HDP2_STRT=1 HDP2_END=0 SWAP_BANK=0 SRAM2_RST=0 SRAM2_ECC=0"
set "default_ob2=-ob SECWM2_STRT=0 SECWM2_END=127 SECWM1_STRT=0 SECWM1_END=127"

echo Regression to PRODUCT_STATE 0xED and tzen=1
call :run_cli %connect% %product_state%
if errorlevel 1 exit /b 1

echo Remove bank1 protection and erase all
call :run_cli %connect% %remove_bank1_protect% %erase_all%
if errorlevel 1 exit /b 1

echo Remove bank2 protection and erase all
call :run_cli %connect% %remove_bank2_protect% %erase_all%
if errorlevel 1 exit /b 1

echo Remove hdp protection
call :run_cli %connect_no_reset% %remove_hdp_protection%
if errorlevel 1 exit /b 1

echo Set default OB 1 ^(dual bank, swap bank, sram2 reset, secure entry point, bank 1 full secure^)
call :run_cli %connect_no_reset% %default_ob1%
if errorlevel 1 exit /b 1

echo Set default OB 2 ^(bank 2 full secure^)
call :run_cli %connect_no_reset% %default_ob2%
if errorlevel 1 exit /b 1

echo regression script Done
exit /b 0

:run_cli
STM32_Programmer_CLI %*
if errorlevel 1 (
    echo ERROR: STM32_Programmer_CLI failed
    exit /b 1
)
exit /b 0
