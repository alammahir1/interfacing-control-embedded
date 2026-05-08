% ---------------------------------------------------------
% THEORETICAL GAIN GENERATOR (Exact Frequency Steps)
% ---------------------------------------------------------
clear; clc;

% 1. DEFINE SPECIFIC COMPONENT VALUES
% ---------------------------------------------------------
R_ext = 110;             % Resistor (Ohms)
R_ind = 84;              % Inductor Internal Resistance (Ohms)
R_total = R_ext + R_ind; % Total Resistance (194 Ohms)

% DECODING LABELS
% Capacitor "105" = 10 * 10^5 pF = 1,000,000 pF = 1 uF
C = 3.0 * 10^-6; 

% Inductor "106" = 10 * 10^6 nH = 10,000,000 nH = 10 mH
L = 30 * 10^-3;  

% 2. DEFINE FREQUENCY STEPS (Your Practical Values)
% ---------------------------------------------------------
% These match the table you provided earlier exactly
freq_hz = [100; 300; 400; 450; 480; 500; 520; 530; 540; 560; 600; 700; 1000; 2000; 5000];

% Convert to Angular Frequency (Rad/s)
w = freq_hz * 2 * pi;

% 3. CALCULATE THEORETICAL RESPONSE
% ---------------------------------------------------------
% Transfer Function H(jw) for Series RLC (Output across Capacitor)
% H = 1 / ( (1 - w^2*L*C) + j(w*R_total*C) )

numerator = 1;
term_real = (1 - (w.^2 .* L .* C));
term_imag = (1j .* w .* R_total .* C);
denominator = term_real + term_imag;

H = numerator ./ denominator;

% 4. EXTRACT RESULTS
% ---------------------------------------------------------
Gain_Linear = abs(H);               % Magnitude (Vout/Vin)
Phase_Degrees = angle(H) * (180/pi); % Phase in Degrees

% 5. EXPORT TO CSV
% ---------------------------------------------------------
results_table = table(freq_hz, Gain_Linear, Phase_Degrees, ...
    'VariableNames', {'Frequency_Hz', 'Theoretical_Gain', 'Theoretical_Phase_Deg'});

filename = 'theoretical_results_105_106.csv';
writetable(results_table, filename);

% 6. DISPLAY SUMMARY
fprintf('---------------------------------------------------\n');
fprintf('Calculated L (from 106 label): %.3f H (10 mH)\n', L);
fprintf('Calculated C (from 105 label): %.6f F (1 uF)\n', C);
fprintf('Total Resistance: %.1f Ohms\n', R_total);
fprintf('Theoretical Resonance: %.1f Hz\n', 1/(2*pi*sqrt(L*C)));
fprintf('---------------------------------------------------\n');
fprintf('Data saved to "%s"\n', filename);
disp(results_table);
