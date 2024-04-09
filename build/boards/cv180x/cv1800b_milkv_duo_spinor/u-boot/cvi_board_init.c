int cvi_board_init(void)
{
	// sensor mclk reset
	PINMUX_CONFIG(PAD_MIPIRX0P, CAM_MCLK0); // Camera MCLK0
	PINMUX_CONFIG(PAD_MIPIRX1N, XGPIOC_8);  // Camera Reset

	// all default gpio
	PINMUX_CONFIG(SD0_PWR_EN, XGPIOA_14);    // Duo Pin 19
	PINMUX_CONFIG(SPK_EN, XGPIOA_15);        // Duo Pin 20
	//PINMUX_CONFIG(SPINOR_MISO, XGPIOA_23);   // Duo Pin 21
	//PINMUX_CONFIG(SPINOR_CS_X, XGPIOA_24);   // Duo Pin 22
	//PINMUX_CONFIG(SPINOR_SCK, XGPIOA_22);    // Duo Pin 24
	//PINMUX_CONFIG(SPINOR_MOSI, XGPIOA_25);   // Duo Pin 25
	//PINMUX_CONFIG(SPINOR_WP_X, XGPIOA_27);   // Duo Pin 26
	//PINMUX_CONFIG(SPINOR_HOLD_X, XGPIOA_26); // Duo Pin 27
	PINMUX_CONFIG(PWR_SEQ2, PWR_GPIO_4);     // Duo Pin 29

	// ADC pins set to gpio
	PINMUX_CONFIG(ADC1, XGPIOB_3);           // ADC1
	PINMUX_CONFIG(USB_VBUS_DET, XGPIOB_6);   // ADC2

	// I2C0
	// PINMUX_CONFIG(IIC0_SCL, IIC0_SCL);
	// PINMUX_CONFIG(IIC0_SDA, IIC0_SDA);

	// I2C1
	PINMUX_CONFIG(PAD_MIPIRX1P, IIC1_SDA);
	PINMUX_CONFIG(PAD_MIPIRX0N, IIC1_SCL);

	// PWM
	PINMUX_CONFIG(SD1_D2, PWM_5);
	PINMUX_CONFIG(SD1_D1, PWM_6);

	// UART 4
	PINMUX_CONFIG(SD1_GPIO1, UART4_TX);
	PINMUX_CONFIG(SD1_GPIO0, UART4_RX);

	// SPI
	PINMUX_CONFIG(SD1_CLK, SPI2_SCK);
	PINMUX_CONFIG(SD1_CMD, SPI2_SDO);
	PINMUX_CONFIG(SD1_D0, SPI2_SDI);
	PINMUX_CONFIG(SD1_D3, SPI2_CS_X);

	return 0;
}
