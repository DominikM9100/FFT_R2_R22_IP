//////////////////////////////////////////////////////////////////////////////////
// Engineer:        Dominik Majak
//
// Design Name:     FFT_R2_R22_IP
// Module Name:     FFT_TOP_R2
// Target Devices:  Basys 3 - Xilinx Artix XC7A35T
// Tool Versions:   Vivado 2024.2
// Description:
//                  Modul wywoluje i laczy kolejne warstwy FFT. Zawiera rowniez
//                  licznik prazkow widmowych, ktory wskazuje na numer aktualnego
//                  prazka.
//////////////////////////////////////////////////////////////////////////////////

module FFT_TOP_R2 #(
parameter N = 16,
parameter W_N = 16,
parameter FFT_N = 256,
parameter KODEK_BCLK_Hz = 12_288_000,
parameter F_PROBKOWANIA_Hz = 48_000
)(
input logic i_rst, i_clk, i_clk_fs,
input logic signed [N-1:0] i_dane_re, i_dane_im,
output logic signed [N-1:0] o_dane_re, o_dane_im,
output logic o_ostatnie
); // FFT_TOP_R2

logic [$clog2(FFT_N)-1:0] licznik;
typedef logic [N-1:0] t_polaczenie [0:$clog2(FFT_N)];
t_polaczenie polaczenie_re, polaczenie_im;

assign polaczenie_re[$clog2(FFT_N)] = i_dane_re;
assign polaczenie_im[$clog2(FFT_N)] = i_dane_im;

for (genvar i = $clog2(FFT_N); i >= 1; i = i-1)
begin: G_FOR_DSP_WARSTWA_DIF
  localparam int BUFOR_N = 1 << (i-1), KROK = 1 << ($clog2(FFT_N)-i);
  FFT_WARSTWA_DIF_R2 #(
  .BUFOR_N(BUFOR_N), .KROK(KROK), .N(N), .W_N(W_N),
  .FFT_N(FFT_N), .KODEK_BCLK_Hz(KODEK_BCLK_Hz),
  .F_PROBKOWANIA_Hz(F_PROBKOWANIA_Hz)
  ) I_FFT_WARSTWA_DIF_R2 (
  .i_rst(i_rst), .i_clk(i_clk), .i_clk_fs(i_clk_fs),
  .i_dane_re(polaczenie_re[i]), .i_dane_im(polaczenie_im[i]),
  .o_dane_re(polaczenie_re[i-1]), .o_dane_im(polaczenie_im[i-1]) );
end // G_FOR_DSP_WARSTWA_DIF

// licznik prazkow
always_ff @(posedge i_clk_fs or posedge i_rst)
begin: AFF_DSP_FFT_DIF_LICZNIK
  if (i_rst) licznik <= 'd1;
  else       licznik <= licznik + 'b1;
end // AFF_DSP_FFT_DIF_LICZNIK

assign o_dane_re = polaczenie_re[0];
assign o_dane_im = polaczenie_im[0];
assign o_ostatnie = (licznik == FFT_N-1);

endmodule // FFT_TOP_R2
