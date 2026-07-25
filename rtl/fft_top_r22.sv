////////////////////////////////////////////////////////////////////////////////
// Engineer:        Dominik Majak
//
// Design Name:     FFT_R2_R22_IP
// Module Name:     FFT_TOP_R22
// Target Devices:  Basys 3 - Xilinx Artix XC7A35T
// Tool Versions:   Vivado 2024.2
// Description:
//                  Jednostka laczaca warstwy trywialne i zlozone w R22 DIF FFT.
//////////////////////////////////////////////////////////////////////////////////

module FFT_TOP_R22 #(
parameter N = 16,
parameter W_N = 16,
parameter FFT_N = 256,
parameter KODEK_BCLK_Hz = 12_288_000,
parameter F_PROBKOWANIA_Hz = 48_000
)(
input  logic i_rst, i_clk, i_clk_fs,
input  logic signed [N-1:0] i_dane_re, i_dane_im,
output logic signed [N-1:0] o_dane_re, o_dane_im,
output logic o_ostatnie
);

localparam int M = $clog2(FFT_N);
logic [$clog2(FFT_N)-1:0] licznik;
typedef logic signed [N-1:0] t_polaczenie [0:M];
t_polaczenie polaczenie_re, polaczenie_im;

assign polaczenie_re[M] = i_dane_re;
assign polaczenie_im[M] = i_dane_im;

for (genvar m = 1; m <= M/2; m = m + 1) begin : G_PARA_R22
  localparam int BUFOR_T = FFT_N >> (2*m - 1);
  localparam int BUFOR_F = FFT_N >> (2*m);
  localparam int KROK_F  = 1 << (2*(m-1));

  // --- warstwa trywialna  ---
  FFT_WARSTWA_DIF_R22_TRYWIALNA #(
  .BUFOR_N(BUFOR_T), .N(N)
  ) I_FFT_WARSTWA_DIF_R22_TRYWIALNA (
  .i_rst(i_rst),
  .i_clk_fs(i_clk_fs),
  .i_dane_re(polaczenie_re[M - 2*(m-1)]),
  .i_dane_im(polaczenie_im[M - 2*(m-1)]),
  .o_dane_re(polaczenie_re[M - 2*(m-1) - 1]),
  .o_dane_im(polaczenie_im[M - 2*(m-1) - 1])
  ); // I_FFT_WARSTWA_DIF_R22_TRYWIALNA

  // --- warstwa zlozona ---
  FFT_WARSTWA_DIF_R22_ZLOZONA #(
  .BUFOR_N(BUFOR_F), .KROK(KROK_F),
  .N(N), .W_N(W_N), .FFT_N(FFT_N),
  .KODEK_BCLK_Hz(KODEK_BCLK_Hz),
  .F_PROBKOWANIA_Hz(F_PROBKOWANIA_Hz)
  ) I_FFT_WARSTWA_DIF_R22_ZLOZONA (
  .i_rst(i_rst), .i_clk(i_clk), .i_clk_fs(i_clk_fs),
  .i_dane_re(polaczenie_re[M - 2*(m-1) - 1]),
  .i_dane_im(polaczenie_im[M - 2*(m-1) - 1]),
  .o_dane_re(polaczenie_re[M - 2*(m-1) - 2]),
  .o_dane_im(polaczenie_im[M - 2*(m-1) - 2])
  ); // I_FFT_WARSTWA_DIF_R22_ZLOZONA
end

always_ff @(posedge i_clk_fs or posedge i_rst) begin
  if (i_rst) licznik <= 'd1;
  else       licznik <= licznik + 1'b1;
end

assign o_dane_re  = polaczenie_re[0];
assign o_dane_im  = polaczenie_im[0];
assign o_ostatnie = (licznik == FFT_N - 1);

endmodule : FFT_TOP_R22
