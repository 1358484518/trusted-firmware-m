/*
 * NS SystemInit for TF-M on STM32H5.
 *
 * SPE already configured SYSCLK (250 MHz PLL) and left USART1 running.
 * The api_ns copy of system_stm32h5xx.c calls SetSysClock() from NS, which
 * retunes PLL1 while it is already on. That glitches the kernel clock and
 * makes the console baud rate unreadable.
 *
 * STM32H5 TF-M also does not implement enable_ns_clk_config(); NS must not
 * program RCC.
 */

#include "stm32h5xx.h"

uint32_t SystemCoreClock = 250000000U;

const uint8_t AHBPrescTable[16] = {
    0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 1U, 2U, 3U, 4U, 6U, 7U, 8U, 9U
};
const uint8_t APBPrescTable[8] = {
    0U, 0U, 0U, 0U, 1U, 2U, 3U, 4U
};

void SystemInit(void)
{
}

void SystemCoreClockUpdate(void)
{
}

uint32_t SECURE_SystemCoreClockUpdate(void)
{
    return SystemCoreClock;
}
