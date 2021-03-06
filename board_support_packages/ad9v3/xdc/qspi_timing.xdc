# All the delay numbers have to be provided by the user
# We need to consider the max delay for worst case analysis
set cclk_delay 6.7
# Following are the SPI device parameters, for MT25QL512ABB8E12-0SIT
# Max Tco
set tco_max 6
# Min Tco
set tco_min 1.5
# Setup time requirement
set tsu 1.75
# Hold time requirement
set th 2.3
# Following are the board/trace delay numbers
# Assumption is that all Data lines are matched
set tdata_trace_delay_max 0.25
set tdata_trace_delay_min 0.25
set tclk_trace_delay_max 0.2
set tclk_trace_delay_min 0.2
### End of user provided delay numbers
# This is to ensure min routing delay from SCK generation to STARTUP input
# User should change this value based on the results
# Having more delay on this net reduces the Fmax
# Following constraint should be commented when STARTUP block is disabled

# set_max_delay 1.5 -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO] -datapath_only
# set_min_delay 0.1 -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO]
# set_max_delay 1.5 -from [get_clocks tx_clk_201MHz] -to [get_pins -hier *USRCCLKO] -datapath_only
# set_min_delay 0.1 -from [get_clocks tx_clk_201MHz] -to [get_pins -hier *USRCCLKO]
set_max_delay 1.5 -from [get_clocks clock_afu] -to [get_pins -hier *USRCCLKO] -datapath_only
set_min_delay 0.1 -from [get_clocks clock_afu] -to [get_pins -hier *USRCCLKO]

# Following command creates a divide by 2 clock
# It also takes into account the delay added by STARTUP block to route the CCLK
# This constraint is not needed when STARTUP block is disabled
# Following constraint should be commented when STARTUP block is disabled

# create_generated_clock -name clk_sck -source [get_pins -hierarchical *axi_quad_spi_0/ext_spi_clk] [get_pins -hierarchical *USRCCLKO] -edges {3 5 7} -edge_shift [list $cclk_delay $cclk_delay $cclk_delay]
create_generated_clock -name clk_sck -source [get_pins bsp/FLASH/QSPI/ext_spi_clk] [get_pins -hierarchical *USRCCLKO] -edges {3 5 7} -edge_shift [list $cclk_delay $cclk_delay $cclk_delay]

# Enable following constraint when STARTUP block is disabled
#create_generated_clock -name clk_virt -source [get_pins -hierarchical
#*axi_quad_spi_0/ext_spi_clk] [get_ports <SCK_IO>] -edges {3 5 7}
# Data is captured into FPGA on the second rising edge of ext_spi_clk after the SCK falling edge
# Data is driven by the FPGA on every alternate rising_edge of ext_spi_clk

set_input_delay -clock clk_sck -max [expr $tco_max + $tdata_trace_delay_max + $tclk_trace_delay_max] [get_ports *FPGA_FLASH*] -clock_fall;
set_input_delay -clock clk_sck -min [expr $tco_min + $tdata_trace_delay_min + $tclk_trace_delay_min] [get_ports *FPGA_FLASH*] -clock_fall;
set_multicycle_path 2 -setup     -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]]
set_multicycle_path 1 -hold -end -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]]

# Data is captured into SPI on the following rising edge of SCK
# Data is driven by the IP on alternate rising_edge of the ext_spi_clk

set_output_delay -clock clk_sck -max [expr $tsu + $tdata_trace_delay_max - $tclk_trace_delay_min] [get_ports *FPGA_FLASH*];
set_output_delay -clock clk_sck -min [expr $tdata_trace_delay_min -$th - $tclk_trace_delay_max]   [get_ports *FPGA_FLASH*];
set_multicycle_path 2 -setup -start -from [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] -to clk_sck
set_multicycle_path 1 -hold -from [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] -to clk_sck
