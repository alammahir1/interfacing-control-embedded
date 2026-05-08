const int Vin = 25;  
const int Vout = 34; 
const int Vinmeasured = 35;

//PID Parameters 
double Kp = 1.2; 
double Ki = 1.5;  
double Kd = 0.0;  

//Controller Setpoint 
double target_voltage = 1; // Target voltage 
double error;

double integral_sum = 0.0;
double last_error = 0.0;
unsigned long last_time = 0;
double sample_time_ms = 20; // 20ms sample time (50 Hz)
double sample_time_sec = sample_time_ms / 1000.0;

void setup() {
  Serial.begin(115200);
  Serial.println("PID Controller for an RLC Circuit");

  analogReadResolution(12); // Set resolution to 12 bits (0-4095)
  // Set attenuation to 11dB. This maps the ADC input range
  // to ~0-3.3V, which matches our DAC output.
  analogSetPinAttenuation(Vout, ADC_11db);

  
  
  Serial.println("ESP32 ready. Sending data to MATLAB...");
  Serial.println("Target_V,Output_V,Timestamp_ms"); // Header row
  last_time = millis(); //last sample time
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
  double alpha = 0.5;
  double current_voltage = alpha * currentunf_voltage + (1.0 - alpha) * current_voltage;
  error = target_voltage - current_voltage;

  int oadc_value = analogRead(Vinmeasured); //sensor inpu
  double ocurrentunf_voltage = (oadc_value / 4095.0) * 3.3; //convert ADC vlaue with 3.3 as max
  double oalpha = 0.5;
  double currentout_voltage = oalpha * ocurrentunf_voltage + (1.0 - oalpha) * currentout_voltage;

//PID >>>>

  // P
  double P_term = Kp * error;

  // Integral

  integral_sum = integral_sum + (Ki * error * delta_time_sec);
  
  // Anti-Windup with max limit 3.3V
  integral_sum = constrain(integral_sum, 0.0, 3.3); 
  double I_term = integral_sum;

  // D
  double error_derivative = (error - last_error) / delta_time_sec;
  double D_term = Kd * error_derivative;

  //Output
  double pid_output = P_term + I_term + D_term;

  //Output Limit
  pid_output = constrain(pid_output, 0.0, 3.3);

  //Convert to DAC and push output
  int dac_value = (pid_output / 3.3) * 255;
  dacWrite(Vin, dac_value);

  //record last error for Kp
  last_error = error;

  //Print for MATLAB >>> 
  //if(current_time<2000){
    // Format: "Target_V,Output_V,Timestamp_ms"
  Serial.print(target_voltage, 4); // Print with 4 decimal places
  Serial.print(",");
  Serial.print(current_voltage, 4);
  Serial.print(",");
  Serial.print(currentout_voltage, 4);
  Serial.print(",");
  Serial.println(current_time);
 // }
  
  
}
