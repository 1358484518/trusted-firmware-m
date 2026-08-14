/*
 * NS SystemInit for TF-M on STM32H5.
 *
 * Matches SPE platform/ext/target/stm/common/stm32h5xx/secure/system_stm32h5xx.c:
 * SPE already configured the 250 MHz PLL. The api_ns Templates copy of
 * system_stm32h5xx.c calls SetSysClock() from NS, which retunes PLL1 while it
 * is already on and makes USART1 baud unreadable after the secure tests.
 *
 * Keep tf-m-tests bring-up (stdio_init / uart_stdout). Do not retune RCC.
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
