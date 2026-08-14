/*
 * NS stdout: reuse USART1 as SPE left it (115200 8N1 on ST-Link VCP).
 *
 * Do not call HAL_UART_Init() / stdio_init(). Recomputing BRR from NS often
 * uses the wrong kernel-clock guess (SystemCoreClock defaults to 64 MHz,
 * and some RCC PLL registers are secure-only), which overwrites the working
 * SPE baud rate and prints garbage after "*** End of Secure test suites ***".
 */

#include <stdint.h>
#include "stm32h5xx.h"

int _write(int fd, char *str, int len)
{
    int i;

    (void)fd;

    if ((str == NULL) || (len <= 0)) {
        return 0;
    }

    /* SPE enables USART1 before jumping to NS. If it is off, stay silent. */
    if ((USART1->CR1 & USART_CR1_UE) == 0U) {
        return 0;
    }

    for (i = 0; i < len; i++) {
        while ((USART1->ISR & USART_ISR_TXE_TXFNF) == 0U) {
        }
        USART1->TDR = (uint8_t)str[i];
    }

    return len;
}
