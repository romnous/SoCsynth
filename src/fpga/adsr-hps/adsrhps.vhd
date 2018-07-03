library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity adsrhps is
	port (
		---------fpga connections-------------
		CLOCK_50        : in std_logic;
		CLOCK3_50 : in std_logic;
		SW              : in std_logic_vector(9 downto 0);
		
		KEY             : in std_logic_vector(3 downto 0);
		HEX0 : out std_logic_vector(6 downto 0);
		HEX1 : out std_logic_vector(6 downto 0);
		HEX2 : out std_logic_vector(6 downto 0);
		HEX3 : out std_logic_vector(6 downto 0);
		HEX4 : out std_logic_vector(6 downto 0);
		HEX5 : out std_logic_vector(6 downto 0);
		---------hps connections---------------
		
		        HPS_CONV_USB_N   : inout std_logic;
        HPS_DDR3_ADDR    : out   std_logic_vector(14 downto 0);
        HPS_DDR3_BA      : out   std_logic_vector(2 downto 0);
        HPS_DDR3_CAS_N   : out   std_logic;
        HPS_DDR3_CK_N    : out   std_logic;
        HPS_DDR3_CK_P    : out   std_logic;
        HPS_DDR3_CKE     : out   std_logic;
        HPS_DDR3_CS_N    : out   std_logic;
        HPS_DDR3_DM      : out   std_logic_vector(3 downto 0);
        HPS_DDR3_DQ      : inout std_logic_vector(31 downto 0);
        HPS_DDR3_DQS_N   : inout std_logic_vector(3 downto 0);
        HPS_DDR3_DQS_P   : inout std_logic_vector(3 downto 0);
        HPS_DDR3_ODT     : out   std_logic;
        HPS_DDR3_RAS_N   : out   std_logic;
        HPS_DDR3_RESET_N : out   std_logic;
        HPS_DDR3_RZQ     : in    std_logic;
        HPS_DDR3_WE_N    : out   std_logic;
        HPS_ENET_GTX_CLK : out   std_logic;
        HPS_ENET_INT_N   : inout std_logic;
        HPS_ENET_MDC     : out   std_logic;
        HPS_ENET_MDIO    : inout std_logic;
        HPS_ENET_RX_CLK  : in    std_logic;
        HPS_ENET_RX_DATA : in    std_logic_vector(3 downto 0);
        HPS_ENET_RX_DV   : in    std_logic;
        HPS_ENET_TX_DATA : out   std_logic_vector(3 downto 0);
        HPS_ENET_TX_EN   : out   std_logic;
        HPS_FLASH_DATA   : inout std_logic_vector(3 downto 0);
        HPS_FLASH_DCLK   : out   std_logic;
        HPS_FLASH_NCSO   : out   std_logic;
        HPS_I2C_CONTROL  : inout std_logic;
        HPS_I2C1_SCLK    : inout std_logic;
        HPS_I2C1_SDAT    : inout std_logic;
        HPS_I2C2_SCLK    : inout std_logic;
        HPS_I2C2_SDAT    : inout std_logic;
		   HPS_SD_CLK       : out   std_logic;
        HPS_SD_CMD       : inout std_logic;
			HPS_SD_DATA : inout std_logic_vector(3 downto 0);
        HPS_SPIM_CLK     : out   std_logic;
        HPS_SPIM_MISO    : in    std_logic;
        HPS_SPIM_MOSI    : out   std_logic;
        HPS_SPIM_SS      : inout std_logic;
        HPS_UART_RX      : in    std_logic;
        HPS_UART_TX      : out   std_logic;
        HPS_USB_CLKOUT   : in    std_logic;
        HPS_USB_DATA     : inout std_logic_vector(7 downto 0);
        HPS_USB_DIR      : in    std_logic;
        HPS_USB_NXT      : in    std_logic;
			HPS_USB_STP : out std_logic;

		-- audio
      AUD_ADCDAT       : in    std_logic;
      AUD_ADCLRCK      : inout std_logic;
      AUD_BCLK         : inout std_logic;
      AUD_DACDAT       : out   std_logic;
      AUD_DACLRCK      : inout std_logic;
	   AUD_XCK          : out   std_logic;
		
		audio_input       : in    std_logic_vector(31 downto 0); -- export
		audio_ctrl        : in    std_logic_vector(15 downto 0);

		FPGA_I2C_SDAT : inout std_logic;
		FPGA_I2C_SCLK : out std_logic
 

	);
end adsrhps;

architecture main of adsrhps is
	component soc_system is
		port (
			   avalon_bridge_external_interface_address     : in    std_logic_vector(15 downto 0) := (others => 'X'); -- address
            avalon_bridge_external_interface_byte_enable : in    std_logic_vector(3 downto 0)  := (others => 'X'); -- byte_enable
            avalon_bridge_external_interface_read        : in    std_logic                     := 'X';             -- read
            avalon_bridge_external_interface_write       : in    std_logic                     := 'X';             -- write
            avalon_bridge_external_interface_write_data  : in    std_logic_vector(31 downto 0) := (others => 'X'); -- write_data
            avalon_bridge_external_interface_acknowledge : out   std_logic;                                        -- acknowledge
            avalon_bridge_external_interface_read_data   : out   std_logic_vector(31 downto 0);                    -- read_data
            audio_subsystem_audio_ADCDAT                 : in    std_logic                     := 'X';             -- ADCDAT
            audio_subsystem_audio_ADCLRCK                : in    std_logic                     := 'X';             -- ADCLRCK
            audio_subsystem_audio_BCLK                   : in    std_logic                     := 'X';             -- BCLK
            audio_subsystem_audio_DACDAT                 : out   std_logic;                                        -- DACDAT
            audio_subsystem_audio_DACLRCK                : in    std_logic                     := 'X';             -- DACLRCK
            audio_subsystem_audio_pll_clk_clk            : out   std_logic;                                        -- clk
            audio_subsystem_audio_pll_ref_clk_clk        : in    std_logic                     := 'X';             -- clk
            audio_subsystem_audio_pll_ref_reset_reset    : in    std_logic                     := 'X';             -- reset
            av_config_external_interface_SDAT            : inout std_logic                     := 'X';             -- SDAT
            av_config_external_interface_SCLK            : out   std_logic;                                        -- SCLK
            hex3_hex0_external_connection_export         : out   std_logic_vector(31 downto 0);                    -- export
            hex5_hex4_external_connection_export         : out   std_logic_vector(15 downto 0);                    -- export
            hps_io_hps_io_emac1_inst_TX_CLK              : out   std_logic;                                        -- hps_io_emac1_inst_TX_CLK
            hps_io_hps_io_emac1_inst_TXD0                : out   std_logic;                                        -- hps_io_emac1_inst_TXD0
            hps_io_hps_io_emac1_inst_TXD1                : out   std_logic;                                        -- hps_io_emac1_inst_TXD1
            hps_io_hps_io_emac1_inst_TXD2                : out   std_logic;                                        -- hps_io_emac1_inst_TXD2
            hps_io_hps_io_emac1_inst_TXD3                : out   std_logic;                                        -- hps_io_emac1_inst_TXD3
            hps_io_hps_io_emac1_inst_RXD0                : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD0
            hps_io_hps_io_emac1_inst_MDIO                : inout std_logic                     := 'X';             -- hps_io_emac1_inst_MDIO
            hps_io_hps_io_emac1_inst_MDC                 : out   std_logic;                                        -- hps_io_emac1_inst_MDC
            hps_io_hps_io_emac1_inst_RX_CTL              : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CTL
            hps_io_hps_io_emac1_inst_TX_CTL              : out   std_logic;                                        -- hps_io_emac1_inst_TX_CTL
            hps_io_hps_io_emac1_inst_RX_CLK              : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CLK
            hps_io_hps_io_emac1_inst_RXD1                : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD1
            hps_io_hps_io_emac1_inst_RXD2                : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD2
            hps_io_hps_io_emac1_inst_RXD3                : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD3
            hps_io_hps_io_qspi_inst_IO0                  : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO0
            hps_io_hps_io_qspi_inst_IO1                  : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO1
            hps_io_hps_io_qspi_inst_IO2                  : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO2
            hps_io_hps_io_qspi_inst_IO3                  : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO3
            hps_io_hps_io_qspi_inst_SS0                  : out   std_logic;                                        -- hps_io_qspi_inst_SS0
            hps_io_hps_io_qspi_inst_CLK                  : out   std_logic;                                        -- hps_io_qspi_inst_CLK
            hps_io_hps_io_sdio_inst_CMD                  : inout std_logic                     := 'X';             -- hps_io_sdio_inst_CMD
            hps_io_hps_io_sdio_inst_D0                   : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D0
            hps_io_hps_io_sdio_inst_D1                   : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D1
            hps_io_hps_io_sdio_inst_CLK                  : out   std_logic;                                        -- hps_io_sdio_inst_CLK
            hps_io_hps_io_sdio_inst_D2                   : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D2
            hps_io_hps_io_sdio_inst_D3                   : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D3
            hps_io_hps_io_usb1_inst_D0                   : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D0
            hps_io_hps_io_usb1_inst_D1                   : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D1
            hps_io_hps_io_usb1_inst_D2                   : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D2
            hps_io_hps_io_usb1_inst_D3                   : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D3
            hps_io_hps_io_usb1_inst_D4                   : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D4
            hps_io_hps_io_usb1_inst_D5                   : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D5
            hps_io_hps_io_usb1_inst_D6                   : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D6
            hps_io_hps_io_usb1_inst_D7                   : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D7
            hps_io_hps_io_usb1_inst_CLK                  : in    std_logic                     := 'X';             -- hps_io_usb1_inst_CLK
            hps_io_hps_io_usb1_inst_STP                  : out   std_logic;                                        -- hps_io_usb1_inst_STP
            hps_io_hps_io_usb1_inst_DIR                  : in    std_logic                     := 'X';             -- hps_io_usb1_inst_DIR
            hps_io_hps_io_usb1_inst_NXT                  : in    std_logic                     := 'X';             -- hps_io_usb1_inst_NXT
            hps_io_hps_io_spim1_inst_CLK                 : out   std_logic;                                        -- hps_io_spim1_inst_CLK
            hps_io_hps_io_spim1_inst_MOSI                : out   std_logic;                                        -- hps_io_spim1_inst_MOSI
            hps_io_hps_io_spim1_inst_MISO                : in    std_logic                     := 'X';             -- hps_io_spim1_inst_MISO
            hps_io_hps_io_spim1_inst_SS0                 : out   std_logic;                                        -- hps_io_spim1_inst_SS0
            hps_io_hps_io_uart0_inst_RX                  : in    std_logic                     := 'X';             -- hps_io_uart0_inst_RX
            hps_io_hps_io_uart0_inst_TX                  : out   std_logic;                                        -- hps_io_uart0_inst_TX
            hps_io_hps_io_i2c0_inst_SDA                  : inout std_logic                     := 'X';             -- hps_io_i2c0_inst_SDA
            hps_io_hps_io_i2c0_inst_SCL                  : inout std_logic                     := 'X';             -- hps_io_i2c0_inst_SCL
            hps_io_hps_io_i2c1_inst_SDA                  : inout std_logic                     := 'X';             -- hps_io_i2c1_inst_SDA
            hps_io_hps_io_i2c1_inst_SCL                  : inout std_logic                     := 'X';             -- hps_io_i2c1_inst_SCL
            key_external_connection_export               : in    std_logic_vector(3 downto 0)  := (others => 'X'); -- export
            ledr_external_connection_export              : out   std_logic_vector(9 downto 0);                     -- export
            memory_mem_a                                 : out   std_logic_vector(14 downto 0);                    -- mem_a
            memory_mem_ba                                : out   std_logic_vector(2 downto 0);                     -- mem_ba
            memory_mem_ck                                : out   std_logic;                                        -- mem_ck
            memory_mem_ck_n                              : out   std_logic;                                        -- mem_ck_n
            memory_mem_cke                               : out   std_logic;                                        -- mem_cke
            memory_mem_cs_n                              : out   std_logic;                                        -- mem_cs_n
            memory_mem_ras_n                             : out   std_logic;                                        -- mem_ras_n
            memory_mem_cas_n                             : out   std_logic;                                        -- mem_cas_n
            memory_mem_we_n                              : out   std_logic;                                        -- mem_we_n
            memory_mem_reset_n                           : out   std_logic;                                        -- mem_reset_n
            memory_mem_dq                                : inout std_logic_vector(31 downto 0) := (others => 'X'); -- mem_dq
            memory_mem_dqs                               : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs
            memory_mem_dqs_n                             : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs_n
            memory_mem_odt                               : out   std_logic;                                        -- mem_odt
            memory_mem_dm                                : out   std_logic_vector(3 downto 0);                     -- mem_dm
            memory_oct_rzqin                             : in    std_logic                     := 'X';             -- oct_rzqin
            sw_1_external_connection_export              : in    std_logic_vector(9 downto 0)  := (others => 'X'); -- export
            system_pll_ref_clk_clk                       : in    std_logic                     := 'X';             -- clk
            system_pll_ref_reset_reset                   : in    std_logic                     := 'X';             -- reset
            system_pll_sdram_clk_clk                     : out   std_logic;                                        -- clk
            audio_input_external_connection_export       : in    std_logic_vector(31 downto 0) := (others => 'X'); -- export
            audio_ctrl_external_connection_export        : in    std_logic_vector(15 downto 0) := (others => 'X')  -- export
			);
		end component soc_system;
		--signal hps_h2f_rst : std_logic;
		signal bus_addr : std_logic_vector(15 downto 0);
		signal bus_byte_enable  : std_logic_vector(3 downto 0);
		signal bus_read  : std_logic;
		signal bus_write  : std_logic;
		signal bus_ack  : std_logic;
		signal bus_write_data : std_logic_vector(31 downto 0);
		signal bus_read_data : std_logic_vector(31 downto 0);
		signal ledr            : std_logic_vector(9 downto 0);
		signal state_clock : std_logic;
		signal hex3_hex0_control : std_logic_vector(31 downto 0);
		signal hex5_hex4_control : std_logic_vector(15 downto 0);
	begin
		u0 : component soc_system
		port map(
			av_config_external_interface_SDAT         => FPGA_I2C_SDAT, -- av_config_external_interface.SDAT
			av_config_external_interface_SCLK         => FPGA_I2C_SCLK, -- .SCLK
			hex3_hex0_external_connection_export      => hex3_hex0_control, -- hex3_hex0_external_connection.export
			hex5_hex4_external_connection_export      => hex5_hex4_control, -- hex5_hex4_external_connection.export
			key_external_connection_export            => KEY, -- key_external_connection.export
			ledr_external_connection_export           => ledr, -- ledr_external_connection.export
			memory_mem_a                              => HPS_DDR3_ADDR, -- memory.mem_a
			memory_mem_ba                             => HPS_DDR3_BA, -- .mem_ba
			memory_mem_ck                             => HPS_DDR3_CK_P, -- .mem_ck
			memory_mem_ck_n                           => HPS_DDR3_CK_N, -- .mem_ck_n
			memory_mem_cke                            => HPS_DDR3_CKE, -- .mem_cke
			memory_mem_cs_n                           => HPS_DDR3_CS_N, -- .mem_cs_n
			memory_mem_ras_n                          => HPS_DDR3_RAS_N, -- .mem_ras_n
			memory_mem_cas_n                          => HPS_DDR3_CAS_N, -- .mem_cas_n
			memory_mem_we_n                           => HPS_DDR3_WE_N, -- .mem_we_n
			memory_mem_reset_n                        => HPS_DDR3_RESET_N, -- .mem_reset_n
			memory_mem_dq                             => HPS_DDR3_DQ, -- .mem_dq
			memory_mem_dqs                            => HPS_DDR3_DQS_P, -- .mem_dqs
			memory_mem_dqs_n                          => HPS_DDR3_DQS_N, -- .mem_dqs_n
			memory_mem_odt                            => HPS_DDR3_ODT, -- .mem_odt
			memory_mem_dm                             => HPS_DDR3_DM, -- .mem_dm
			memory_oct_rzqin                          => HPS_DDR3_RZQ, -- .oct_rzqin
			sw_1_external_connection_export           => SW, -- sw_1_external_connection.export
			system_pll_ref_clk_clk                    => CLOCK_50, -- system_pll_ref_clk.clk
			system_pll_ref_reset_reset                => '0', -- system_pll_ref_reset.reset
			system_pll_sdram_clk_clk                  => state_clock, -- system_pll_sdram_clk.clk
			audio_subsystem_audio_pll_ref_clk_clk     => CLOCK3_50, -- audio_subsystem_audio_pll_ref_clk.clk
			audio_subsystem_audio_pll_ref_reset_reset => '0', -- audio_subsystem_audio_pll_ref_reset.reset
			audio_subsystem_audio_pll_clk_clk         => AUD_XCK, -- audio_subsystem_audio_pll_clk.clk
			audio_subsystem_audio_ADCDAT              => AUD_ADCDAT, -- audio_subsystem_audio.ADCDAT
			audio_subsystem_audio_ADCLRCK             => AUD_ADCLRCK, -- .ADCLRCK
			audio_subsystem_audio_BCLK                => AUD_BCLK, -- .BCLK
			audio_subsystem_audio_DACDAT              => AUD_DACDAT, -- .DACDAT
			audio_subsystem_audio_DACLRCK             => AUD_DACLRCK, -- .DACLRCK
			avalon_bridge_external_interface_address          => bus_addr,          --            audio_external_interface.address
			avalon_bridge_external_interface_byte_enable      => bus_byte_enable,      --                                    .byte_enable
			avalon_bridge_external_interface_read             => bus_read,             --                                    .read
			avalon_bridge_external_interface_write            => bus_write,            --                                    .write
			avalon_bridge_external_interface_write_data       => bus_write_data,       --                                    .write_data
			avalon_bridge_external_interface_acknowledge      => bus_ack,      --                                    .acknowledge
			avalon_bridge_external_interface_read_data        => bus_read_data,         --                                    .read_data
			audio_input_external_connection_export       => audio_input,       --     audio_input_external_connection.export
			audio_ctrl_external_connection_export        => audio_ctrl,         --      audio_ctrl_external_connection.export
			hps_io_hps_io_emac1_inst_tx_clk           => HPS_ENET_gtx_clk, -- hps_io.hps_io_emac1_inst_tx_clk
			hps_io_hps_io_emac1_inst_txd0             => HPS_ENET_TX_DATA(0), -- .hps_io_emac1_inst_txd0
			hps_io_hps_io_emac1_inst_txd1             => HPS_ENET_TX_DATA(1), -- .hps_io_emac1_inst_txd1
			hps_io_hps_io_emac1_inst_txd2             => HPS_ENET_TX_DATA(2), -- .hps_io_emac1_inst_txd2
			hps_io_hps_io_emac1_inst_txd3             => HPS_ENET_TX_DATA(3), -- .hps_io_emac1_inst_txd3
			hps_io_hps_io_emac1_inst_rxd0             => HPS_ENET_RX_DATA(0), -- .hps_io_emac1_inst_rxd0
			hps_io_hps_io_emac1_inst_mdio             => HPS_ENET_MDIO, -- .hps_io_emac1_inst_mdio
			hps_io_hps_io_emac1_inst_mdc              => HPS_ENET_MDC, -- .hps_io_emac1_inst_mdc
			hps_io_hps_io_emac1_inst_rx_ctl           => HPS_ENET_RX_DV, -- .hps_io_emac1_inst_rx_ctl
			hps_io_hps_io_emac1_inst_tx_ctl           => HPS_ENET_TX_EN, -- .hps_io_emac1_inst_tx_ctl
			hps_io_hps_io_emac1_inst_rx_clk           => HPS_ENET_RX_CLK, -- .hps_io_emac1_inst_rx_clk
			hps_io_hps_io_emac1_inst_rxd1             => HPS_ENET_RX_DATA(1), -- .hps_io_emac1_inst_rxd1
			hps_io_hps_io_emac1_inst_rxd2             => HPS_ENET_RX_DATA(2), -- .hps_io_emac1_inst_rxd2
			hps_io_hps_io_emac1_inst_rxd3             => HPS_ENET_RX_DATA(3), -- .hps_io_emac1_inst_rxd3
			hps_io_hps_io_sdio_inst_cmd               => HPS_SD_CMD, -- .hps_io_sdio_inst_cmd
			hps_io_hps_io_sdio_inst_d0                => HPS_SD_DATA(0), -- .hps_io_sdio_inst_d0
			hps_io_hps_io_sdio_inst_d1                => HPS_SD_DATA(1), -- .hps_io_sdio_inst_d1
			hps_io_hps_io_sdio_inst_clk               => HPS_SD_CLK, -- .hps_io_sdio_inst_clk
			hps_io_hps_io_sdio_inst_d2                => HPS_SD_DATA(2), -- .hps_io_sdio_inst_d2
			hps_io_hps_io_sdio_inst_d3                => HPS_SD_DATA(3), -- .hps_io_sdio_inst_d3
			hps_io_hps_io_usb1_inst_d0                => HPS_USB_DATA(0), -- .hps_io_usb1_inst_d0
			hps_io_hps_io_usb1_inst_d1                => HPS_USB_DATA(1), -- .hps_io_usb1_inst_d1
			hps_io_hps_io_usb1_inst_d2                => HPS_USB_DATA(2), -- .hps_io_usb1_inst_d2
			hps_io_hps_io_usb1_inst_d3                => HPS_USB_DATA(3), -- .hps_io_usb1_inst_d3
			hps_io_hps_io_usb1_inst_d4                => HPS_USB_DATA(4), -- .hps_io_usb1_inst_d4
			hps_io_hps_io_usb1_inst_d5                => HPS_USB_DATA(5), -- .hps_io_usb1_inst_d5
			hps_io_hps_io_usb1_inst_d6                => HPS_USB_DATA(6), -- .hps_io_usb1_inst_d6
			hps_io_hps_io_usb1_inst_d7                => HPS_USB_DATA(7), -- .hps_io_usb1_inst_d7
			hps_io_hps_io_usb1_inst_clk               => HPS_USB_CLKOUT, -- .hps_io_usb1_inst_clk
			hps_io_hps_io_usb1_inst_stp               => HPS_USB_STP, -- .hps_io_usb1_inst_stp
			hps_io_hps_io_usb1_inst_dir               => HPS_USB_DIR, -- .hps_io_usb1_inst_dir
			hps_io_hps_io_usb1_inst_nxt               => HPS_USB_NXT, -- .hps_io_usb1_inst_nxt
			hps_io_hps_io_uart0_inst_rx               => HPS_UART_RX, -- .hps_io_uart0_inst_rx
			hps_io_hps_io_uart0_inst_tx               => HPS_UART_TX, -- .hps_io_uart0_inst_tx 
			hps_io_hps_io_qspi_inst_IO0               => HPS_FLASH_DATA(0), -- .hps_io_qspi_inst_IO0
			hps_io_hps_io_qspi_inst_IO1               => HPS_FLASH_DATA(1), -- .hps_io_qspi_inst_IO1
			hps_io_hps_io_qspi_inst_IO2               => HPS_FLASH_DATA(2), -- .hps_io_qspi_inst_IO2
			hps_io_hps_io_qspi_inst_IO3               => HPS_FLASH_DATA(3), -- .hps_io_qspi_inst_IO3
			hps_io_hps_io_qspi_inst_SS0               => HPS_FLASH_NCSO, -- .hps_io_qspi_inst_SS0
			hps_io_hps_io_qspi_inst_CLK               => HPS_FLASH_DCLK, -- .hps_io_qspi_inst_CLK
			hps_io_hps_io_spim1_inst_CLK              => HPS_SPIM_CLK, -- .hps_io_spim1_inst_CLK
			hps_io_hps_io_spim1_inst_MOSI             => HPS_SPIM_MOSI, -- .hps_io_spim1_inst_MOSI
			hps_io_hps_io_spim1_inst_MISO             => HPS_SPIM_MISO, -- .hps_io_spim1_inst_MISO
			hps_io_hps_io_spim1_inst_SS0              => HPS_SPIM_SS, -- .hps_io_spim1_inst_SS0
			hps_io_hps_io_i2c0_inst_SDA               => HPS_I2C1_SDAT, -- .hps_io_i2c0_inst_SDA
			hps_io_hps_io_i2c0_inst_SCL               => HPS_I2C1_SCLK, -- .hps_io_i2c0_inst_SCL
			hps_io_hps_io_i2c1_inst_SDA               => HPS_I2C2_SDAT, -- .hps_io_i2c1_inst_SDA
			hps_io_hps_io_i2c1_inst_SCL               => HPS_I2C2_SCLK -- .hps_io_i2c1_inst_SCL
		);
		
process(clock_50)
begin
	ledr <= audio_input(9 downto 0);
	HEX0 <= hex3_hex0_control(6 downto 0);
	HEX1 <= hex3_hex0_control(14 downto 8);
	HEX2 <= hex3_hex0_control(22 downto 16);
	HEX3 <= hex3_hex0_control(30 downto 24);
	HEX4 <= hex5_hex4_control(6 downto 0);
	HEX5 <= hex5_hex4_control(14 downto 8);
end process;
end main;