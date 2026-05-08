// Pins
const int tempPin = 34;

unsigned long startTime;
unsigned long lastSampleTime = 0;
const int sampleInterval = 1000; // 1 second

void setup() {
  Serial.begin(115200);
  delay(5000); // Short delay to open Serial Monitor
  
  startTime = millis();
}

void loop() {
  unsigned long currentTime = millis();

  // Check if 1 second has passed
  if (currentTime - lastSampleTime >= sampleInterval) {
    lastSampleTime = currentTime;

    // --- 1. Averaging Logic ---
    int numSamples = 50;
    long sumADC = 0;
    for(int i = 0; i < numSamples; i++) {
      sumADC += analogRead(tempPin);
      delay(2); // Tiny delay between samples for stability
    }
    float averageADC = (float)sumADC / numSamples;

    // --- 2. Conversion ---
    float voltage = averageADC * (3.3 / 4095.0);
    // Note: Ensure this formula matches your sensor (e.g., LM35, TMP36, etc.)
    float tempC = (voltage * 100.0) - 273.0; 

    // --- 3. Fan Voltage Logic ---
    float fanVoltage = 0;
    // 10 seconds after boot, turn on fan
    if (currentTime - startTime >= 10000) {
      fanVoltage = 11;           //change fan voltage here
    } else {
      fanVoltage = 0;
    }

    // --- 4. Output for MATLAB ---
    Serial.print(tempC);
    Serial.print(",");
    Serial.println(fanVoltage);
  }
}
