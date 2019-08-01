
import geomerative.*;
import controlP5.*;
import java.util.*;


// viewport
int VP_MAX_X = 1450;
int VP_MAX_Y = 1450;
int ARM_REACH = 1427;

// position of a sheet of paper
int PAPER_X = 500;
int PAPER_Y =   0;
int PAPER_WIDTH =  700;
int PAPER_HEIGHT = 600;

// screen
int SCREEN_MAX_X = 800;
int SCREEN_MAX_Y = 800;
float SCREEN_SCALE = (float)SCREEN_MAX_X / VP_MAX_X;
int START_X = 150;
int START_Y = 10;

// initial position of loaded shape
int START_TRANSLATE_X = 200;
int START_TRANSLATE_Y = 200;

color gridColor = 0xFFB0B0B0;
color paperColor = 0xFFF0F0F0;
color background = 0xFFE8E8E8;
color activeColor = 0xFFFF0000;

RShape shape = null;
RShape fillLines = null;
String filename;
float shapeScale = 1F;
boolean doFill = true;

float stepWidth = 12F;


void setup() {
    size(960, 820);
    RG.init(this);
    RG.setPolygonizer(RG.ADAPTATIVE);

    println("screen scale: " + SCREEN_SCALE);
    setupUI();

    // filename = "edding.svg";
    // shape = loadSvg(filename);
}


void draw() {

    mapMousePosition();

    strokeWeight(2);
    stroke(0);
    fill(background);
    rect(START_X-1, START_Y-1, SCREEN_MAX_X, SCREEN_MAX_Y);
    clip(START_X, START_Y, SCREEN_MAX_X, SCREEN_MAX_Y);
  
    pushMatrix();
    translate(START_X, START_Y + SCREEN_MAX_Y);
    scale(SCREEN_SCALE, -SCREEN_SCALE);
    drawPaper();
    drawGrid();
  
    if (shape != null) {
        shape.draw();
        if (fillLines != null) {
            fillLines.draw();
        }
        if (mouseIsOverShape) {
            stroke(activeColor);
            rect(shape.getX(), shape.getY(), shape.getWidth(), shape.getHeight());
        }
    }
    popMatrix();
    noClip();
}

void setStroke(RShape shape) {
    shape.getStyle().fill = false;
    shape.getStyle().stroke = true;
    for (int i = 0; i < shape.countChildren(); i++) {
        setStroke(shape.children[i]);
    }
}

void toggleFillStroke() {
    doFill = !doFill;
    if (shape != null) {
        setStroke(shape);
        fillLines = computeIntersections(shape);
    }
}


void drawGrid() {
    noFill();
    ellipseMode(RADIUS);
    strokeWeight(2);
    stroke(gridColor);
    circle(0, 0, ARM_REACH);
    for (int y = 0; y < 1400; y += 200) {
        line(0, y, VP_MAX_X, y);
    }
    for (int x = 0; x < 1400; x += 200) {
        line(x, 0, x, VP_MAX_X);
    }
}

void drawPaper() {
    stroke(gridColor);
    fill(paperColor);
    rect(PAPER_X, PAPER_Y, PAPER_WIDTH, PAPER_HEIGHT);
}

RShape loadSvg(String filename) {
    shape = RG.loadShape(filename);
    println("shape width/height: " + shape.width + ", " + shape.height);
    print(shape, "shape: ");
    prepareSvg(shape);
    print(shape, "shape: ");
    return shape;
}

void prepareSvg(RShape shape) {
    RPoint p1 = shape.getTopLeft();
    RPoint p2 = shape.getBottomRight();
    shape.translate(-p1.x, -p1.y);
    shape.scale(1F, -1F);
    shape.translate(0, shape.height);
    printShape(shape, "");
    shape.translate(START_TRANSLATE_X, START_TRANSLATE_Y);
}

void printShape(RShape shape, String indent) {
    println(indent + "childs: " + shape.countChildren() + ", paths: " + shape.countPaths());
    printStyle(shape.getStyle(), indent + " ");
    // shape.getStyle().fill = false;
    // shape.getStyle().stroke = true;
    for (int i = 0; i < shape.countChildren(); i++) {
        printShape(shape.children[i], indent + "  ");
    }
    for (int i = 0; i < shape.countPaths(); i++) {
        RPath path = shape.paths[i];
        RStyle stl = path.getStyle();
        // println(indent + "points: " + path.getPoints().length);
        // printStyle(path.getStyle(), indent + " ");
    }    
}

void printStyle(RStyle stl, String indent) {
    int fill = stl.fillColor;
    println(indent + "style: fill: " + stl.fill + ", color: " +  red(fill) + ", " + green(fill) + ", " + blue(fill));
}

void print(RShape p, String msg) {
    RPoint p1 = p.getTopLeft();
    RPoint p2 = p.getBottomRight();
    println(msg + " (" + p1.x + ", " + p1.y + "), (" + p2.x + ", " + p2.y + ")");
}


void scaleShape(RShape shape, RPoint center, float scale) {
    if (shape != null) {
        shape.scale(scale, scale, center);
    }
}


RShape computeIntersectionsWithShape(RShape shape, String indent) {
    
    RShape allLines = new RShape();

    println(indent + "shape childs: " + shape.countChildren());
    
    for (int i = 0; i < shape.countChildren(); i++) {
        RShape lines = computeIntersectionsWithShape(shape.children[i], indent + "  ");
        allLines.addChild(lines);
        println("<- " + allLines.countChildren());
    }

    float x = 0;
    float y = 0;

    int fill = shape.getStyle().fillColor;
    stepWidth = (red(fill) / 255f) * 10 + 4; 
    println(indent + "  style: fill: " + shape.getStyle().fill + ", color: " +  red(fill) + ", " + green(fill) + ", " + blue(fill) + ", step: " + stepWidth);

    if (shape.countPaths() > 0) {
    
        while (x < VP_MAX_X * 2 && y < VP_MAX_Y * 2) {      
            RShape s = new RShape();
            s.addMoveTo(new RPoint(0, y));
            s.addLineTo(new RPoint(x, 0));
            RPoint[] points = shape.getIntersections(s);
            if (points != null) {
                println(indent + "  points: " + points.length);
                List<ComparablePoint> pointsList = new ArrayList<ComparablePoint>();      
                for (RPoint p : points) {
                    pointsList.add(new ComparablePoint(p));
                }
                Collections.sort(pointsList);
                if (pointsList.size() % 2 == 0) {
                    int i = 0;
                    while (i <  pointsList.size()) {
                        RPoint p1 = pointsList.get(i++);
                        RPoint p2 = pointsList.get(i++);
                        RShape l = new RShape();
                        l.addMoveTo(p1);
                        l.addLineTo(p2);
                        allLines.addChild(l);
                    }
                }
            }
            x += stepWidth;
            y += stepWidth;
        }
    }
    println(indent + "  intersection lines: " + allLines.countChildren());
    return allLines;
}

RShape computeIntersections(RShape shape) {
    println("computeIntersections");
    RShape allLines = computeIntersectionsWithShape(shape, "");
    return allLines;
}

public class ComparablePoint extends RPoint implements Comparable<ComparablePoint> {
    public ComparablePoint(RPoint p) {
        super(p);
    }
    public int compareTo(ComparablePoint other) {
        return (x < other.x) ? -1 : (x == other.x) ? 0 : 1;
    }     
}






