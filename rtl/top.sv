////////////////////////////////////////////////////////////////////////////////
// Engineer:        Dominik Majak
//
// Design Name:     FFT_R2_R22_IP
// Module Name:     TOP
// Target Devices:  Basys 3 - Xilinx Artix XC7A35T
// Tool Versions:   Vivado 2024.2
// Description:
//                  Jednostka glowna, laczaca pozostale moduly.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module TOP #(
parameter N = 16, // szerokosc danych
parameter FFT_N = 256,
parameter KODEK_BCLK_Hz = 12_288_000,
parameter F_PROBKOWANIA_Hz = 48_000
)(
input logic i_clk,
input logic i_rst,
input logic [1:0] i_dds_typ,
input logic [2:0] i_dds_krok,
output logic o_locked
); // TOP

logic rst, clk_12M288;
always_ff @(posedge i_clk) rst <= i_rst;
 
GENERACJA_ZEGAROW I_GENERACJA_ZEGAROW (
.clk_100M(i_clk), .clk_12M288(clk_12M288),
.reset(rst), .locked(o_locked)
); // I_GENERACJA_ZEGAROW

logic [31:0] r_dds_krok;
always_ff @(posedge i_clk) begin
  case (i_dds_krok)
    'd0: r_dds_krok <= 42950;
    'd1: r_dds_krok <= 42950*2;
    'd2: r_dds_krok <= 42950*3;
    'd3: r_dds_krok <= 42950*4;
    'd4: r_dds_krok <= 42950*5;
    'd5: r_dds_krok <= 42950*6;
    'd6: r_dds_krok <= 42950*7;
    default: r_dds_krok <= 42950*8;
  endcase
end

logic [N-1:0] dds_dane_o;
DDS #(
.N(16), .DDS_LICZBA_PROBEK(64)
) I_DDS (
.i_rst(i_rst), .i_clk(i_clk),
.i_krok(r_dds_krok), .i_typ(i_dds_typ),
.i_wzmocnienie(11'd256),
.o_dane(dds_dane_o)
); // I_DDS

logic [$clog2(KODEK_BCLK_Hz/F_PROBKOWANIA_Hz)-1:0] cnt_fs;
logic clk_fs;
logic r2_last, r22_last, ip_last;
logic signed [N-1:0] r2_re, r2_im, r22_re, r22_im, ip_re, ip_im;
logic signed [N*2-1:0] amp_r2, amp_r22, amp_ip;

always @(posedge clk_12M288 or posedge i_rst) begin
  if (i_rst) cnt_fs <= 'd0;
  else       cnt_fs <= cnt_fs + 'd1;
end
assign clk_fs = cnt_fs[$high(cnt_fs)];

FFT_TOP_R2 #(
.N(N), .W_N(16), .FFT_N(FFT_N),
.KODEK_BCLK_Hz(KODEK_BCLK_Hz),
.F_PROBKOWANIA_Hz(F_PROBKOWANIA_Hz)
) I_R2 (
.i_rst(i_rst), .i_clk(i_clk),
.i_clk_fs(clk_fs),
.i_dane_re(dds_dane_o), .i_dane_im('d0),
.o_dane_re(r2_re),
.o_dane_im(r2_im),
.o_ostatnie(r2_last)
); // I_R2

FFT_TOP_R22 #(
.N(N), .W_N(16), .FFT_N(FFT_N),
.KODEK_BCLK_Hz(KODEK_BCLK_Hz),
.F_PROBKOWANIA_Hz(F_PROBKOWANIA_Hz)
) I_R22 (
.i_rst(i_rst), .i_clk(i_clk),
.i_clk_fs(clk_fs),
.i_dane_re(dds_dane_o), .i_dane_im('d0),
.o_dane_re(r22_re),
.o_dane_im(r22_im),
.o_ostatnie(r22_last)
); // I_R22

IP_CORE_FFT_WRAPPER #(
.N(N), .FFT_N(FFT_N)
) I_IP (
.i_rst(i_rst), .i_clk(clk_fs),
.i_dane_re(dds_dane_o), .i_dane_im('d0),
.o_dane_re(ip_re),
.o_dane_im(ip_im),
.o_ostatnie(ip_last)
); // I_IP

logic signed [N-1:0] ila_dane_re;
logic signed [N-1:0] ila_fft_re_r2, ila_fft_re_r22;
logic signed [N-1:0] ila_fft_im_r2, ila_fft_im_r22;
logic signed [N-1:0] ila_fft_re_ip, ila_fft_im_ip;
logic [$clog2(FFT_N)-1:0] ila_adres;

ILA_FFT I_ILA_FFT (
.clk(i_clk),
.probe0(ila_dane_re),
.probe1(ila_fft_re_r2),
.probe2(ila_fft_im_r2),
.probe3(ila_adres),
.probe4(ila_fft_re_r22),
.probe5(ila_fft_im_r22),
.probe6(ila_fft_re_ip),
.probe7(ila_fft_im_ip),
.probe8(amp_r2),
.probe9(amp_r22),
.probe10(amp_ip)
); // I_ILA_FFT
    
ILA_PAMIEC #(
.N(N), .DIF_DIT(1), .FFT_N(FFT_N)
) I_ILA_PAMIEC (
.i_rst(rst), .i_rst_wr(r2_last),
.i_clk_wr(clk_fs), .i_clk_rd(i_clk),
.i_dane_wr_re(dds_dane_o),
.i_fft_wr_re_r2(r2_re),   .i_fft_wr_im_r2(r2_im),
.i_fft_wr_re_r22(r22_re), .i_fft_wr_im_r22(r22_im),
.i_fft_wr_re_ip(ip_re),   .i_fft_wr_im_ip(ip_im),
.o_adres_rd(ila_adres),
.o_dane_rd_re(ila_dane_re),
.o_fft_rd_re_r2(ila_fft_re_r2),   .o_fft_rd_im_r2(ila_fft_im_r2),
.o_fft_rd_re_r22(ila_fft_re_r22), .o_fft_rd_im_r22(ila_fft_im_r22),
.o_fft_rd_re_ip(ila_fft_re_ip),   .o_fft_rd_im_ip(ila_fft_im_ip),
.o_amp_r2(amp_r2), .o_amp_r22(amp_r22), .o_amp_ip(amp_ip)
); // I_ILA_PAMIEC

endmodule // TOP
