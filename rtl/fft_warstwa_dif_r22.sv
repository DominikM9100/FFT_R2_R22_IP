////////////////////////////////////////////////////////////////////////////////
// Engineer:        Dominik Majak
//
// Design Name:     FFT_R2_R22_IP
// Module Name:     FFT_WARSTWA_DIF_R22_ZLOZONA
// Target Devices:  Basys 3 - Xilinx Artix XC7A35T
// Tool Versions:   Vivado 2024.2
// Description:
//                  Jednostka wykorzysuje algorytm R22 do implementacji
//                  operacji motylkowych. Jest to jednostka wykonująca
//                  operacje złożone.
//////////////////////////////////////////////////////////////////////////////////

module FFT_WARSTWA_DIF_R22_ZLOZONA #(
parameter BUFOR_N          = 64,
parameter KROK             = 128,
parameter N                = 16,
parameter W_N              = 16,
parameter FFT_N            = 256,
parameter KODEK_BCLK_Hz    = 12_288_000,
parameter F_PROBKOWANIA_Hz = 48_000
)(
input logic i_rst, i_clk, i_clk_fs,
input logic signed [N-1:0] i_dane_re, i_dane_im,
output logic signed [N-1:0] o_dane_re, o_dane_im
);

localparam int ROT_BIT = $clog2(BUFOR_N);

logic [ROT_BIT+1:0] licznik;
always_ff @(posedge i_clk_fs or posedge i_rst) begin
  if (i_rst) licznik <= '0;
  else       licznik <= licznik + 1'b1;
end

logic [1:0] phase;
assign phase = licznik[ROT_BIT+1 : ROT_BIT];

// --- mnozenie przez trywialne -j na wejsciu ---
logic signed [N-1:0] i_dane_rot_re, i_dane_rot_im;
always_comb begin
  if (phase == 2'b01) begin
    i_dane_rot_re =  i_dane_im;
    i_dane_rot_im = -i_dane_re;
  end else begin
    i_dane_rot_re =  i_dane_re;
    i_dane_rot_im =  i_dane_im;
  end
end

// --- ROM Twiddle Factor (TF) ---
typedef logic signed [W_N-1:0] t_w_rom [0:(FFT_N/2)-1];

function automatic t_w_rom GEN_W_RE_ROM();
  t_w_rom temp;
  real faza; int wartosc;
  for (int i=0; i<FFT_N/2; i++) begin
    faza = 3.14159 * i / (FFT_N/2);
    wartosc = (2**(W_N-1) - 1) * $cos(faza);
    temp[i] = $rtoi($floor(wartosc + 0.5));
  end
  return temp;
endfunction

function automatic t_w_rom GEN_W_IM_ROM();
  t_w_rom temp;
  real faza; int wartosc;
  for (int i=0; i<FFT_N/2; i++) begin
    faza = 3.14159 * i / (FFT_N/2);
    wartosc = -(2**(W_N-1) - 1) * $sin(faza);
    temp[i] = $rtoi($floor(wartosc + 0.5));
  end
  return temp;
endfunction

parameter t_w_rom W_RE_ROM = GEN_W_RE_ROM();
parameter t_w_rom W_IM_ROM = GEN_W_IM_ROM();

// --- struktura R2 motylka ---
typedef logic signed [N-1:0] t_bufor [0:BUFOR_N-1];
t_bufor bufor_re, bufor_im;

logic signed   [N:0]   suma_re, suma_im, roznica_re, roznica_im;
logic signed [N-1:0] a_re, a_im, b_re, b_im;
logic signed [N-1:0] i_bufor_re, i_bufor_im;

always_comb begin
  suma_re    = bufor_re[BUFOR_N-1] + i_dane_rot_re;
  suma_im    = bufor_im[BUFOR_N-1] + i_dane_rot_im;
  roznica_re = bufor_re[BUFOR_N-1] - i_dane_rot_re;
  roznica_im = bufor_im[BUFOR_N-1] - i_dane_rot_im;
end

assign a_re = suma_re[N:1];
assign a_im = suma_im[N:1];
assign b_re = roznica_re[N:1];
assign b_im = roznica_im[N:1];

assign i_bufor_re = (licznik[ROT_BIT] == 1'b0) ? i_dane_rot_re : b_re;
assign i_bufor_im = (licznik[ROT_BIT] == 1'b0) ? i_dane_rot_im : b_im;

// --- wybor probki TF ---
always_ff @(posedge i_clk_fs) begin
  bufor_re[0] <= i_bufor_re;
  bufor_im[0] <= i_bufor_im;
  for (int i=1; i<BUFOR_N; i++) begin
    bufor_re[i] <= bufor_re[i-1];
    bufor_im[i] <= bufor_im[i-1];
  end
end

logic signed [N-1:0] o_dane_pre_re, o_dane_pre_im;
assign o_dane_pre_re = (licznik[ROT_BIT] == 1'b0) ? bufor_re[BUFOR_N-1] : a_re;
assign o_dane_pre_im = (licznik[ROT_BIT] == 1'b0) ? bufor_im[BUFOR_N-1] : a_im;

// --- wybor indeksu TF ---
logic [$clog2(FFT_N)-1:0] n_idx;
assign n_idx = licznik & ((1 << ROT_BIT) - 1);

logic [$clog2(FFT_N)-1:0] raw_idx;
always_comb begin
  case (phase)
    2'b11: raw_idx = 0;
    2'b00: raw_idx = 2 * n_idx * KROK;
    2'b01: raw_idx = 1 * n_idx * KROK;
    2'b10: raw_idx = 3 * n_idx * KROK;
  endcase
end

logic invert_w;
logic [$clog2(FFT_N)-1:0] real_idx;
assign invert_w = (raw_idx >= (FFT_N/2));
assign real_idx = invert_w ? (raw_idx - (FFT_N/2)) : raw_idx;

logic signed [W_N-1:0] w_re, w_im;
always_comb begin
  if (raw_idx == 0) begin
    w_re = (2**(W_N-1)) - 1;
    w_im = '0;
  end else begin
    w_re = invert_w ? -W_RE_ROM[real_idx] : W_RE_ROM[real_idx];
    w_im = invert_w ? -W_IM_ROM[real_idx] : W_IM_ROM[real_idx];
  end
end

// --- multipleksowany uklad DSP na wyjsciu ---
logic [$clog2(KODEK_BCLK_Hz/F_PROBKOWANIA_Hz)-1:0] licznik_mux;
always_ff @(posedge i_clk or posedge i_rst) begin
  if (i_rst) licznik_mux <= '0;
  else       licznik_mux <= licznik_mux + 1'b1;
end

logic signed [N-1:0]       dsp_a;
logic signed [W_N-1:0]     dsp_b;
logic signed [(N+W_N)-1:0] dsp_wynik;
logic signed [(N+W_N)-1:0] mnozenie_0, mnozenie_1, mnozenie_2, mnozenie_3;

always_comb begin
  dsp_a = '0;
  dsp_b = '0;
  case (licznik_mux[$high(licznik_mux):$high(licznik_mux)-1])
    2'd0: begin dsp_a = o_dane_pre_re; dsp_b = w_re; end
    2'd1: begin dsp_a = o_dane_pre_im; dsp_b = w_im; end
    2'd2: begin dsp_a = o_dane_pre_re; dsp_b = w_im; end
    2'd3: begin dsp_a = o_dane_pre_im; dsp_b = w_re; end
  endcase
end

assign dsp_wynik = dsp_a * dsp_b;

always_ff @(posedge i_clk) begin
  case (licznik_mux[$high(licznik_mux):$high(licznik_mux)-1])
    2'd0: mnozenie_0 <= dsp_wynik;
    2'd1: mnozenie_1 <= dsp_wynik;
    2'd2: mnozenie_2 <= dsp_wynik;
    2'd3: mnozenie_3 <= dsp_wynik;
  endcase
end

// -- przypisanie danych na wyjsciu
logic signed [N-1:0] o_dane_re_mult, o_dane_im_mult;
assign o_dane_re_mult = mnozenie_0[$high(mnozenie_0)-1:$high(mnozenie_0)-N] -
                        mnozenie_1[$high(mnozenie_1)-1:$high(mnozenie_1)-N];
assign o_dane_im_mult = mnozenie_2[$high(mnozenie_2)-1:$high(mnozenie_2)-N] +
                        mnozenie_3[$high(mnozenie_3)-1:$high(mnozenie_3)-N];

// ominiecie sprzetowego mnozenia dla fazy 11
assign o_dane_re = (phase == 2'b11) ? o_dane_pre_re : o_dane_re_mult;
assign o_dane_im = (phase == 2'b11) ? o_dane_pre_im : o_dane_im_mult;

endmodule // FFT_WARSTWA_DIF_R22_ZLOZONA



////////////////////////////////////////////////////////////////////////////////
// Engineer:        Dominik Majak
//
// Design Name:     PRACA_MAGISTERSKA_SV
// Module Name:     FFT_WARSTWA_DIF_R22_TRYWIALNA
// Target Devices:  ZYBO - ZYNQ XC7Z010
// Tool Versions:   Vivado 2024.2
// Description:
//                  Jednostka wykorzysuje algorytm R22 do implementacji
//                  operacji motylkowych. Jest to jednostka wykonująca
//                  operacje trywialne.
//////////////////////////////////////////////////////////////////////////////////

module FFT_WARSTWA_DIF_R22_TRYWIALNA #(
parameter BUFOR_N = 128,
parameter N       = 16
)(
input  logic                i_rst,
input  logic                i_clk_fs,
input  logic signed [N-1:0] i_dane_re,
input  logic signed [N-1:0] i_dane_im,
output logic signed [N-1:0] o_dane_re,
output logic signed [N-1:0] o_dane_im
);

typedef logic signed [N-1:0] t_bufor [0:BUFOR_N-1];
t_bufor bufor_re, bufor_im;

logic [$clog2(BUFOR_N):0] licznik;
logic signed [N:0]  suma_re, suma_im, roznica_re, roznica_im;
logic signed [N-1:0] a_re, a_im, b_re, b_im;
logic signed [N-1:0] i_bufor_re, i_bufor_im;

always_ff @(posedge i_clk_fs or posedge i_rst) begin
  if (i_rst) licznik <= '0;
  else       licznik <= licznik + 1'b1;
end

always_ff @(posedge i_clk_fs) begin
  bufor_re[0] <= i_bufor_re;
  bufor_im[0] <= i_bufor_im;
  for (int i = 1; i < BUFOR_N; i++) begin
    bufor_re[i] <= bufor_re[i-1];
    bufor_im[i] <= bufor_im[i-1];
  end
end

always_comb begin
  suma_re    = bufor_re[BUFOR_N-1] + i_dane_re;
  suma_im    = bufor_im[BUFOR_N-1] + i_dane_im;
  roznica_re = bufor_re[BUFOR_N-1] - i_dane_re;
  roznica_im = bufor_im[BUFOR_N-1] - i_dane_im;
end

assign a_re = suma_re[N:1];
assign a_im = suma_im[N:1];
assign b_re = roznica_re[N:1];
assign b_im = roznica_im[N:1];

assign i_bufor_re = (licznik[$clog2(BUFOR_N)] == 1'b0) ? i_dane_re : b_re;
assign i_bufor_im = (licznik[$clog2(BUFOR_N)] == 1'b0) ? i_dane_im : b_im;

assign o_dane_re = (licznik[$clog2(BUFOR_N)] == 1'b0) ? bufor_re[BUFOR_N-1] : a_re;
assign o_dane_im = (licznik[$clog2(BUFOR_N)] == 1'b0) ? bufor_im[BUFOR_N-1] : a_im;

endmodule // FFT_WARSTWA_DIF_R22_TRYWIALNA
