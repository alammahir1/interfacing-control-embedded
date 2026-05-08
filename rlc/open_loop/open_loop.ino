const int Vin = 25;  
const int Vout = 34; 
const int Vinmeasured = 35;

double target_voltage = 1; // Target voltage 

unsigned long last_time = 0;
double sample_time_ms = 20; // 20ms sample time (50 Hz)
double sample_time_sec = sample_time_ms / 1000.0;

void setup() {
  Serial.begin(115200);
  Serial.println("RLC Circuit");

  analogReadResolution(12); // Set resolution to 12 bits (0-4095)
  // Set attenuation to 11dB. This maps the ADC input range
  // to ~0-3.3V, which matches our DAC output.
  analogSetPinAttenuation(Vout, ADC_11db);

  
  
  Serial.println("ESP32 ready. Sending data to MATLAB...");
  Serial.println("Target_V,Output_V,Timestamp_ms"); // Header row
  last_time = millis(); //last sample time

  int dac_value = (1.0 / 3.3) * 255;
  dacWrite(Vin, dac_value);
}

void loop() {

  unsigned long current_time = millis();
  if (current_time - last_time < sample_time_ms) { // Wait sample time
    return; 
  }
  double delta_time_sec = (current_time - last_time) / 1000.0;
  last_time = current_time;

  int adc_value = analogRead(Vout); //sensor inpu
  double currentunf_voltage = (adc_value / 4095.0) * 3.3; //convert ADC vlaue with 3.3 as max
