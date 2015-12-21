
##--------------------------------------------------------------
# IMPORTANT: Set AD7616 operation and interface mode
#
#    ad7616_opm - Defines the operation mode (software OR hardware)
#    ad7616_if  - Defines the interface type (serial OR parallel)
#
# LEGEND: Software  - 0
#         Hardware  - 1
#         Serial    - 0
#         Parallel  - 1
#
# NOTE : These switches are 'hardware' switches. User needs to
# reimplement the design each and every time, after these variables
# were changed.

set ad7616_opm  0
set ad7616_if   0

##--------------------------------------------------------------

# data interfaces

create_bd_port -dir O sclk
create_bd_port -dir O sdo
create_bd_port -dir I sdi_0
create_bd_port -dir I sdi_1

create_bd_port -dir O -from 15 -to 0 db_o
create_bd_port -dir I -from 15 -to 0 db_i
create_bd_port -dir O rd_n
create_bd_port -dir O wr_n

# control lines

create_bd_port -dir O reset_n
create_bd_port -dir O cnvst
create_bd_port -dir O cs_n
create_bd_port -dir I busy
create_bd_port -dir O seq_en
create_bd_port -dir O -from 1 -to 0 hw_rngsel
create_bd_port -dir O -from 2 -to 0 chsel
create_bd_port -dir O crcen
create_bd_port -dir O burst
create_bd_port -dir O -from 2 -to 0 os

# instantiation

set axi_ad7616 [create_bd_cell -type ip -vlnv analog.com:user:axi_ad7616:1.0 axi_ad7616]
set_property -dict [list CONFIG.OP_MODE $ad7616_opm] $axi_ad7616
set_property -dict [list CONFIG.IF_TYPE $ad7616_if] $axi_ad7616

set axi_ad7616_dma [create_bd_cell -type ip -vlnv analog.com:user:axi_dmac:1.0 axi_ad7616_dma]
set_property -dict [list CONFIG.DMA_TYPE_SRC {1}] $axi_ad7616_dma
set_property -dict [list CONFIG.DMA_TYPE_DEST {0}] $axi_ad7616_dma
set_property -dict [list CONFIG.CYCLIC {0}] $axi_ad7616_dma
set_property -dict [list CONFIG.DMA_2D_TRANSFER {0}] $axi_ad7616_dma
set_property -dict [list CONFIG.DMA_DATA_WIDTH_SRC {32}] $axi_ad7616_dma
set_property -dict [list CONFIG.DMA_DATA_WIDTH_DEST {64}] $axi_ad7616_dma

# interface connections
if {$ad7616_if == 0} {

  ad_connect  sclk axi_ad7616/sclk
  ad_connect  sdo axi_ad7616/sdo
  ad_connect  sdi_0 axi_ad7616/sdi_0
  ad_connect  sdi_1 axi_ad7616/sdi_1
  ad_connect  cs_n axi_ad7616/cs_n

  ad_connect  reset_n axi_ad7616/reset_n
  ad_connect  cnvst axi_ad7616/cnvst
  ad_connect  busy axi_ad7616/busy
  ad_connect  seq_en axi_ad7616/seq_en
  ad_connect  hw_rngsel axi_ad7616/hw_rngsel
  ad_connect  chsel axi_ad7616/chsel
  ad_connect  crcen axi_ad7616/crcen
  ad_connect  burst axi_ad7616/burst
  ad_connect  os axi_ad7616/os

  ad_connect  db_o GND
  ad_connect  wr_n GND
  ad_connect  rd_n GND

} else {

}

ad_connect  axi_ad7616/m_axis axi_ad7616_dma/s_axis
ad_connect  sys_cpu_clk axi_ad7616_dma/s_axis_aclk

# interconnect

ad_cpu_interconnect  0x44A00000 axi_ad7616
ad_cpu_interconnect  0x44A30000 axi_ad7616_dma

# memory interconnect

ad_mem_hp1_interconnect sys_cpu_clk sys_ps7/S_AXI_HP1
ad_mem_hp1_interconnect sys_cpu_clk axi_ad7616_dma/m_dest_axi
ad_connect sys_cpu_resetn axi_ad7616_dma/m_dest_axi_aresetn

# interrupts

ad_cpu_interrupt ps-13 mb-12 axi_ad7616_dma/irq
ad_cpu_interrupt ps-12 mb-13 axi_ad7616/irq
