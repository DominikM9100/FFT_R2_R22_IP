////////////////////////////////////////////////////////////////////////////////
// Engineer:        Dominik Majak
//
// Design Name:     FFT_R2_R22_IP
// Module Name:     FFT_WARSTWA_DIF_R2
// Target Devices:  Basys 3 - Xilinx Artix XC7A35T
// Tool Versions:   Vivado 2024.2
// Description:
//                  Jednostka do wykonywania operacji motylkowej i mnozenia
//                  przez baze Fouriera. Zoptymalizowana do uzycia
//                  pojedynczego bloku DSP poprzez multipleksowanie mnozenia.
//                  Wymaga zegara nadrzednego 12.288 MHz i zagara o częstotliwosci
//                  probkowania 48 kHz.
//////////////////////////////////////////////////////////////////////////////////

module FFT_WARSTWA_DIF_R2 #(
parameter BUFOR_N = 64,
parameter KROK = 128,
parameter N = 16,
parameter W_N = 16,
parameter FFT_N = 256,
parameter KODEK_BCLK_Hz = 12_288_000,
parameter F_PROBKOWANIA_Hz = 48_000
)(
input logic i_rst,
input logic i_clk,
input logic i_clk_fs,
input logic signed [N-1:0] i_dane_re,
input logic signed [N-1:0] i_dane_im,
output logic signed [N-1:0] o_dane_re,
output logic signed [N-1:0] o_dane_im
);

typedef logic signed [W_N-1:0] t_w_rom [0:(FFT_N/2)-1];
// funkcje geneujace baze fouriera
function automatic t_w_rom GEN_W_RE_ROM();
  t_w_rom temp_tab;
  real faza;
  int wartosc;
  int i;
  for (i = 0; i < FFT_N / 2; i = i + 1) begin
    faza = 3.14159 * i / (FFT_N / 2);
    wartosc = (2**(W_N-1) - 1) * $cos(faza);
    temp_tab[i] = $rtoi($floor(wartosc + 0.5));
  end
  return temp_tab;
endfunction
function automatic t_w_rom GEN_W_IM_ROM();
  t_w_rom temp_tab;
  real faza;
  int wartosc;
  int i;
  for (i = 0; i < FFT_N / 2; i = i + 1) begin
    faza = 3.14159 * i / (FFT_N / 2);
    wartosc = - (2**(W_N-1) - 1) * $sin(faza);
    temp_tab[i] = $rtoi($floor(wartosc + 0.5));
  end
  return temp_tab;
endfunction

// inicjalizacja tablic
parameter t_w_rom W_RE_ROM = GEN_W_RE_ROM();
parameter t_w_rom W_IM_ROM = GEN_W_IM_ROM();
// deklaracja buforow probek
typedef logic signed [N-1:0] t_bufor [0:BUFOR_N-1];
t_bufor bufor_re;
t_bufor bufor_im;
// sygnaly wewnetrzne
logic [$clog2(BUFOR_N):0] licznik;
logic signed [N:0] suma_re, suma_im;
logic signed [N:0] roznica_re, roznica_im;
logic signed [N-1:0] a_re, a_im, b_re, b_im;
logic signed [N-1:0] i_bufor_re, i_bufor_im;
logic signed [W_N-1:0] w_re, w_im;
logic signed [(N+W_N)-1:0] mnozenie_0, mnozenie_1;
logic signed [(N+W_N)-1:0] mnozenie_2, mnozenie_3;
logic signed [N-1:0] d_re, d_im;
logic [$clog2(KODEK_BCLK_Hz/F_PROBKOWANIA_Hz)-1:0] licznik_mux;
logic signed [N-1:0] dsp_a;
logic signed [W_N-1:0] dsp_b;
logic signed [(N+W_N)-1:0] dsp_wynik;

// glowny licznik warstwy
always_ff @(posedge i_clk_fs or posedge i_rst)
begin: AFF_DSP_WARSTWA_DIF_LICZNIK
  if (i_rst) licznik <= 'd0;
  else       licznik <= licznik + 'd1;
end // AFF_DSP_WARSTWA_DIF_LICZNIK

// licznik sterujacy multiplekserem wynikow mnozenia
always_ff @(posedge i_clk or posedge i_rst)
begin: AFF_DSP_WARSTWA_DIF_LICZNIK_MNOZENIE
  if (i_rst) licznik_mux <= 'd0;
  else       licznik_mux <= licznik_mux + 'd1;
end // AFF_DSP_WARSTWA_DIF_LICZNIK_MNOZENIE

always_ff @(posedge i_clk_fs) begin
  bufor_re[0] <= i_bufor_re;
  bufor_im[0] <= i_bufor_im;
  for (int i = 1; i < BUFOR_N; i = i + 1) begin
    bufor_re[i] <= bufor_re[i-1];
    bufor_im[i] <= bufor_im[i-1];
  end
end

// odczyt wspolczynnikow bazy fouriera
always_comb
begin: ACOMB_DSP_WARSTWA_DIF_WSPOLCZYNNIKI
  if (licznik[$high(licznik)] == 'b1) begin
    w_re = W_RE_ROM[(licznik - BUFOR_N) * KROK];
    w_im = W_IM_ROM[(licznik - BUFOR_N) * KROK];
  end else begin
    w_re = (2**(W_N-1)) - 1;
    w_im = 'd0;
  end
end // ACOMB_DSP_WARSTWA_DIF_WSPOLCZYNNIKI

always_comb begin: ACOMB_DODAWANIE_0
  suma_re = bufor_re[BUFOR_N-1] + i_dane_re;
end // ACOMB_DODAWANIE_0

always_comb begin: ACOMB_DODAWANIE_1
  suma_im = bufor_im[BUFOR_N-1] + i_dane_im;
end // ACOMB_DODAWANIE_1

always_comb begin: ACOMB_ODEJMOWANIE_0
  roznica_re = bufor_re[BUFOR_N-1] - i_dane_re;
end // ACOMB_ODEJMOWANIE_0

always_comb begin: ACOMB_ODEJMOWANIE_1
  roznica_im = bufor_im[BUFOR_N-1] - i_dane_im;
end // ACOMB_ODEJMOWANIE_1

// przesuniecie realizowane jako wybor bitow - skalowanie
assign a_re = suma_re[N:1];
assign a_im = suma_im[N:1];
assign b_re = roznica_re[N:1];
assign b_im = roznica_im[N:1];

// multipleksowanie sygnalow na wejsciu do ukladu mnozacego
always_comb
begin: ACOMB_DSP_WARSTWA_MUX
  dsp_a = 'd0;
  dsp_b = 'd0;
  case (licznik_mux[$high(licznik_mux):$high(licznik_mux)-1])
    'd0: begin dsp_a = b_re; dsp_b = w_re; end
    'd1: begin dsp_a = b_im; dsp_b = w_im; end
    'd2: begin dsp_a = b_re; dsp_b = w_im; end
    'd3: begin dsp_a = b_im; dsp_b = w_re; end
  endcase // licznik_mux[$high(licznik_mux):$high(licznik_mux)-1]
end // ACOMB_DSP_WARSTWA_MUX

always_comb begin: ACOMB_MNOZENIE
  dsp_wynik = dsp_a * dsp_b;
end // ACOMB_MNOZENIE

// zapis wynikow mnozenia w odpowiednich rejestrach
always_ff @(posedge i_clk)
begin: AFF_DSP_WARSTWA_DIF_WYNIK_MNOZENIA
  case (licznik_mux[$high(licznik_mux):$high(licznik_mux)-1])
    'd0: mnozenie_0 <= dsp_wynik;
    'd1: mnozenie_1 <= dsp_wynik;
    'd2: mnozenie_2 <= dsp_wynik;
    'd3: mnozenie_3 <= dsp_wynik;
  endcase // licznik_mux[$high(licznik_mux):$high(licznik_mux)-1]
end // AFF_DSP_WARSTWA_DIF_WYNIK_MNOZENIA

always_comb begin: ACOMB_ODEJMOWANIE_2
  d_re = mnozenie_0[$high(mnozenie_0)-1:$high(mnozenie_0)-N] -
         mnozenie_1[$high(mnozenie_1)-1:$high(mnozenie_1)-N];
end // ACOMB_ODEJMOWANIE_2

always_comb begin: ACOMB_DODAWANIE_2
  d_im = mnozenie_2[$high(mnozenie_2)-1:$high(mnozenie_2)-N] +
         mnozenie_3[$high(mnozenie_3)-1:$high(mnozenie_3)-N];
end // ACOMB_DODAWANIE_2

// ladowanie danych do bufora probek
assign i_bufor_re = (licznik[$high(licznik)] == 'b0) ? i_dane_re : d_re;
assign i_bufor_im = (licznik[$high(licznik)] == 'b0) ? i_dane_im : d_im;

// przypisanie danych wyjsciowych
assign o_dane_re = (licznik[$high(licznik)] == 'b0) ? bufor_re[BUFOR_N-1] : a_re;
assign o_dane_im = (licznik[$high(licznik)] == 'b0) ? bufor_im[BUFOR_N-1] : a_im;

endmodule // FFT_WARSTWA_DIF_R2
