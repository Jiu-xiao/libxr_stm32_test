#include "app_main.h"

#include "libxr.hpp"
#include "main.h"
#include "stm32_adc.hpp"
#include "stm32_can.hpp"
#include "stm32_canfd.hpp"
#include "stm32_gpio.hpp"
#include "stm32_i2c.hpp"
#include "stm32_power.hpp"
#include "stm32_pwm.hpp"
#include "stm32_spi.hpp"
#include "stm32_timebase.hpp"
#include "stm32_uart.hpp"
#include "stm32_usbx.hpp"
#include "flash_map.hpp"

using namespace LibXR;

/* User Code Begin 1 */
/* User Code End 1 */
/* External HAL Declarations */
extern ADC_HandleTypeDef hadc1;
extern ADC_HandleTypeDef hadc3;
extern CAN_HandleTypeDef hcan1;
extern CAN_HandleTypeDef hcan2;
extern I2C_HandleTypeDef hi2c1;
extern I2C_HandleTypeDef hi2c2;
extern I2C_HandleTypeDef hi2c3;
extern SPI_HandleTypeDef hspi1;
extern TIM_HandleTypeDef htim10;
extern TIM_HandleTypeDef htim1;
extern TIM_HandleTypeDef htim2;
extern TIM_HandleTypeDef htim3;
extern TIM_HandleTypeDef htim4;
extern TIM_HandleTypeDef htim5;
extern TIM_HandleTypeDef htim7;
extern TIM_HandleTypeDef htim8;
extern UART_HandleTypeDef huart1;
extern UART_HandleTypeDef huart3;
extern UART_HandleTypeDef huart6;
// extern USBD_HandleTypeDef hUsbDeviceFS;
// extern uint8_t UserRxBufferFS[APP_RX_DATA_SIZE];
// extern uint8_t UserTxBufferFS[APP_TX_DATA_SIZE];

/* DMA Resources */
static uint16_t adc1_buf[64];
static uint16_t adc3_buf[64];
static uint8_t spi1_tx_buf[32];
static uint8_t spi1_rx_buf[32];
static uint8_t usart1_tx_buf[128];
static uint8_t usart1_rx_buf[128];
static uint8_t usart3_rx_buf[128];
static uint8_t usart6_tx_buf[128];
static uint8_t usart6_rx_buf[128];
static uint8_t i2c1_buf[32];
static uint8_t i2c2_buf[32];
static uint8_t i2c3_buf[32];

extern "C" void app_main(void)
{
  /* User Code Begin 2 */

  /* User Code End 2 */
  STM32TimerTimebase timebase(&htim2);
  PlatformInit();
  STM32PowerManager power_manager;

  /* GPIO Configuration */
  STM32GPIO USER_KEY(USER_KEY_GPIO_Port, USER_KEY_Pin, EXTI0_IRQn);
  STM32GPIO ACCL_CS(ACCL_CS_GPIO_Port, ACCL_CS_Pin);
  STM32GPIO GYRO_CS(GYRO_CS_GPIO_Port, GYRO_CS_Pin);
  STM32GPIO HW0(HW0_GPIO_Port, HW0_Pin);
  STM32GPIO HW1(HW1_GPIO_Port, HW1_Pin);
  STM32GPIO HW2(HW2_GPIO_Port, HW2_Pin);
  STM32GPIO ACCL_INT(ACCL_INT_GPIO_Port, ACCL_INT_Pin, EXTI4_IRQn);
  STM32GPIO GYRO_INT(GYRO_INT_GPIO_Port, GYRO_INT_Pin, EXTI9_5_IRQn);
  STM32GPIO CMPS_INT(CMPS_INT_GPIO_Port, CMPS_INT_Pin, EXTI3_IRQn);
  STM32GPIO CMPS_RST(CMPS_RST_GPIO_Port, CMPS_RST_Pin);

  std::array<uint32_t, 2> adc1_channels = {ADC_CHANNEL_TEMPSENSOR, ADC_CHANNEL_VREFINT};
  STM32ADC adc1(&hadc1, adc1_buf, adc1_channels, 3.3);
  auto adc1_adc_channel_tempsensor = adc1.GetChannel(0);
  UNUSED(adc1_adc_channel_tempsensor);
  auto adc1_adc_channel_vrefint = adc1.GetChannel(1);
  UNUSED(adc1_adc_channel_vrefint);

  std::array<uint32_t, 1> adc3_channels = {ADC_CHANNEL_8};
  STM32ADC adc3(&hadc3, adc3_buf, adc3_channels, 3.3);
  auto adc3_adc_channel_8 = adc3.GetChannel(0);
  UNUSED(adc3_adc_channel_8);

  STM32PWM pwm_tim1_ch1(&htim1, TIM_CHANNEL_1);
  STM32PWM pwm_tim1_ch2(&htim1, TIM_CHANNEL_2);
  STM32PWM pwm_tim1_ch3(&htim1, TIM_CHANNEL_3);
  STM32PWM pwm_tim1_ch4(&htim1, TIM_CHANNEL_4);

  STM32PWM pwm_tim10_ch1(&htim10, TIM_CHANNEL_1);

  STM32PWM pwm_tim3_ch3(&htim3, TIM_CHANNEL_3);

  STM32PWM pwm_tim4_ch3(&htim4, TIM_CHANNEL_3);

  STM32PWM pwm_tim5_ch1(&htim5, TIM_CHANNEL_1);
  STM32PWM pwm_tim5_ch2(&htim5, TIM_CHANNEL_2);
  STM32PWM pwm_tim5_ch3(&htim5, TIM_CHANNEL_3);

  STM32PWM pwm_tim8_ch1(&htim8, TIM_CHANNEL_1);
  STM32PWM pwm_tim8_ch2(&htim8, TIM_CHANNEL_2);
  STM32PWM pwm_tim8_ch3(&htim8, TIM_CHANNEL_3);

  STM32SPI spi1(&hspi1, spi1_rx_buf, spi1_tx_buf, 3);

  STM32UART usart1(&huart1,
                   usart1_rx_buf, usart1_tx_buf, 5, 5);

  STM32UART usart3(&huart3,
                   usart3_rx_buf, {nullptr, 0}, 5, 5);

  STM32UART usart6(&huart6,
                   usart6_rx_buf, usart6_tx_buf, 5, 5);

  STM32I2C i2c1(&hi2c1, i2c1_buf, 3);

  STM32I2C i2c2(&hi2c2, i2c2_buf, 3);

  STM32I2C i2c3(&hi2c3, i2c3_buf, 3);

  STM32CAN can1(&hcan1, 5);

  STM32CAN can2(&hcan2, 5);

  STM32VirtualUART uart_cdc(1024, 2, 1024, 2, 5, 15, 256);

  /* User Code Begin 3 */
  STDIO::read_ = &uart_cdc.read_port_;
  STDIO::write_ = &uart_cdc.write_port_;

  LibXR::RamFS ramfs;
  LibXR::Terminal terminal(ramfs);
  auto timer = LibXR::Timer::CreateTask(terminal.TaskFun, &terminal, 10);
  Timer::Add(timer);
  Timer::Start(timer);
  while (true)
  {
    Thread::Sleep(UINT32_MAX);
  }
  /* User Code End 3 */
}