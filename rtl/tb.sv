////////////////////////////////////////////////////////////////////////////////
// Engineer:        Dominik Majak
//
// Design Name:     TB
// Module Name:     FFT_WARSTWA_DIF_R22_ZLOZONA
// Target Devices:  Basys 3 - Xilinx Artix XC7A35T
// Tool Versions:   Vivado 2024.2
// Description:
//                  Testbench. Sprawdza poprawnosc obliczania prazkow poprzez
//                  wypisanie w oknie konsoli wyznaczonych wartosci.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`default_nettype none

module TB;

localparam int N = 16;
localparam int W_N = 16;
localparam int FFT_N = 256;
localparam int KODEK_BCLK_Hz = 64;
localparam int F_PROBKOWANIA_Hz = 1;

logic rst, clk, clk_fs;
logic signed [N-1:0] dds_data;
logic r2_last, r22_last, ip_last;
logic signed [N-1:0] r2_re, r2_im, r22_re, r22_im, ip_re, ip_im;
logic [N*2-1:0] r2_amp, r22_amp, ip_amp;
int krok;

DDS #( .N(N), .DDS_LICZBA_PROBEK(256) )
I_DDS (.i_rst(rst), .i_clk(clk),
.i_krok(krok), .i_typ('d1), .i_wzmocnienie('d512),
.o_dane(dds_data)
); // I_DDS

FFT_TOP_R22 #(
.N(N), .W_N(W_N), .FFT_N(FFT_N),
.KODEK_BCLK_Hz(KODEK_BCLK_Hz),
.F_PROBKOWANIA_Hz(F_PROBKOWANIA_Hz)
) I_R22 (
.i_rst(rst), .i_clk(clk),
.i_clk_fs(clk_fs),
.i_dane_re(dds_data), .i_dane_im('d0),
.o_dane_re(r22_re),
.o_dane_im(r22_im),
.o_ostatnie(r22_last)
); // I_R22

FFT_TOP_R2 #(
.N(N), .W_N(W_N), .FFT_N(FFT_N),
.KODEK_BCLK_Hz(KODEK_BCLK_Hz),
.F_PROBKOWANIA_Hz(F_PROBKOWANIA_Hz)
) I_R2 (
.i_rst(rst), .i_clk(clk),
.i_clk_fs(clk_fs),
.i_dane_re(dds_data), .i_dane_im('d0),
.o_dane_re(r2_re),
.o_dane_im(r2_im),
.o_ostatnie(r2_last)
); // I_R2

IP_CORE_FFT_WRAPPER #(
.N(N), .FFT_N(FFT_N)
) I_IP (
.i_rst(rst), .i_clk(clk_fs),
.i_dane_re(dds_data), .i_dane_im('d0),
.o_dane_re(ip_re),
.o_dane_im(ip_im),
.o_ostatnie(ip_last)
); // I_IP


assign #40.5 clk = (clk === 0);
logic [7:0] cnt_fs = 0;
always @(posedge clk) begin
  cnt_fs <= cnt_fs + 'd1;
end
assign clk_fs = cnt_fs[7];

initial begin
  krok = 350000;
  rst = 1'b0;
  #10000;
  rst = 1'b1;
  #10000;
  rst = 1'b0;
  #8ms;
  krok = 700000;
  #6ms;
  krok = 1400000;
  #4ms;
  krok = 2000000;
  #4ms;
  krok = 3000000;
end

assign r2_amp = r2_re*r2_re + r2_im*r2_im;
assign r22_amp = r22_re*r22_re + r22_im*r22_im;
assign ip_amp = ip_re*ip_re + ip_im*ip_im;

int ip_last_cnt = 0;
initial begin
  forever begin
    @(posedge clk_fs);
    if (ip_last) begin
      ip_last_cnt++;
      if (ip_last_cnt == 2) break;
    end
  end

  for (int i=0; i<100; i++) begin
    if (ip_last_cnt == 2) begin
      $display("R2: %4.0d,      R22: %4.0d,      IP: %4.0d", $sqrt(R2_AMP), $sqrt(R22_AMP), $sqrt(ip_amp));
    end
    @(posedge clk_fs);
  end
  $finish;
end

logic [$clog2(FFT_N)-1:0] adr_wr;
logic [N-1:0] r2_ram [0:FFT_N-1];
logic [N-1:0] r22_ram [0:FFT_N-1];
logic [N-1:0] ip_ram [0:FFT_N-1];

always_ff @(posedge clk_fs) begin
  if (rst || r2_last) adr_wr <= 1;
  else adr_wr <= adr_wr + 1;
end

always_ff @(posedge clk_fs) begin
  r2_ram[adr_wr] <= r2_amp;
  r22_ram[adr_wr] <= r22_amp;
end

localparam OPOZNIENIE = 43;
logic signed [2*N-1:0] linia_opozniajaca;

always_ff @(posedge clk_fs) begin
  linia_opozniajaca[0] <= ip_amp;
  for (int i = 1; i < OPOZNIENIE; i++) begin
    linia_opozniajaca[i] <= linia_opozniajaca[i-1];
  end
end

always_ff @(posedge clk_fs) ip_ram[adr_wr] <= linia_opozniajaca[OPOZNIENIE-1];

localparam WYROWNANIE = 1*FFT_N+20;
logic [2*N-1:0] lo_r2_amp [0:WYROWNANIE];
logic [2*N-1:0] lo_r22_amp [0:WYROWNANIE];
logic [WYROWNANIE:0] lo_r2_last;
logic [WYROWNANIE:0] lo_r22_last;

always_ff @(posedge clk_fs) begin
  lo_r2_amp[0] <= r2_amp;
  for (int i = 1; i < WYROWNANIE; i++) begin
    lo_r2_amp[i] <= lo_r2_amp[i-1];
  end
end

always_ff @(posedge clk_fs) begin
  lo_r22_amp[0] <= r22_amp;
  for (int i = 1; i < WYROWNANIE; i++) begin
    lo_r22_amp[i] <= lo_r22_amp[i-1];
  end
end

always_ff @(posedge clk_fs) lo_r2_last <= {lo_r2_last[$high(lo_r2_last)-2:0], r2_last};
always_ff @(posedge clk_fs) lo_r22_last <= {lo_r22_last[$high(lo_r22_last)-2:0], r22_last};

logic R2_LAST, R22_LAST;
logic [2*N-1:0] R2_AMP, R22_AMP;

assign R2_LAST = lo_r2_last[$high(lo_r2_last)-1];
assign R22_LAST = lo_r22_last[$high(lo_r22_last)-1];
assign R2_AMP = lo_r2_amp[WYROWNANIE-1];
assign R22_AMP = lo_r22_amp[WYROWNANIE-1];

endmodule // TB
