# Interfacing Control Systems and Embedded Systems

**Repository link:** https://github.com/alammahir1/interfacing-control-embedded


---

## 1. Introduction

This repository contains the firmware and analysis code developed for the third-year individual project *Interfacing Control Systems and Embedded Systems* (EEEN30330, University of Manchester, 2026). The project develops two complementary control frameworks that bridge analytical control theory and discrete-time embedded execution on the ESP32 microcontroller, applied to two physical plants of contrasting dynamic character.

The first framework targets a **series RLC circuit**, a fast (millisecond-timescale) plant whose transfer function is derivable analytically from component values. The framework comprises a 15-point AC frequency sweep used to validate the analytical model against measurement, and a discrete-time PID controller running at 50 Hz that regulates the capacitor voltage to a fixed setpoint with EMA filtering on the feedback path and clamp-based anti-windup on the integrator.

The second framework targets a **fan-heatsink thermal assembly**, a slow (multi-second-timescale) plant whose model cannot be derived analytically and must be discovered from data. The framework comprises step-response experiments at nine fan operating points spanning 3 V to 11 V, a MATLAB acquisition pipeline that streams data over USB serial and resamples onto a uniform 6-second grid, a Monte Carlo random search over 50,000 candidates per operating point that fits second-order overdamped models, and an integrator-with-dead-time (IPDT) reduction that yields a discrete-time control law suitable for embedded execution.

Together, the two frameworks demonstrate how the same engineering goal — practical, stable embedded control — is achieved through methods that must be matched to the plant's timescale and structural complexity.

---

## 2. Hardware Diagrams

### 2.1 RLC circuit

```
                     +-------+      +-------+      +-------+
   GPIO 25 (DAC) -->|   R   |---->|   L   |---->|   C   |---> GND
                     +-------+      +-------+      +-------+
        |                                            |
        +-- GPIO 34 (ADC, V_pos read-back)            +-- GPIO 32 (ADC, V_C measured)

   GPIO 26 (DAC, inverted) -- GPIO 35 (ADC, V_neg read-back)
```

**Component values:**
- R_ext = 47 Ω (external resistor)
- R_ind = 18 Ω (inductor parasitic resistance)
- R_total = 65 Ω
- L = 30 mH
- C = 3 µF

### 2.2 Fan-heatsink thermal assembly

```
                  +-----------+
                  |    FAN    |   (driven by bench DC supply, 3–11 V)
                  +-----------+
                       ↓ airflow
                  ┌───────────┐
                  │  HEATSINK │   (aluminium, finned)
                  │   ┌LM335┐ │   (temperature sensor at base)
                  └───┴──┬──┴─┘
                         │
                  GPIO 34 (ADC) on ESP32 ──── USB ──── Host PC (MATLAB)
```

The heatsink is pre-heated using a handheld heat gun before each step experiment because the available bench DC supplies could not deliver the 6 W needed to drive the integrated heating resistor of the assembly directly. The procedural variability this introduces is documented in the project final report (Section 4.3.3).

---

## 3. User Installation Instructions

### Prerequisites

Both frameworks share the same toolchain. Install once and you are ready to run either.

1. **Arduino IDE** (version 2.x recommended). Download from https://www.arduino.cc/en/software.
2. **ESP32 board package** for the Arduino IDE. Inside the IDE, go to *File → Preferences*, paste `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json` into the *Additional Boards Manager URLs* field, then go to *Tools → Board → Boards Manager* and install **esp32** by Espressif Systems.
3. **MATLAB R2020b or newer**, with the Control System Toolbox (required for the `tf` and `step` functions used in the Monte Carlo identifier).

### Hardware setup — RLC framework

1. Wire the RLC circuit on a breadboard with the component values listed in Section 2.1.
2. Connect ESP32 pins as shown: GPIO 25 (DAC drive), GPIO 26 (DAC inverted drive), GPIO 32 (ADC, capacitor voltage), GPIO 34 / GPIO 35 (ADC, drive read-back).
3. Connect the ESP32 to your PC via USB.

### Hardware setup — Thermal framework

1. Mount the LM335 temperature sensor at the base of the heatsink. Wire its output to ESP32 GPIO 34.
2. Connect the fan supply pins to a regulated bench DC supply.
3. Have a handheld heat gun available for pre-heating the heatsink.
4. Connect the ESP32 to your host PC via USB.

### Cloning this repository

Open a terminal and run:

```
git clone https://github.com/alammahir1/interfacing-control-embedded.git
cd interfacing-control-embedded
```

---

## 4. How to Run the Code

The repository is organised into two top-level folders, `rlc/` and `thermal/`, each containing the firmware and host-side scripts for that framework.

### 4.1 RLC framework

Four runnable items, executed in order during the project:

**4.1.1 Generate theoretical AC sweep reference (MATLAB).** Run `rlc/matlab/theoretical_sweep.m`. This evaluates H(s) = 1/(LCs² + R_total·C·s + 1) at the 15 sweep frequencies and exports gain and phase to `theoretical_results.csv` for later comparison.

**4.1.2 Run the physical AC sweep (ESP32 firmware).** Open `rlc/ac_sweep/ac_sweep.ino` in the Arduino IDE. Set the target frequency `Hz` at the top (e.g. `int Hz = 530;`), then upload to the ESP32. Open the Serial Plotter at 115200 baud — the firmware prints the differential drive voltage and capacitor voltage at each step of the synthesised sinusoid. Capture peak-to-peak values from a digital oscilloscope on the capacitor pin for the most accurate gain measurement, and repeat for each of the 15 sweep frequencies.

**4.1.3 Open-loop step response (ESP32 firmware, no PID).** Open `rlc/openloop/openloop.ino` and upload. The firmware drives the input directly to the setpoint voltage and streams the resulting capacitor voltage to serial. Record with `rlc/matlab/log_serial.m` on the host PC.

**4.1.4 Closed-loop PID step response (ESP32 firmware).** Open `rlc/pid_closedloop/pid_closedloop.ino` and upload. This is the main control firmware — it samples the capacitor voltage at 50 Hz, applies an EMA filter, runs the discrete PID law, clamps the integrator for anti-windup, and writes the resulting control voltage back through the DAC. The host script `log_serial.m` records `Target_V, Output_V, Input_V, Timestamp_ms` at 115200 baud for offline plotting.

### 4.2 Thermal framework

Four-stage pipeline, executed in order:

**4.2.1 ESP32 firmware — temperature logging.** Open `thermal/esp32_logger/esp32_logger.ino`. At the top of `loop()` you will find:

```c
fanVoltage = 11;   // change fan voltage here
```

Change this to the operating voltage you are about to test (3, 4, 5, … 11 V). Upload to the ESP32. The firmware samples the ADC 50 times per second-long outer interval and averages, converts the result to °C using the LM335 calibration, and streams `tempC, fanVoltage` over USB serial at 115200 baud. The fan voltage is held at 0 V for the first 10 s after boot to capture a pre-step baseline before the step is applied.

**4.2.2 MATLAB — streaming acquisition.** Run `thermal/matlab/serial_logger.m` on the host PC. Set `port` at the top to your ESP32's COM port. The script timestamps each sample with MATLAB's `tic`/`toc` stopwatch (avoiding any drift between the ESP32's `millis()` counter and the host clock), maintains a live two-panel plot, and exports the dataset to a CSV file when the plot window is closed. Run a fresh acquisition for each operating point (3 V through 11 V), plus one additional run with `fanVoltage = 0` throughout — this is the no-fan baseline. Save each CSV as `fandata_<V>V.csv`.

**4.2.3 MATLAB — resampling onto 6-second grid.** Run `thermal/matlab/resample_to_6s.m` once for each raw CSV. PCHIP-interpolates onto a uniform 6-second grid and writes `fandata_<V>V_6.csv`. PCHIP is preferred over cubic spline (which would overshoot near sharp transitions) and over linear (which loses the smooth concavity of the physical signal).

**4.2.4 MATLAB — Monte Carlo identification.** Run `thermal/matlab/monte_carlo_fit.m` once per operating point, editing the input filename at the top:

```matlab
X1 = csvread("fandata_7V_6.csv");
X  = csvread("fandata_nofan_6.csv");
```

The script performs 50,000 random-sample iterations over K ∈ [0.1, 20], τ₁ ∈ [5, 20], τ₂ ∈ [0.1, 4.0], minimising the sum of squared errors against the measured step response. Best-fit parameters and cost J are printed to the command window, with a comparison plot. Recording the best-fit parameters across all nine operating points produces the per-operating-point gain table used by the IPDT controller.

---

## 5. Technical Details

### 5.1 RLC plant model

Applying Kirchhoff's Voltage Law around the loop with the capacitor voltage taken as output gives:

$$LC \cdot \frac{d^2 V_{out}}{dt^2} + R_{total} \cdot C \cdot \frac{dV_{out}}{dt} + V_{out} = V_{in}$$

Taking the Laplace transform under zero initial conditions:

$$H(s) = \frac{V_{out}(s)}{V_{in}(s)} = \frac{1}{LCs^2 + R_{total} C s + 1}$$

With the component values used: ω_n = 1/√(LC) ≈ 3333 rad/s, f_n ≈ 530.5 Hz, ζ ≈ 0.969 (near-critically damped).

### 5.2 RLC state-space realisation

Choosing x₁ = V_C (capacitor voltage) and x₂ = i_L (inductor current):

$$A = \begin{bmatrix} 0 & 1/C \\ -1/L & -R_{total}/L \end{bmatrix}, \quad B = \begin{bmatrix} 0 \\ 1/L \end{bmatrix}, \quad C = \begin{bmatrix} 1 & 0 \end{bmatrix}, \quad D = \begin{bmatrix} 0 \end{bmatrix}$$

Numerically: A = [0, 333333.33; −33.33, −2167], B = [0; 33.33].

### 5.3 Discrete PID law

The continuous PID law is discretised by backward Euler:

$$u[k] = K_p \cdot e[k] + K_i \cdot T \cdot \sum_{i=0}^{k} e[i] + \frac{K_d}{T}(e[k] - e[k-1])$$

with T = 20 ms (50 Hz loop rate), K_p = 1.2, K_i = 1.5 s⁻¹, K_d = 0. The derivative gain is set to zero because the dominant high-frequency content in the system is ADC quantisation noise (≈ 0.81 mV per LSB at 12-bit, 3.3 V full-scale), and the 1/T factor in the derivative term would amplify it.

### 5.4 EMA filter

The raw ADC reading on each loop iteration is smoothed by a first-order exponential moving average:

$$y_{filtered}[k] = \alpha \cdot y_{raw}[k] + (1 - \alpha) \cdot y_{filtered}[k-1]$$

with α = 0.5, giving a −3 dB cutoff at approximately 8 Hz at the 50 Hz loop rate.

### 5.5 Anti-windup

The integrator accumulator is clamped to the actuator output range [0.0, 3.3] V using `constrain()` after each update. This saturation-based scheme was chosen over back-calculation anti-windup because it requires no additional tuning parameter and is robust given the conservative gain values in use.

### 5.6 Differential push-pull DAC drive

The AC sweep firmware uses both ESP32 DACs in a differential push-pull configuration: GPIO 25 produces V₀ + A·sin(ωt) and GPIO 26 produces V₀ − A·sin(ωt), with V₀ ≈ 0.5 V (DAC code 39) and A ≈ 0.26 V (amplitude of 20 DAC steps). The differential drive doubles the effective swing relative to a single-ended configuration and allows bipolar excitation despite each DAC being unipolar. The centre offset is kept above ≈ 0.1 V because the ESP32 DACs lose linearity below this threshold.

### 5.7 Thermal identification cost function

A second-order overdamped transfer function with two distinct real time constants is fitted at each operating point:

$$G(s) = \frac{K}{(\tau_1 s + 1)(\tau_2 s + 1)}$$

with cost function:

$$J(\theta) = \sum_k \left(y[k] - y_{model}[k; \theta]\right)^2$$

### 5.8 Why Monte Carlo random search

Direct gradient-based optimisation of [K, τ₁, τ₂] is unreliable because the cost surface is non-convex. The two time constants enter the response symmetrically (a permutation symmetry in the loss landscape), and the inverse-response behaviour observed in the raw data gives rise to multiple local minima corresponding to qualitatively different model fits. Random search uses only function evaluations and samples the parameter space globally, sidestepping both pathologies.

### 5.9 IPDT reduction and discrete control law

For controller synthesis, each identified second-order model is approximated as an integrator with dead time:

$$G(s) \approx \frac{K_{int}}{s} \cdot e^{-L_{eff} \cdot s}, \qquad K_{int} = \frac{K}{\tau_1 + \tau_2}$$

For implementation at sampling period T = 6 s with effective dead time expressed as an integer number of sample steps d = ⌊L_eff / T⌋, forward-Euler discretisation gives:

$$y[k + d] = y[k + d - 1] + K_{int} \cdot V[k]$$

The K_int values multiplied by T = 6 s are all order-unity, keeping the recursion numerically well-conditioned. The structure is equivalent to a degenerate Smith Predictor with a pure-integrator inner loop.

### 5.10 Identified parameter table

| Fan (V) | K (°C/V) | τ₁ (s) | τ₂ (s) | Cost J | K_int (°C/V·s) | K_int × T |
|---------|----------|--------|--------|--------|----------------|-----------|
| 3       | 11.077   | 19.649 | 3.949  | 23.66  | 0.563          | 3.378     |
| 4       | 14.019   | 19.329 | 3.973  |  8.20  | 0.7253         | 4.352     |
| 5       |  9.074   | 12.171 | 3.911  |  0.82  | 0.7455         | 4.473     |
| 6       | 12.676   | 13.947 | 3.903  |  6.85  | 0.9088         | 5.453     |
| 7       |  8.927   | 10.047 | 3.926  |  0.87  | 0.8885         | 5.310     |
| 8       | 11.355   |  9.700 | 2.694  |  4.98  | 1.171          | 7.056     |
| 9       |  9.576   |  8.517 | 3.834  |  1.66  | 1.124          | 6.745     |
| 10      | 14.519   |  8.949 | 3.059  | 11.54  | 1.622          | 9.734     |
| 11      | 12.904   |  7.132 | 3.496  | 11.95  | 1.809          | 10.854    |

τ₁ falls monotonically with fan voltage as forced convection becomes more efficient. τ₂ remains in a narrow band (2.7–3.9 s) across the operating range, supporting its physical interpretation as the LM335 thermal lag (independent of fan speed). K varies non-monotonically due to manual heat-gun pre-heating variability.

---

## 6. Repository Layout

```
interfacing-control-embedded/
├── rlc/
│   ├── matlab/
│   │   ├── theoretical_sweep.m       # AC sweep theoretical reference
│   │   └── log_serial.m              # Host-side serial logger
│   ├── ac_sweep/
│   │   └── ac_sweep.ino              # Physical AC sweep firmware
│   ├── openloop/
│   │   └── openloop.ino              # Open-loop step firmware
│   └── pid_closedloop/
│       └── pid_closedloop.ino        # Main PID closed-loop firmware
│
├── thermal/
│   ├── esp32_logger/
│   │   └── esp32_logger.ino          # Temperature streaming firmware
│   └── matlab/
│       ├── serial_logger.m           # Host-side acquisition + live plot
│       ├── resample_to_6s.m          # PCHIP resampling to 6-s grid
│       └── monte_carlo_fit.m         # 50,000-iteration parameter search
│
├── data/                              # Recorded CSV datasets
└── README.md                           # This file
```

---

## 7. Known Issues and Future Improvements

### RLC framework
- **DAC quantisation.** The 8-bit on-board DAC has a 12.9 mV output quantum (3.3 V / 256), which sets a fundamental floor on the achievable steady-state precision. Replacing with an external 12-bit SPI DAC such as the Microchip MCP4922 would reduce this to under 1 mV.
- **Loop rate.** At 50 Hz the loop is in the slow-regulation regime relative to the 530 Hz natural frequency. Increasing to several hundred hertz would let the controller actively track the resonant transient rather than just regulating the slowly-varying mean.
- **DAC slew at high sweep frequencies.** At 5000 Hz the synthesised sinusoid is generated in 100 amplitude steps lasting 2 µs each, approaching the limit of the ESP32's internal DAC settling time. Reading back the actual delivered amplitude on GPIO 34/35 mitigates but does not eliminate this.
- **State-feedback alternative.** Pole-placement or LQR design using the state-space realisation in Section 5.2 is a natural extension and would let direct comparison with PID performance.

### Thermal framework
- **Heat-gun procedural variability.** The bench DC supplies could not deliver the 6 W needed to drive the integrated heating resistor, forcing manual heat-gun pre-heating that produces inconsistent initial temperatures (±5 °C) across runs. Sourcing a higher-current supply (25 V, 3 A) and using the integrated resistor is the single most impactful improvement and would be expected to remove the K scatter entirely.
- **Inverse response not modelled.** The raw step responses exhibit a non-minimum-phase inverse-response transient that the second-order overdamped fit cannot capture (only real left-half-plane poles, no zeros). Extending the Monte Carlo search to include an explicit right-half-plane zero — expanding θ to [K, τ₁, τ₂, z] — would capture this directly.
- **Open-loop simulation only.** The IPDT control law is currently implemented in MATLAB simulation against the identified plant. A natural extension is to deploy it on the ESP32 itself with K_int values stored as a firmware lookup table indexed by commanded fan voltage.

### Cross-cutting
- **Integrated demonstration.** Cascading the two frameworks on a single piece of hardware would showcase the methodology end-to-end: the RLC PID loop regulating the supply voltage to the heatsink fan, with the thermal IPDT loop providing the setpoint to the RLC loop. This represents a natural step toward a deployable thermal-management subsystem of the kind found in compact electronic enclosures.

---

## 8. Citation

If you use this code in academic work, please cite:

> Student ID 11354743, *Interfacing Control Systems and Embedded Systems*, Third-Year Individual Project, Department of Electrical and Electronic Engineering, University of Manchester, April 2026. Supervisor: Dr. Ognjen Marjanović.

---

## 9. Bugs and Feature Requests

Please report any bugs or request features through the GitHub Issue Tracker on this repository.
