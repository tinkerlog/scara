import java.util.*;
import processing.svg.*;

Integer[] valuesArray = {
  new Integer(0x000000),
  new Integer(0x000001),
  new Integer(0x000002),
  new Integer(0x000100),
  new Integer(0x000101),
  new Integer(0x000102),
  new Integer(0x000200),
  new Integer(0x000201),
  new Integer(0x000202),
  new Integer(0x010000),
  new Integer(0x010001),
  new Integer(0x010002),
  new Integer(0x010100),
  new Integer(0x010101),
  new Integer(0x010102),
  new Integer(0x010200),
  new Integer(0x010201),
  new Integer(0x010202),
  new Integer(0x020000),
  new Integer(0x020001),
  new Integer(0x020002),
  new Integer(0x020100),
  new Integer(0x020101),
  new Integer(0x020102),
  new Integer(0x020200),
  new Integer(0x020201),
  new Integer(0x020202)
};

List<Integer> values = Arrays.asList(valuesArray);

int gw = 20;              // gridWidth
int gw2 = gw / 2;
int tileWidth = 8 * gw;   // width of a tile
int tileHeight = 4 * gw;  // height of a tile
int padding = 10;         // space between tiles

int startX = 20;
int startY = 20;

void setup() {
  size(550, 850); 
  Collections.shuffle(values);
  noLoop();
  beginRecord(SVG, "alps.svg");
}

void draw() {  
  background(230);
  for (int y = 0; y < 9; y++) {
    for (int x = 0; x < 3; x++) {
      drawTile(
        startX + x * (tileWidth + padding), 
        startY + y * (tileHeight + padding), 
        values.get(x+y*3));  
    }
  }
  endRecord();
}

void drawTile(int x, int y, int tile) {    
  boolean[] horizon = new boolean[16];
  for (int i = 0; i < 16; i++) {
    horizon[i] = true;
  }
  noFill();
  beginShape();
  vertex(x, y);
  vertex(x + tileWidth, y);
  vertex(x + tileWidth, y + tileHeight);
  vertex(x, y + tileHeight);
  vertex(x, y);
  endShape();
  drawMountain(x       , y + tileHeight, 0, getMountain(tile, 0),                    0, horizon);
  drawMountain(x + 2*gw, y + tileHeight, 1, getMountain(tile, 1), getMountain(tile, 0), horizon);
  drawMountain(x + 4*gw, y + tileHeight, 2, getMountain(tile, 2), getMountain(tile, 1), horizon);
  drawHorizon(x, y + tileHeight, horizon);
}

void drawMountain(int x, int y, int pos, int mountain, int before, boolean[] horizon) {  
  beginShape();
  switch (mountain) {
    case 0x00: // flat land
      break;
    case 0x01: // small mountain
      clearHorizon(0x01, pos, horizon);
      switch (before) {
        case 0x00: vertex(x + 1*gw, y - 1*gw); break;
        case 0x01: vertex(x + 1*gw, y - 1*gw); break;
        case 0x02: vertex(x + 1*gw+gw/2, y - 1*gw - gw/2); break;
      }        
      vertex(x + 2*gw, y - 2*gw);
      vertex(x + 3*gw, y - 1*gw);
      break;
    case 0x02: // big mountain
      clearHorizon(0x02, pos, horizon);
      switch (before) {
        case 0x00: vertex(x, y - gw); break;
        case 0x01: vertex(x + 1*gw - gw/2, y - 2*gw + gw/2); break;
        case 0x02: vertex(x + 1*gw, y - 2*gw); break;
      }
      vertex(x + 2*gw, y - 3*gw);
      vertex(x + 4*gw, y -   gw);
      break;
  }
  endShape();
}

void clearHorizon(int mountain, int pos, boolean horizon[]) {
  if (mountain == 0x02) {
    for (int i = 0; i < 6; i++) {
      horizon[pos*4+1+i] = false;
    }
  }
  else if (mountain == 0x01) {
    horizon[pos*4+4] = false;
    horizon[pos*4+3] = false;
  }
}

void drawHorizon(int x, int y, boolean horizon[]) {
  int horizonY = y - (gw + gw/2);
  beginShape(LINES);
  vertex(x, horizonY);
  boolean isOn = true;
  for (int i = 0; i < horizon.length; i++) {
    if (isOn && !horizon[i]) {
      vertex(x + i*gw2, horizonY);  // end
      isOn = false;
    }
    else if (!isOn && horizon[i]) {
      vertex(x + i*gw2, horizonY); // start
      isOn = true;
    }
  }
  vertex(x + tileWidth, horizonY);
  endShape();        
}
  
int getMountain(int mountains, int pos) {
  return mountains >> (pos*8) & 0x0000FF;
}
