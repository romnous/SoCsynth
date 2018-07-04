# Clock constraints

create_clock -period 20 [get_ports CLOCK_50]
create_clock -period 20 [get_ports CLOCK2_50]
create_clock -period 20 [get_ports CLOCK3_50]
create_clock -period 20 [get_ports CLOCK4_50]

#create_clock -period "18.432 MHz" -name clk_audxck [get_ports AUD_XCK]
#create_clock -period "1.536 MHz" -name clk_audbck [get_ports AUD_BCLK]


# Automatically constrain PLL and other generated clocks
derive_pll_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty