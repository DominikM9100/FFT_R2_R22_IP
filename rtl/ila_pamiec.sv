////////////////////////////////////////////////////////////////////////////////
// Engineer:        Dominik Majak
//
// Design Name:     FFT_R2_R22_IP
// Module Name:     ILA_PAMIEC
// Target Devices:  Basys 3 - Xilinx Artix XC7A35T
// Tool Versions:   Vivado 2024.2
// Description:
//                  Modul pamieci odwracajacej kolejnosc bitow.
//////////////////////////////////////////////////////////////////////////////////

module ILA_PAMIEC #(
parameter N = 16,
parameter DIF_DIT = 1, // (DIF) 1 - bit-reverse | (DIT) 0 - natural-order
parameter FFT_N = 64
)(
input logic i_rst,
input logic i_rst_wr, i_clk_wr,
input logic signed [N-1:0] i_dane_wr_re, // from DDS
input logic signed [N-1:0] i_fft_wr_re_r2, i_fft_wr_im_r2,
input logic signed [N-1:0] i_fft_wr_re_r22, i_fft_wr_im_r22,
input logic signed [N-1:0] i_fft_wr_re_ip, i_fft_wr_im_ip,
input logic i_clk_rd,
output logic [7:0] o_adres_rd,
output logic signed [N-1:0] o_dane_rd_re,
output logic signed [N-1:0] o_fft_rd_re_r2, o_fft_rd_im_r2,
output logic signed [N-1:0] o_fft_rd_re_r22, o_fft_rd_im_r22,
output logic signed [N-1:0] o_fft_rd_re_ip, o_fft_rd_im_ip,
output logic signed [2*N:0] o_amp_r2, o_amp_r22, o_amp_ip
); // ILA_PAMIEC

logic signed [N-1:0] ram_dane_re [0:FFT_N-1];
logic signed [N-1:0] ram_fft_re_r2 [0:FFT_N-1];
logic signed [N-1:0] ram_fft_im_r2 [0:FFT_N-1];
logic signed [N-1:0] ram_fft_re_r22 [0:FFT_N-1];
logic signed [N-1:0] ram_fft_im_r22 [0:FFT_N-1];
logic signed [N-1:0] ram_fft_re_ip [0:FFT_N-1];
logic signed [N-1:0] ram_fft_im_ip [0:FFT_N-1];
logic [$clog2(FFT_N)-1:0] adres_wr;
logic [$clog2(FFT_N)-1:0] adres_rd;
logic signed [N-1:0] fft_rd_re_r2, fft_rd_im_r2;
logic signed [N-1:0] fft_rd_re_r22, fft_rd_im_r22;
logic signed [N-1:0] fft_rd_re_ip, fft_rd_im_ip;

always_ff @(posedge i_clk_wr)
begin: AFF_ILA_PAMIEC_OBRAZU_ADRES_WR
  if (i_rst || i_rst_wr) adres_wr <= 'd0;
  else                   adres_wr <= adres_wr + 'd1;
end // AFF_ILA_PAMIEC_OBRAZU_ADRES_WR

always_ff @(posedge i_clk_rd)
begin: AFF_ILA_PAMIEC_OBRAZU_ADRES_RD
  if (i_rst) adres_rd <= 'd0;
  else       adres_rd <= adres_rd + 'd1;
end // AFF_ILA_PAMIEC_OBRAZU_ADRES_RD

always_ff @(posedge i_clk_wr) ram_dane_re[adres_wr] <= i_dane_wr_re;
always_ff @(posedge i_clk_wr) ram_fft_re_r2[adres_wr] <= i_fft_wr_re_r2;
always_ff @(posedge i_clk_wr) ram_fft_im_r2[adres_wr] <= i_fft_wr_im_r2;

always_ff @(posedge i_clk_wr) ram_fft_re_r22[adres_wr] <= i_fft_wr_re_r22;
always_ff @(posedge i_clk_wr) ram_fft_im_r22[adres_wr] <= i_fft_wr_im_r22;

localparam OPOZNIENIE = 43;
logic signed [N-1:0] dane_wr_re_opoznione;
logic signed [N-1:0] linia_opozniajaca_re [0:OPOZNIENIE-1];
logic signed [N-1:0] linia_opozniajaca_im [0:OPOZNIENIE-1];

always_ff @(posedge i_clk_wr) begin: AFF_ILA_PAMIEC_LINIA_OPOZNIAJACA
  linia_opozniajaca_re[0] <= i_fft_wr_re_ip;
  linia_opozniajaca_im[0] <= i_fft_wr_im_ip;
  for (int i = 1; i < OPOZNIENIE; i++) begin
    linia_opozniajaca_re[i] <= linia_opozniajaca_re[i-1];
    linia_opozniajaca_im[i] <= linia_opozniajaca_im[i-1];
  end
end // AFF_ILA_PAMIEC_LINIA_OPOZNIAJACA

always_ff @(posedge i_clk_wr) ram_fft_re_ip[adres_wr] <= linia_opozniajaca_re[OPOZNIENIE-1];
always_ff @(posedge i_clk_wr) ram_fft_im_ip[adres_wr] <= linia_opozniajaca_im[OPOZNIENIE-1];

generate
  if (DIF_DIT) begin: G_ILA_DIF
    logic [7:0] adres_rd_owrocone;
    always_comb
    begin: ACOMB_ILA_PAMIEC_OBRAZU_ODWROCENIE_BITOW
      adres_rd_owrocone = 'd0;
      for (int i = 0; i < $clog2(FFT_N); i++) begin
        adres_rd_owrocone[i] = adres_rd[($clog2(FFT_N)-1)-i];
      end
    end // ACOMB_ILA_PAMIEC_OBRAZU_ODWROCENIE_BITOW
    always_ff @(posedge i_clk_rd) o_dane_rd_re <= ram_dane_re[adres_rd];
    always_ff @(posedge i_clk_rd) fft_rd_re_r2 <= ram_fft_re_r2[adres_rd_owrocone];
    always_ff @(posedge i_clk_rd) fft_rd_im_r2 <= ram_fft_im_r2[adres_rd_owrocone];
    always_ff @(posedge i_clk_rd) fft_rd_re_r22 <= ram_fft_re_r22[adres_rd_owrocone];
    always_ff @(posedge i_clk_rd) fft_rd_im_r22 <= ram_fft_im_r22[adres_rd_owrocone];
    always_ff @(posedge i_clk_rd) fft_rd_re_ip <= ram_fft_re_ip[adres_rd_owrocone];
    always_ff @(posedge i_clk_rd) fft_rd_im_ip <= ram_fft_im_ip[adres_rd_owrocone];
  end
  else begin: G_ILA_DIT
    always_ff @(posedge i_clk_rd) o_dane_rd_re <= ram_dane_re[adres_rd];
    always_ff @(posedge i_clk_rd) fft_rd_re_r2 <= ram_fft_re_r2[adres_rd];
    always_ff @(posedge i_clk_rd) fft_rd_im_r2 <= ram_fft_im_r2[adres_rd];
    always_ff @(posedge i_clk_rd) fft_rd_re_r22 <= ram_fft_re_r22[adres_rd];
    always_ff @(posedge i_clk_rd) fft_rd_im_r22 <= ram_fft_im_r22[adres_rd];
    always_ff @(posedge i_clk_rd) fft_rd_re_ip <= ram_fft_re_ip[adres_rd];
    always_ff @(posedge i_clk_rd) fft_rd_im_ip <= ram_fft_im_ip[adres_rd];
  end
endgenerate

assign o_fft_rd_re_r2 = fft_rd_re_r2;
assign o_fft_rd_im_r2 = fft_rd_im_r2;

assign o_fft_rd_re_r22 = fft_rd_re_r22;
assign o_fft_rd_im_r22 = fft_rd_im_r22;

assign o_fft_rd_re_ip = fft_rd_re_ip;
assign o_fft_rd_im_ip = fft_rd_im_ip;

logic [2*N:0] mult_re_r2, mult_re_r22, mult_re_ip;
logic [2*N:0] mult_im_r2, mult_im_r22, mult_im_ip;
always_ff @(posedge i_clk_rd) begin
  mult_re_r2  <= fft_rd_re_r2*fft_rd_re_r2;
  mult_im_r2  <= fft_rd_im_r2*fft_rd_im_r2;
  mult_re_r22 <= fft_rd_re_r22*fft_rd_re_r22;
  mult_im_r22 <= fft_rd_im_r22*fft_rd_im_r22;
  mult_re_ip  <= fft_rd_re_ip*fft_rd_re_ip;
  mult_im_ip  <= fft_rd_im_ip*fft_rd_im_ip;
  o_amp_r2  <= mult_re_r2 + mult_im_r2;
  o_amp_r22 <= mult_re_r22 + mult_im_r22;
  o_amp_ip  <= mult_re_ip + mult_im_ip;
end

generate
  if        (FFT_N == 256)   assign o_adres_rd = adres_rd-'d1;
  else if   (FFT_N == 128)   assign o_adres_rd = {1'b0, (adres_rd-'d1)};
  else if   (FFT_N == 16)    assign o_adres_rd = {4'b0000, (adres_rd-'d1)};
  else    /*(FFT_N ==  64)*/ assign o_adres_rd = {2'b00, (adres_rd-'d1)};
endgenerate

endmodule; // ILA_PAMIEC
