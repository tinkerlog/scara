import processing.svg.*;

color bgColor = 0xFF272822;  
color lineColor = 0xFF66D9EF;
color axisColor = 0xFFFD971F;

int startX = 50;
int endX = 1150;
int startY = 50;
int lineSpacing = 100;
int maxLines = 8;
int lineWidth = endX - startX;
float range = PI * 16;
int samples = 400;

float yAmp = 20F;
float xAmp = 20F;
float a1 = 20F;
float a1Amp = 20F;
float a2 = 10F;
float a2Amp = 15F;

void setup() {
  size(1200, 900);  
  noLoop();
  beginRecord(SVG, "wavy_spirals.svg");
}


void draw() {
  background(bgColor);
  yAmp = 0F;
  xAmp = 2.0F;
  for (int y = 0; y < maxLines; y++) {    
    drawLine(startY + y * lineSpacing);
    yAmp += 8;
    xAmp = pow(xAmp, 1.27);
  }
  endRecord();
}

void drawLine(int startY) {    
  // stroke(axisColor);
  // line(startX, startY, endX, startY);
  
  stroke(lineColor);
  noFill();
  beginShape();
  float spiralStart = -range;
  float spiralDelta = (range * 2) / samples;
  float xDelta = lineWidth / (float)samples;

  for (int i = 0; i <= samples; i++) {
    float x = spiralStart + i * spiralDelta;
    float screenY = startY - f1(x);
    float xd = -f2(x);
    float screenX = startX + i * xDelta + xd;
    vertex(screenX, screenY);
  }  
  endShape();
}

float f1(float x) {
  float influence = (1 / (sqrt(PI) * a1)) * exp(-(sq(x)/sq(a1))) * a1Amp;   
  return sin(x) * influence * yAmp;
}

float f2(float x) {
  float influence = (1 / (sqrt(PI) * a2)) * exp(-(sq(x)/sq(a2))) * a2Amp;   
  return cos(x) * influence * xAmp;
}
