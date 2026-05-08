#include <math.h>

// DAC PINS (Must be 25 and 26)
int pinPos = 25; 
int pinNeg = 26; 

// ADC PINS (To measure the result)
const int adcPos = 34; // Connect to Pin 25
const int adcNeg = 35; // Connect to Pin 26
const int adcCap = 32; // Connect to Eo Capacitor

// Settings
int Hz = 100; 
const int steps = 100;
int stepDelay = 1000000 / (Hz * steps);

void setup() {
  Serial.begin(115200);
}

void loop() {
  for(int i = 0; i < steps; i++) {
    
    float angle = (2.0 * PI * i) / steps;

    // --- AMPLITUDE SETTING ---
    // Amplitude of 20 steps (approx 0.25V swing per pin)
    int amplitudeSteps = 20; 

    // Center point is step 39 (approx 0.5V)
    // Note: ESP32 DACs struggle below 0.1V, so keep center > 20
    int valPos = 39 + (amplitudeSteps * sin(angle));
    int valNeg = 39 - (amplitudeSteps * sin(angle)); 

    // --- FIX 1: REMOVED DIRECTION SWAPPING ---
    // Always write the standard sine to Pos and inverted to Neg
    dacWrite(pinPos, valPos);
    dacWrite(pinNeg, valNeg); 

    // Read Voltages
    float vPos = (analogRead(adcPos) * 3.3) / 4095.0;
    
    // --- FIX 2: UNCOMMENTED THE NEGATIVE READ ---
    // You must read both to calculate the real difference
    float vNeg = (analogRead(adcNeg) * 3.3) / 4095.0;
    float vCap = (analogRead(adcCap) * 3.3) / 4095.0;
    
    // Calculate the Voltage ACROSS the circuit
    float diffVoltage = vPos - vNeg;
    float diffCapVoltage = vCap - 0.5;

    // Print for Serial Plotter
    Serial.print("Voltage_Difference:");
    Serial.println(diffVoltage); 
    Serial.print("Capacitor_Voltage:");
    Serial.println(diffCapVoltage);
    // You can also plot raw values to debug:
    // Serial.print(" vPos:"); Serial.print(vPos);
    // Serial.print(" vNeg:"); Serial.println(vNeg);

    delayMicroseconds(stepDelay);
  }
}
