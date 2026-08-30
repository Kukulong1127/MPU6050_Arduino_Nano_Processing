#include <Wire.h>

const int MPU_ADDR = 0x68;

int16_t gyroX_raw, gyroY_raw, gyroZ_raw;
float gyroX, gyroY, gyroZ;

void setup() {
  Serial.begin(115200);
  Wire.begin();

  // Wake up MPU6050
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x6B);
  Wire.write(0x00);
  Wire.endTransmission();

  // Set gyroscope range to ±250 deg/s
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x1B);
  Wire.write(0x00);
  Wire.endTransmission();

  delay(1000);
}

void loop() {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x43); // Gyro data start register
  Wire.endTransmission(false);

  Wire.requestFrom(MPU_ADDR, 6, true);

  gyroX_raw = Wire.read() << 8 | Wire.read();
  gyroY_raw = Wire.read() << 8 | Wire.read();
  gyroZ_raw = Wire.read() << 8 | Wire.read();

  // Convert to deg/s
  gyroX = gyroX_raw / 131.0;
  gyroY = gyroY_raw / 131.0;
  gyroZ = gyroZ_raw / 131.0;

  // Send data to Processing
  Serial.print(gyroX);
  Serial.print(",");
  Serial.print(gyroY);
  Serial.print(",");
  Serial.println(gyroZ);

  delay(10);
}