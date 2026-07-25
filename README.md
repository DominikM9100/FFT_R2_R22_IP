W projekcie porównano opracowaną implementację FFT z komercyjnym modułem IP Core FFT firmy AMD. Zaproponowane rozwiązanie dobrze sprawdza się w przypadku przetwarzania sygnałów o niskiej częstotliwości, np. sygnałów audio. W projekcie wprowadzono optymalizację polegającą na zredukowaniu liczby bloków DSP potrzebnych do wykonywania operacji mnożenia zespolonego. Osiągnięto to poprzez sekwencyjne przełączanie odpowiednich par części rzeczywistych i urojonych mnożonych ze sobą liczb zespolonych.

Zużycie zasobów sprzętowych dla 64-punktowej FFT przedstawiono poniżej. Wyróżnione wiersze odpowiadają następującym implementacjom: I_IP_CORE_FFT – IP Core FFT firmy AMD, I_R2 – opracowana FFT o podstawie Radix-2, I_R22 – opracowana FFT o podstawie Radix-2².

[1]

Zestawienie dla 256-punktowej FFT:

[2]

Opracowana jednostka FFT opiera się na architekturze potokowej SDF, której działanie przedstawia poniższy rysunek:

[3]

Poprawność działania sprawdzono z wykorzystaniem wbudowanego w układ FPGA modułu debugowania ILA. Analizie FFT poddano sygnał sinusoidalny o częstotliwości 8 kHz, wygenerowany w module DDS wewnątrz układu FPGA.

[4]

Częstotliwość próbkowania FFT wynosiła w tym przypadku 48 kHz. Przy 64-punktowej transformacie rozdzielczość częstotliwościowa wynosiła 750 Hz, co potwierdza obecność jedenastego prążka. Dodatkowo przetestowano sygnał prostokątny o częstotliwości 3 kHz:

[5]

Działanie projektu zweryfikowano również w środowisku Vivado z wykorzystaniem dedykowanego pliku testowego (ang. testbench). Kolorem czerwonym oznaczono IP Core FFT firmy AMD, a kolorem zielonym opracowane implementacje. Zastosowano również odwróconą kolejność bitów (ang. bit-reversal):

[6]

Obliczone wartości wypisane w oknie konsoli:

[7]

















Projekt przedstawia porównanie opracowanej implementacji FFT w porównaniu do komercyjnego modułu IP Core FFT firmy AMD. Opracowane rozwiązanie sprawdza się w przypadku przetwarzania sygnałów o niskiej częstotliwości np. sygnałów audio. W projekcie wprowadzono optymalizację polegającą na zredukowaniu potrzebnych bloków DSP do wykonywania operacji mnożenia zespolonego poprzez sekwencyjne przełączanie odpowiednich par części rzeczywistych i urojonych mnożonych ze sobą liczb zespolonych.

Zużycie zasobów sprzętowych dla 64-punktowej FFT przedstawione jest poniżej. Zaznaczone wiersze przedstawiają odpowiednie implementacje: I_IP_CORE_FFT - IP Core FFT od AMD, I_R2 - opracowana FFT o podstawie Radix-2, I_R22 - opracowana FFT o podstawie Radix-2^2.


[1]


256-punktowa FFT:


[2]


Opracowana jednostka FFT opiera się o architekturę potokową SDF, której działanie przedstawia poniższy rysunek:


[3]


Poprawność działania została sprawdzona z użyciem modułu debuggowania na układzie FPGA - ILA. Sygnał poddany analizie FFT to sygnał sinusoidalny o częstotliwości 8 kHz wygenerowany w module DDS wewnątrz układu FPGA.


[4]


Częstotliwość próbkowania FFT wynosiła w tym przypadku 48 kHz. Przy 64-punktowej FFT rozdzielczość częstotliwościowa wynosiła 750 Hz, co potwierdza obecność jedenastego prążka. Sprawdzony został jeszcze sygnał prostokątny o częstotliwości 3 kHz:


[5]


Projekt został również sprawdzony w środowisku testowym Vivado z napisanym testbenchem. Kolorem czerwonym został zaznaczony IP Core FFT od AMD, zielonymi zaznaczono opracowane implementacje. Zachowano również kolejność odwróconych bitów (ang. bit-reverse):


[6]


Obliczone wartość wypisane w oknie konsoli:


[7]
