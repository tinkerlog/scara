import processing.svg.*;

color bgColor = 0xFF272822;  
color lineColor = 0xFF66D9EF;

int startX = 50;
int endX = 1150;
int startY = 50;
int lineSpacing = 100;
int maxLines = 8;
int lineWidth = endX - startX;
float range = PI * 30;
int samples = 600;
boolean doRecord = false;

float yAmp = 20F;
float xAmp = 20F;
float a1 = 20F;
float a1Amp = 20F;
float a2 = 10F;
float a2Amp = 15F;

void setup() {
  size(1200, 900);  
}

void keyPressed() {
  switch (key) {
    case 'a': a1 *= 1.02; break;
    case 'A': a1 /= 1.02; break; 
    case 'q': a1Amp *= 1.01; break;
    case 'Q': a1Amp /= 1.01; break;
    case 's': a2 *= 1.02; break;
    case 'S': a2 /= 1.02; break;
    case 'w': a2Amp *= 1.01; break;
    case 'W': a2Amp /= 1.01; break;
    case 'r': doRecord = true; break;
  }
} 

void draw() {
  if (doRecord) {
    beginRecord(SVG, "wavy_spirals.svg");
  }
  background(bgColor);
  yAmp = 0F;
  xAmp = 2.0F;
  for (int y = 0; y < maxLines; y++) {    
    drawLine(startY + y * lineSpacing);
    yAmp += 2 + pow(yAmp/2, 1.002);
    xAmp = pow(xAmp, 1.275);
  }
  if (doRecord) {    
    endRecord();
    doRecord = false;
  }
}

void drawLine(int startY) {    
  
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
  return -cos(x) * influence * xAmp;
}
