//////////////////////////////////////////////////////////////////////////////////
// Engineer:        Dominik Majak
//
// Design Name:     FFT_R2_R22_IP
// Module Name:     DDS
// Target Devices:  Basys 3 - Xilinx Artix XC7A35T
// Tool Versions:   Vivado 2024.2
// Description:
//                  Moduł bezposredniej syntezy cyfrowej do testowania FFT.
//////////////////////////////////////////////////////////////////////////////////

module DDS #(
parameter N = 16,
parameter DDS_LICZBA_PROBEK = 256
)(
input logic i_rst, i_clk,
input logic [31:0] i_krok,
input logic [1:0] i_typ,
input logic signed [10:0] i_wzmocnienie,
output logic signed [N-1:0] o_dane
); // DDS

logic [31:0] r_suma, r_krok;
logic signed [N-1:0] r_dane;
typedef logic signed [N-1:0] sin_rom [0:DDS_LICZBA_PROBEK-1];

logic signed [$high(i_wzmocnienie):0] r_wzmocnienie;
logic signed [N+10:0] r_wynik;

// funkcja do inicjalizacji pamieci ROM sinusa
function sin_rom GEN_DDS_SIN_ROM();
  sin_rom temp_tab; real faza, wartosc; int i;
  for (i = 0; i < DDS_LICZBA_PROBEK; i = i + 1) begin
    faza = 2.0 * 3.14159 * i / DDS_LICZBA_PROBEK;
    wartosc = (2**(N-1)-1) * $sin(faza); // tutaj ustaw amplitude
    temp_tab[i] = $rtoi($floor(wartosc + 0.5));
  end
  return temp_tab;
endfunction

// tablica probek sinusa
parameter sin_rom dds_sin_rom = GEN_DDS_SIN_ROM();

// rejestracja kroku fazy
always_ff @(posedge i_clk) r_krok <= i_krok;

// zwiekszanie akumulatora fazy
always_ff @(posedge i_clk or posedge i_rst)
begin: AFF_DDS_AKUMULATOR_FAZY
  if (i_rst) r_suma <= 'd0;
  else if (i_typ) r_suma <= r_suma + r_krok;
end // AFF_DDS_AKUMULATOR_FAZY

// wybor typu sygnalu
always_ff @(posedge i_clk)
begin: AFF_DDS_PRZELACZ_SYGNAL
  case (i_typ) // typ ustalany w rejestrze P2F
    'd0:     r_dane <= 'd0; // wylaczony
    'd1:     r_dane <= dds_sin_rom[r_suma[31:(31-$clog2(DDS_LICZBA_PROBEK))+1]];
    'd2:     r_dane <= {{8{1'b0}}, r_suma[31:24]};
    default: r_dane <= (r_suma[$high(r_suma)]) ? 2**(N-1)-1 : -(2**(N-1)-1);
  endcase // i_typ
end // AFF_DDS_PRZELACZ_SYGNAL

always_ff @(posedge i_clk) r_wzmocnienie <= i_wzmocnienie;

always_ff @(posedge i_clk)
begin: AFF_DDS_SKALOWANIE
  r_wynik <= r_wzmocnienie * r_dane; // zabezpieczenie przed przekroczeniem zakresu przy wprowadzaniu wartości do i_wzmocnienie
end // AFF_DDS_SKALOWANIE

assign o_dane = r_wynik[$high(r_wynik)-1:$high(r_wynik)-N];

endmodule // DDS
