//////////////////////////////////////////////////////////////////////////////////
// Engineer:        Dominik Majak
//
// Design Name:     FFT_R2_R22_IP
// Module Name:     IP_CORE_FFT_WRAPPER
// Target Devices:  Basys 3 - Xilinx Artix XC7A35T
// Tool Versions:   Vivado 2024.2
// Description:
//                  Wrapper dla IP Core FFT. Wywoluje IP Core i zapewnia
//                  minimalne wysterowanie moduly do pracy ciaglej.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module IP_CORE_FFT_WRAPPER #(
parameter N = 16,
parameter FFT_N = 256
)(
input logic i_rst,
input logic i_clk,
input logic signed [N-1:0] i_dane_re,
input logic signed [N-1:0] i_dane_im,
output logic signed [N-1:0] o_dane_re,
output logic signed [N-1:0] o_dane_im,
output logic o_ostatnie
); // IP_CORE_FFT_WRAPPER

logic [7:0] s_axis_config_tdata = 'd0;
logic s_axis_config_tvalid = 'b0;
logic s_axis_config_tready;
logic s_axis_data_tready;
logic m_axis_data_tvalid;
logic event_frame_started;
logic event_tlast_unexpected;
logic event_tlast_missing;
logic event_status_channel_halt;
logic event_data_in_channel_halt;
logic event_data_out_channel_halt;
logic tlast;
logic [$clog2(FFT_N)-1:0] licznik = 'b0;

IP_CORE_FFT I_IP_CORE_FFT (
.aclk(i_clk),
.s_axis_config_tdata(s_axis_config_tdata),
.s_axis_config_tvalid(s_axis_config_tvalid),
.s_axis_config_tready(s_axis_config_tready),
.s_axis_data_tdata({i_dane_im, i_dane_re}),
.s_axis_data_tvalid(1'b1),
.s_axis_data_tready(s_axis_data_tready),
.s_axis_data_tlast(tlast),
.m_axis_data_tdata({o_dane_im, o_dane_re}),
.m_axis_data_tvalid(m_axis_data_tvalid),
.m_axis_data_tready(1'b1),
.m_axis_data_tlast(o_ostatnie),
.event_frame_started(event_frame_started),
.event_tlast_unexpected(event_tlast_unexpected),
.event_tlast_missing(event_tlast_missing),
.event_status_channel_halt(event_status_channel_halt),
.event_data_in_channel_halt(event_data_in_channel_halt),
.event_data_out_channel_halt(event_data_out_channel_halt)
); // I_IP_CORE_FFT

always @(posedge i_clk or posedge i_rst)
  if (i_rst) licznik <= 'd0;
  else       licznik <= licznik + 'd1;

assign tlast = (licznik == FFT_N-1);

endmodule // IP_CORE_FFT_WRAPPER
