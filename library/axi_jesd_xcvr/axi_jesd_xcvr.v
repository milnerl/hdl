// ***************************************************************************
// ***************************************************************************
// Copyright 2011(c) Analog Devices, Inc.
// 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//     - Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     - Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in
//       the documentation and/or other materials provided with the
//       distribution.
//     - Neither the name of Analog Devices, Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//     - The use of this software may or may not infringe the patent rights
//       of one or more patent holders.  This license does not release you
//       from the requirement that you obtain separate licenses from these
//       patent holders to use this software.
//     - Use of the software either in source or binary form, must be run
//       on or directly connected to an Analog Devices Inc. component.
//    
// THIS SOFTWARE IS PROVIDED BY ANALOG DEVICES "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
// PARTICULAR PURPOSE ARE DISCLAIMED.
//
// IN NO EVENT SHALL ANALOG DEVICES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, INTELLECTUAL PROPERTY
// RIGHTS, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module axi_jesd_xcvr (

  // receive interface

  rx_ref_clk,
  rx_d,
  rx_clk,
  rx_ext_sysref_in,
  rx_ext_sysref_out,
  rx_sync,
  rx_sof,
  rx_data,

  // transmit interface

  tx_ref_clk,
  tx_d,
  tx_clk,
  tx_ext_sysref_in,
  tx_ext_sysref_out,
  tx_sync,
  tx_data,

  // axi-lite (slave)

  s_axi_aclk,
  s_axi_aresetn,
  s_axi_awvalid,
  s_axi_awaddr,
  s_axi_awprot,
  s_axi_awready,
  s_axi_wvalid,
  s_axi_wdata,
  s_axi_wstrb,
  s_axi_wready,
  s_axi_bvalid,
  s_axi_bresp,
  s_axi_bready,
  s_axi_arvalid,
  s_axi_araddr,
  s_axi_arprot,
  s_axi_arready,
  s_axi_rvalid,
  s_axi_rdata,
  s_axi_rresp,
  s_axi_rready);

  parameter   PCORE_ID = 0;
  parameter   PCORE_DEVICE_TYPE = 0;
  parameter   PCORE_NUM_OF_TX_LANES = 4;
  parameter   PCORE_NUM_OF_RX_LANES = 4;

  // receive interface

  input                                         rx_ref_clk;
  input   [(PCORE_NUM_OF_RX_LANES-1):0]         rx_d;
  output                                        rx_clk;
  input                                         rx_ext_sysref_in;
  output                                        rx_ext_sysref_out;
  output                                        rx_sync;
  output  [((PCORE_NUM_OF_RX_LANES* 1)-1):0]    rx_sof;
  output  [((PCORE_NUM_OF_RX_LANES*32)-1):0]    rx_data;

  // transmit interface

  input                                         tx_ref_clk;
  output  [(PCORE_NUM_OF_TX_LANES-1):0]         tx_d;
  output                                        tx_clk;
  input                                         tx_ext_sysref_in;
  output                                        tx_ext_sysref_out;
  input                                         tx_sync;
  input   [((PCORE_NUM_OF_TX_LANES*32)-1):0]    tx_data;

  // axi interface

  input                                         s_axi_aclk;        
  input                                         s_axi_aresetn;     
  input                                         s_axi_awvalid;     
  input   [ 31:0]                               s_axi_awaddr;      
  input   [  2:0]                               s_axi_awprot;      
  output                                        s_axi_awready;     
  input                                         s_axi_wvalid;      
  input   [ 31:0]                               s_axi_wdata;       
  input   [  3:0]                               s_axi_wstrb;       
  output                                        s_axi_wready;      
  output                                        s_axi_bvalid;      
  output  [  1:0]                               s_axi_bresp;       
  input                                         s_axi_bready;      
  input                                         s_axi_arvalid;     
  input   [ 31:0]                               s_axi_araddr;      
  input   [  2:0]                               s_axi_arprot;      
  output                                        s_axi_arready;     
  output                                        s_axi_rvalid;      
  output  [ 31:0]                               s_axi_rdata;       
  output  [  1:0]                               s_axi_rresp;       
  input                                         s_axi_rready;      

  // internal signals                                        

  wire                                          up_rstn;
  wire                                          up_clk;
  wire    [  7:0]                               status_s;
  wire                                          rst;
  wire                                          rx_rstn;
  wire                                          rx_ip_sync_s;
  wire    [  3:0]                               rx_ip_sof_s;                     
  wire    [((PCORE_NUM_OF_RX_LANES*32)-1):0]    rx_ip_data_s;
  wire    [(PCORE_NUM_OF_RX_LANES-1):0]         rx_ready_s;
  wire    [  7:0]                               rx_status_s;
  wire                                          tx_rstn;
  wire                                          tx_ip_sync_s;
  wire    [((PCORE_NUM_OF_TX_LANES*32)-1):0]    tx_ip_data_s;
  wire    [(PCORE_NUM_OF_TX_LANES-1):0]         tx_ready_s;
  wire    [  7:0]                               tx_status_s;
  wire                                          up_wreq_s;
  wire    [ 13:0]                               up_waddr_s;
  wire    [ 31:0]                               up_wdata_s;
  wire                                          up_wack_s;
  wire                                          up_rreq_s;
  wire    [ 13:0]                               up_raddr_s;
  wire    [ 31:0]                               up_rdata_s;
  wire                                          up_rack_s;
                                                
  // assignments

  assign status_s = 8'hff;
  assign up_rstn = s_axi_aresetn;
  assign up_clk = s_axi_aclk;

  generate
  if (PCORE_NUM_OF_TX_LANES < 8) begin
  assign tx_status_s[7:PCORE_NUM_OF_TX_LANES] = status_s[7:PCORE_NUM_OF_TX_LANES];
  assign tx_status_s[(PCORE_NUM_OF_TX_LANES-1):0] = tx_ready_s;
  end else begin
  assign tx_status_s = tx_ready_s[7:0];
  end
  endgenerate

  generate
  if (PCORE_NUM_OF_RX_LANES < 8) begin
  assign rx_status_s[7:PCORE_NUM_OF_RX_LANES] = status_s[7:PCORE_NUM_OF_RX_LANES];
  assign rx_status_s[(PCORE_NUM_OF_RX_LANES-1):0] = rx_ready_s;
  end else begin
  assign rx_status_s = rx_ready_s[7:0];
  end
  endgenerate

  genvar n;
  generate
  for (n = 0; n < PCORE_NUM_OF_RX_LANES; n = n + 1) begin: g_rx_lane
  ad_jesd_align i_jesd_align (
    .rx_clk (rx_clk),
    .rx_ip_sof (rx_ip_sof_s),
    .rx_ip_data (rx_ip_data_s[n*32+31:n*32]),
    .rx_sof (rx_sof[n]),
    .rx_data (rx_data[n*32+31:n*32]));
  end
  endgenerate

  generate
  for (n = 0; n < PCORE_NUM_OF_TX_LANES; n = n + 1) begin: g_tx_lane
  assign tx_ip_data_s[((n*32) + 31):((n*32) + 24)] = tx_data[((n*32) +  7):((n*32) +  0)];
  assign tx_ip_data_s[((n*32) + 23):((n*32) + 16)] = tx_data[((n*32) + 15):((n*32) +  8)];
  assign tx_ip_data_s[((n*32) + 15):((n*32) +  8)] = tx_data[((n*32) + 23):((n*32) + 16)];
  assign tx_ip_data_s[((n*32) +  7):((n*32) +  0)] = tx_data[((n*32) + 31):((n*32) + 24)];
  end
  endgenerate

  sys_xcvr #(
    .PCORE_NUM_OF_TX_LANES (PCORE_NUM_OF_TX_LANES),
    .PCORE_NUM_OF_RX_LANES (PCORE_NUM_OF_RX_LANES))
  i_sys_xcvr (
    .up_clk (up_clk),
    .up_rstn (up_rstn),
    .rx_ref_clk (rx_ref_clk),
    .rx_d (rx_d),
    .tx_ref_clk (tx_ref_clk),
    .tx_d (tx_d),
    .rst (rst),
    .rx_clk (rx_clk),
    .rx_rstn (rx_rstn),
    .rx_sysref (rx_ext_sysref_out),
    .rx_ip_sync (rx_ip_sync_s),
    .rx_ip_sof (rx_ip_sof_s),
    .rx_ip_data (rx_ip_data_s),
    .rx_ready (rx_ready_s),
    .rx_int (),
    .tx_clk (tx_clk),
    .tx_rstn (tx_rstn),
    .tx_sysref (tx_ext_sysref_out),
    .tx_ip_sync (tx_ip_sync_s),
    .tx_ip_data (tx_ip_data_s),
    .tx_ready (tx_ready_s),
    .tx_int ());

  // processor
    
  up_xcvr #(
    .PCORE_ID(PCORE_ID),
    .PCORE_DEVICE_TYPE(PCORE_DEVICE_TYPE))
  i_up_xcvr (
    .rst (rst),
    .rx_clk (rx_clk),
    .rx_rstn (rx_rstn),
    .rx_ext_sysref (rx_ext_sysref_in),
    .rx_sysref (rx_ext_sysref_out),
    .rx_ip_sync (rx_ip_sync_s),
    .rx_sync (rx_sync),
    .rx_status (rx_status_s),
    .tx_clk (tx_clk),
    .tx_rstn (tx_rstn),
    .tx_ext_sysref (tx_ext_sysref_in),
    .tx_sysref (tx_ext_sysref_out),
    .tx_sync (tx_sync),
    .tx_ip_sync (tx_ip_sync_s),
    .tx_status (tx_status_s),
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s),
    .up_rack (up_rack_s));

  // axi interface

  up_axi i_up_axi (
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_axi_awvalid (s_axi_awvalid),
    .up_axi_awaddr (s_axi_awaddr),
    .up_axi_awready (s_axi_awready),
    .up_axi_wvalid (s_axi_wvalid),
    .up_axi_wdata (s_axi_wdata),
    .up_axi_wstrb (s_axi_wstrb),
    .up_axi_wready (s_axi_wready),
    .up_axi_bvalid (s_axi_bvalid),
    .up_axi_bresp (s_axi_bresp),
    .up_axi_bready (s_axi_bready),
    .up_axi_arvalid (s_axi_arvalid),
    .up_axi_araddr (s_axi_araddr),
    .up_axi_arready (s_axi_arready),
    .up_axi_rvalid (s_axi_rvalid),
    .up_axi_rresp (s_axi_rresp),
    .up_axi_rdata (s_axi_rdata),
    .up_axi_rready (s_axi_rready),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s),
    .up_rack (up_rack_s));

endmodule

// ***************************************************************************
// ***************************************************************************