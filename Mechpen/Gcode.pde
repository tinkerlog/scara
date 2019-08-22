/**
 * Export GCODE.
 *
 * G0 X<value> y<value> ; move to
 * G1 X<value> y<value> ; line to
 * G4 <value>           ; delay ms
 * M283 U               ; move pen up
 * M283 H               ; move pen up half
 * M283 D               ; move pen down
 * M400                 ; wait until sync
 * M501                 ; load EEPROM data
 *
 */

String FILE_PREAMBLE =
    "M501\n" +
    "M283 U\n" +
    "G4 P1000";
String FILE_POSTAMBLE =
    "M283 U\n" +
    "G4 1000\n" +
    "G0 X1427 Y0";
String POLY_PREAMBLE =
    "";
String POLY_POSTAMBLE =
    "M400\n" +
    "M283 H\n" +
    "G4 P500";

String MOVE_TO =
    "G0 X%.2f Y%.2f\n" +
    "M400\n" +
    "M283 D\n" +
    "G4 P900";
String LINE_TO =
    "G1 X%.2f Y%.2f";

int pointCount = 0;
int lineCount = 0;

void exportPath(RPath path, PrintWriter out, String indent) {
    out.println(POLY_PREAMBLE);
    RPoint[] points = path.getPoints();
    pointCount += points.length;
    // println(indent + "points: " + points.length);
    RPoint p1 = points[0];    
    out.println(String.format(Locale.US, MOVE_TO, p1.x, p1.y));
    for (int i = 0; i < points.length - 1; i++) {
        RPoint p2 = points[i];
        out.println(String.format(Locale.US, LINE_TO, p2.x, p2.y));
        lineCount++;
    }    
    out.println(POLY_POSTAMBLE);
}

void exportShape(RShape shape, PrintWriter out, String indent) {
    ShapeConfig config = shapeConfigs.get(shape);
    String cstr = config == null ? "null" : config.toString();
    println(indent + "shape " + shape + ", " + cstr);
    for (int i = 0; i < shape.countChildren(); i++) {
        exportShape(shape.children[i], out, indent + "  ");
    }
    if (shape.countChildren() == 0 && shape.countPaths() > 0) {
        if (config.doDraw) {
            if (config.style != STYLE_HATCH) {
                for (int i = 0; i < shape.countPaths(); i++) {
                    println(indent + "path: " + i);
                    exportPath(shape.paths[i], out, indent);
                }
            }
            RShape lines = shapeLines.get(shape);
            // println(indent + "fillLines: " + lines.countChildren());
            if (lines != null) {
                for (int i = 0; i < lines.countChildren(); i++) {
                    RShape lineChild = lines.children[i];
                    for (int j = 0; j < lineChild.countPaths(); j++) {
                        exportPath(lineChild.paths[j], out, indent);
                    }
                }
            }
        }
    }
}

void exportFile() {
    if (shape == null) {
        return;
    }
    pointCount = 0;
    lineCount = 0;
    String gcodeFilename = filename.substring(0, filename.lastIndexOf(".")) + ".gcode";
    println("exporting gcode to: " + gcodeFilename);
    PrintWriter out = createWriter(gcodeFilename);
    out.println(FILE_PREAMBLE);
    exportShape(shape, out, "");
    out.println(FILE_POSTAMBLE);
    out.close();
    println("points: " + pointCount);
    println("lines: " + lineCount);
    println("done");
}

