import processing.serial.*;

Serial myPort;

PImage panorama;
PShape sphereView;

// Raw gyro data from Arduino
float gyroX = 0;
float gyroY = 0;
float gyroZ = 0;

// Filtered gyro data
float smoothX = 0;
float smoothY = 0;
float smoothZ = 0;

// Camera orientation
float yaw = 0;
float pitch = 0;

// Timing
int lastTime;

// Filtering parameters
float deadband = 1.0;     // deg/s
float alpha = 0.15;       // EMA smoothing factor

// 0 = raw, 1 = deadband, 2 = deadband + smoothing
int filterMode = 1;

String[] modeNames = {
  "Raw gyro",
  "Deadband",
  "Deadband + smoothing"
};

// Stationary drift test
boolean testRunning = false;
int testStartTime;
float testDuration = 30.0;   // seconds
float testStartYaw = 0;
float testStartPitch = 0;

void setup() {
  size(1000, 700, P3D);

  println(Serial.list());

  // Change this if your Arduino is not Serial.list()[0]
  myPort = new Serial(this, Serial.list()[0], 115200);
  myPort.bufferUntil('\n');

  panorama = loadImage("my_room_lappis.jpg");

  sphereView = createShape(SPHERE, 1000);
  sphereView.setTexture(panorama);
  sphereView.setStroke(false);

  lastTime = millis();

  println("Controls:");
  println("1 = Raw gyro");
  println("2 = Deadband");
  println("3 = Deadband + smoothing");
  println("R = Reset camera");
  println("T = Start stationary drift test");
  println("P = Save screenshot");
}

void draw() {
  background(0);

  int currentTime = millis();
  float dt = (currentTime - lastTime) / 1000.0;
  lastTime = currentTime;

  // Prevent large jumps if the sketch lags
  dt = constrain(dt, 0, 0.05);

  // Apply selected filtering method
  float[] filteredGyro = processGyro(gyroX, gyroY, gyroZ);

  float gx = filteredGyro[0];
  float gy = filteredGyro[1];
  float gz = filteredGyro[2];

  // Map gyro data to camera motion
  // Current mapping:
  // Z-axis gyro controls yaw
  // X-axis gyro controls pitch
  yaw += gz * dt;
  pitch += gx * dt;

  // Avoid camera flipping upside down
  pitch = constrain(pitch, -85, 85);

  drawPanorama();
  drawHUD(gx, gy, gz);
  checkStationaryTest();
}

float[] processGyro(float x, float y, float z) {
  float gx = x;
  float gy = y;
  float gz = z;

  // Mode 1 and 2: apply deadband
  if (filterMode >= 1) {
    gx = applyDeadband(gx);
    gy = applyDeadband(gy);
    gz = applyDeadband(gz);
  }

  // Mode 2: apply exponential moving average smoothing
  if (filterMode == 2) {
    smoothX = alpha * gx + (1 - alpha) * smoothX;
    smoothY = alpha * gy + (1 - alpha) * smoothY;
    smoothZ = alpha * gz + (1 - alpha) * smoothZ;

    gx = smoothX;
    gy = smoothY;
    gz = smoothZ;
  }

  return new float[] {gx, gy, gz};
}

float applyDeadband(float value) {
  if (abs(value) < deadband) {
    return 0;
  } else {
    return value;
  }
}

void drawPanorama() {
  float yawRad = radians(yaw);
  float pitchRad = radians(pitch);

  float lookX = sin(yawRad) * cos(pitchRad);
  float lookY = sin(pitchRad);
  float lookZ = -cos(yawRad) * cos(pitchRad);

  perspective(PI / 3.0, width / float(height), 1, 5000);

  camera(
    0, 0, 0,
    lookX, lookY, lookZ,
    0, 1, 0
  );

  pushMatrix();

  // Flip the sphere so the texture is visible from inside
  scale(-1, 1, 1);

  shape(sphereView);

  popMatrix();
}

void drawHUD(float gx, float gy, float gz) {
  hint(DISABLE_DEPTH_TEST);

  camera();
  resetMatrix();

  noStroke();
  fill(0, 170);
  rect(15, 15, 470, testRunning ? 205 : 175, 8);

  fill(255);
  textAlign(LEFT);
  textSize(16);

  text("Evaluation Mode: " + modeNames[filterMode], 30, 45);

  text("Raw gyro X: " + nf(gyroX, 1, 2) +
       "   Y: " + nf(gyroY, 1, 2) +
       "   Z: " + nf(gyroZ, 1, 2) + " deg/s", 30, 75);

  text("Used gyro X: " + nf(gx, 1, 2) +
       "   Y: " + nf(gy, 1, 2) +
       "   Z: " + nf(gz, 1, 2) + " deg/s", 30, 100);

  text("Yaw: " + nf(yaw, 1, 2) +
       " deg   Pitch: " + nf(pitch, 1, 2) + " deg", 30, 125);

  text("Deadband: " + nf(deadband, 1, 2) +
       " deg/s   Smoothing alpha: " + nf(alpha, 1, 2), 30, 150);

  text("Keys: 1 Raw | 2 Deadband | 3 Smooth | R Reset | T Test | P Screenshot", 30, 175);

  if (testRunning) {
    float elapsed = (millis() - testStartTime) / 1000.0;
    float remaining = max(0, testDuration - elapsed);

    text("Stationary test running. Keep the sensor still.", 30, 200);
    text("Remaining time: " + nf(remaining, 1, 1) + " s", 30, 225);
  }

  hint(ENABLE_DEPTH_TEST);
}

void checkStationaryTest() {
  if (!testRunning) return;

  float elapsed = (millis() - testStartTime) / 1000.0;

  if (elapsed >= testDuration) {
    testRunning = false;

    float yawDrift = abs(angleDifference(yaw, testStartYaw));
    float pitchDrift = abs(pitch - testStartPitch);

    println("====================================");
    println("Stationary Drift Test Result");
    println("Method: " + modeNames[filterMode]);
    println("Duration: " + nf(testDuration, 1, 1) + " s");
    println("Yaw drift: " + nf(yawDrift, 1, 2) + " deg");
    println("Pitch drift: " + nf(pitchDrift, 1, 2) + " deg");
    println("Deadband: " + nf(deadband, 1, 2) + " deg/s");
    println("Smoothing alpha: " + nf(alpha, 1, 2));
    println("====================================");
  }
}

float angleDifference(float a, float b) {
  float diff = a - b;

  while (diff > 180) diff -= 360;
  while (diff < -180) diff += 360;

  return diff;
}

void serialEvent(Serial myPort) {
  String data = myPort.readStringUntil('\n');

  if (data != null) {
    data = trim(data);

    String[] values = split(data, ',');

    if (values.length == 3) {
      gyroX = float(values[0]);
      gyroY = float(values[1]);
      gyroZ = float(values[2]);
    }
  }
}

void keyPressed() {
  if (key == '1') {
    setFilterMode(0);
  }

  if (key == '2') {
    setFilterMode(1);
  }

  if (key == '3') {
    setFilterMode(2);
  }

  if (key == 'r' || key == 'R') {
    resetCamera();
  }

  if (key == 't' || key == 'T') {
    startStationaryTest();
  }

  if (key == 'p' || key == 'P') {
    saveFrame("evaluation_mode_" + filterMode + "_####.png");
    println("Screenshot saved.");
  }
}

void setFilterMode(int mode) {
  filterMode = mode;
  resetCamera();

  smoothX = 0;
  smoothY = 0;
  smoothZ = 0;

  println("Changed mode to: " + modeNames[filterMode]);
}

void resetCamera() {
  yaw = 0;
  pitch = 0;

  smoothX = 0;
  smoothY = 0;
  smoothZ = 0;

  println("Camera reset.");
}

void startStationaryTest() {
  resetCamera();

  testRunning = true;
  testStartTime = millis();
  testStartYaw = yaw;
  testStartPitch = pitch;

  println("Starting stationary drift test: " + modeNames[filterMode]);
  println("Keep the MPU6050 completely still for " + testDuration + " seconds.");
}
