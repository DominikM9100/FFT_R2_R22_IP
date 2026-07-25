W projekcie porównano opracowaną implementację FFT z komercyjnym modułem IP Core FFT firmy AMD. Zaproponowane rozwiązanie dobrze sprawdza się w przypadku przetwarzania sygnałów o niskiej częstotliwości, np. sygnałów audio. W projekcie wprowadzono optymalizację polegającą na zredukowaniu liczby bloków DSP potrzebnych do wykonywania operacji mnożenia zespolonego. Osiągnięto to poprzez sekwencyjne przełączanie odpowiednich par części rzeczywistych i urojonych mnożonych ze sobą liczb zespolonych.

Zużycie zasobów sprzętowych dla 64-punktowej FFT przedstawiono poniżej. Wyróżnione wiersze odpowiadają następującym implementacjom: I_IP_CORE_FFT – IP Core FFT firmy AMD, I_R2 – opracowana FFT o podstawie Radix-2, I_R22 – opracowana FFT o podstawie Radix-2².

![image alt](https://github.com/DominikM9100/FFT_R2_R22_IP/blob/eb529aadadceef9ad770e7099a3a73269e8064e8/images/1.png)

Zestawienie dla 256-punktowej FFT:

![image alt](https://github.com/DominikM9100/FFT_R2_R22_IP/blob/eb529aadadceef9ad770e7099a3a73269e8064e8/images/2.png)

Opracowana jednostka FFT opiera się na architekturze potokowej SDF, której działanie przedstawia poniższy rysunek:

![image alt](https://github.com/DominikM9100/FFT_R2_R22_IP/blob/eb529aadadceef9ad770e7099a3a73269e8064e8/images/3.png)

Poprawność działania sprawdzono z wykorzystaniem wbudowanego w układ FPGA modułu debugowania ILA. Analizie FFT poddano sygnał sinusoidalny o częstotliwości 8 kHz, wygenerowany w module DDS wewnątrz układu FPGA.

![image alt](https://github.com/DominikM9100/FFT_R2_R22_IP/blob/eb529aadadceef9ad770e7099a3a73269e8064e8/images/4.png)

Częstotliwość próbkowania FFT wynosiła w tym przypadku 48 kHz. Przy 64-punktowej transformacie rozdzielczość częstotliwościowa wynosiła 750 Hz, co potwierdza obecność jedenastego prążka. Dodatkowo przetestowano sygnał prostokątny o częstotliwości 3 kHz:

![image alt](https://github.com/DominikM9100/FFT_R2_R22_IP/blob/eb529aadadceef9ad770e7099a3a73269e8064e8/images/5.png)

Działanie projektu zweryfikowano również w środowisku Vivado z wykorzystaniem dedykowanego pliku testowego (ang. testbench). Kolorem czerwonym oznaczono IP Core FFT firmy AMD, a kolorem zielonym opracowane implementacje. Zastosowano również odwróconą kolejność bitów (ang. bit-reversal):

![image alt](https://github.com/DominikM9100/FFT_R2_R22_IP/blob/eb529aadadceef9ad770e7099a3a73269e8064e8/images/6.png)

Obliczone wartości wypisane w oknie konsoli:

![image alt](https://github.com/DominikM9100/FFT_R2_R22_IP/blob/eb529aadadceef9ad770e7099a3a73269e8064e8/images/7.png)
