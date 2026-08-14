/*
 * Copyright (c) 2013-2024, Arm Limited. All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Same CMSIS USART driver as api_ns platform_ns / tf-m-tests, except:
 * if SPE already enabled USART1, do not call HAL_UART_Init() (that rewrites
 * BRR from an NS clock guess and garbles 115200 after the secure tests).
 */

#include "Driver_USART.h"

#include "tfm_hal_device_header.h"
#include "stm32hal.h"
#include "board.h"
#ifndef ARG_UNUSED
#define ARG_UNUSED(arg)  (void)arg
#endif /* ARG_UNUSED */
#define USART_DRV_VERSION  ARM_DRIVER_VERSION_MAJOR_MINOR(2, 2)

static const ARM_DRIVER_VERSION DriverVersion =
{
  ARM_USART_API_VERSION,
  USART_DRV_VERSION
};

static const ARM_USART_CAPABILITIES DriverCapabilities =
{
  1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

static ARM_DRIVER_VERSION USART_GetVersion(void)
{
  return DriverVersion;
}

static ARM_USART_CAPABILITIES USART_GetCapabilities(void)
{
  return DriverCapabilities;
}

static UART_HandleTypeDef uart_device;

static void uart_handle_bind(void)
{
  uart_device.Instance = COM_INSTANCE;
  uart_device.Init.BaudRate       = 115200;
  uart_device.Init.WordLength     = UART_WORDLENGTH_8B;
  uart_device.Init.StopBits       = UART_STOPBITS_1;
  uart_device.Init.Parity         = UART_PARITY_NONE;
  uart_device.Init.Mode           = UART_MODE_TX_RX;
  uart_device.Init.HwFlowCtl      = UART_HWCONTROL_NONE;
  uart_device.Init.OverSampling   = UART_OVERSAMPLING_8;
  uart_device.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
  uart_device.Init.ClockPrescaler = UART_PRESCALER_DIV1;
  uart_device.gState = HAL_UART_STATE_READY;
  uart_device.RxState = HAL_UART_STATE_READY;
  uart_device.ErrorCode = HAL_UART_ERROR_NONE;
}

static int32_t USART0_Initialize(ARM_USART_SignalEvent_t cb_event)
{
  ARG_UNUSED(cb_event);

  uart_handle_bind();

  /* SPE left USART1 running at 115200. Keep that BRR. */
  if ((COM_INSTANCE->CR1 & USART_CR1_UE) != 0U) {
    return ARM_DRIVER_OK;
  }

  if (HAL_UART_Init(&uart_device) != HAL_OK) {
    return ARM_DRIVER_ERROR;
  }
  return ARM_DRIVER_OK;
}

static int32_t USART0_Uninitialize(void)
{
  return ARM_DRIVER_OK;
}

static int32_t USART0_PowerControl(ARM_POWER_STATE state)
{
  ARG_UNUSED(state);
  return ARM_DRIVER_OK;
}

static int32_t USART0_Send(const void *data, uint32_t num)
{
  if ((data == NULL) || (num == 0U)) {
    return ARM_DRIVER_ERROR_PARAMETER;
  }
  HAL_UART_Transmit(&uart_device, (uint8_t *)data, num, 1000);
  return ARM_DRIVER_OK;
}

static int32_t USART0_Receive(void *data, uint32_t num)
{
  if ((data == NULL) || (num == 0U)) {
    return ARM_DRIVER_ERROR_PARAMETER;
  }
  HAL_UART_Receive_IT(&uart_device, data, num);
  return (int32_t)num;
}

static int32_t USART0_Transfer(const void *data_out, void *data_in, uint32_t num)
{
  ARG_UNUSED(data_out);
  ARG_UNUSED(data_in);
  ARG_UNUSED(num);
  return ARM_DRIVER_ERROR_UNSUPPORTED;
}

static uint32_t USART0_GetTxCount(void)
{
  return 0;
}

static uint32_t USART0_GetRxCount(void)
{
  return 0;
}

static int32_t USART0_Control(uint32_t control, uint32_t arg)
{
  ARG_UNUSED(control);
  ARG_UNUSED(arg);
  return ARM_DRIVER_OK;
}

static ARM_USART_STATUS USART0_GetStatus(void)
{
  ARM_USART_STATUS status = {0, 0, 0, 0, 0, 0, 0, 0};
  return status;
}

static int32_t USART0_SetModemControl(ARM_USART_MODEM_CONTROL control)
{
  ARG_UNUSED(control);
  return ARM_DRIVER_ERROR_UNSUPPORTED;
}

static ARM_USART_MODEM_STATUS USART0_GetModemStatus(void)
{
  ARM_USART_MODEM_STATUS modem_status = {0, 0, 0, 0, 0};
  return modem_status;
}

ARM_DRIVER_USART Driver_USART0 =
{
  USART_GetVersion,
  USART_GetCapabilities,
  USART0_Initialize,
  USART0_Uninitialize,
  USART0_PowerControl,
  USART0_Send,
  USART0_Receive,
  USART0_Transfer,
  USART0_GetTxCount,
  USART0_GetRxCount,
  USART0_Control,
  USART0_GetStatus,
  USART0_SetModemControl,
  USART0_GetModemStatus
};
