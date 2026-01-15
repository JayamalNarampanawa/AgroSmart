#define TRIG 26
#define ECHO 25

void setup() {
  Serial.begin(115200);
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);
}

void loop() {
  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);

  long duration = pulseIn(ECHO, HIGH, 30000);
  float distance = duration * 0.034 / 2;

  Serial.print("Water Level Distance: ");
  Serial.print(distance);
  Serial.println(" cm");

  delay(1000);
}
