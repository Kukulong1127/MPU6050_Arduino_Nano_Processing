import processing.serial.*;

Serial myPort;

float gyroX, gyroY, gyroZ;

// Object rotation angles
float angleX = 0;
float angleY = 0;
float angleZ = 0;

// Time calculation
int lastTime;

void setup() {
  size(800, 600, P3D);

  println(Serial.list());

  // Change this to your Arduino port
  // Example: Serial.list()[0], Serial.list()[1], etc.
  myPort = new Serial(this, Serial.list()[0], 115200);

  myPort.bufferUntil('\n');

  lastTime = millis();
}

void draw() {
  background(30);

  lights();

  // Time step in seconds
  int currentTime = millis();
  float dt = (currentTime - lastTime) / 1000.0;
  lastTime = currentTime;

  // Integrate gyro speed into angle
  angleX += gyroX * dt;
  angleY += gyroY * dt;
  angleZ += gyroZ * dt;

  translate(width / 2, height / 2, 0);

  // Convert degrees to radians for Processing rotation
  rotateX(radians(angleX));
  rotateY(radians(angleY));
  rotateZ(radians(angleZ));

  // Draw object
  fill(100, 180, 255);
  stroke(255);
  strokeWeight(2);

  box(200, 80, 120);

  // Draw axis lines
  drawAxes();
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

void drawAxes() {
  strokeWeight(4);

  // X axis
  stroke(255, 0, 0);
  line(0, 0, 0, 150, 0, 0);

  // Y axis
  stroke(0, 255, 0);
  line(0, 0, 0, 0, 150, 0);

  // Z axis
  stroke(0, 0, 255);
  line(0, 0, 0, 0, 0, 150);
}
