/**
 * Mouse related stuff.
 */

float mouseShapeCoordX = 0F;
float mouseShapeCoordY = 0F;
boolean mouseIsOverShape = false;


void mouseMoved() {
    if (shape != null) {
        mouseIsOverShape = isContained(mouseShapeCoordX, mouseShapeCoordY);
    }
    else {
        mouseIsOverShape = false;
    }
}

void mouseWheel(MouseEvent event) {
    if (mouseIsOverShape) {
        float e = event.getCount();
        RPoint center = shape.getCenter();
        if (e > 0.0001) {
            scaleShape(shape, center, 1.02);
            scaleShape(fillLines, center, 1.02);
        }
        else if (e < -0.001) {
            scaleShape(shape, center, 0.98);
            scaleShape(fillLines, center, 0.98);
        }
    }
}

void mouseDragged() {
    if (mouseIsOverShape) {
        int deltaX = mouseX-pmouseX;
        int deltaY = mouseY-pmouseY;
        if (deltaX != 0 || deltaY != 0) {
            shape.translate(deltaX / SCREEN_SCALE, deltaY / -SCREEN_SCALE);
            if (fillLines != null) {
                fillLines.translate(deltaX / SCREEN_SCALE, deltaY / -SCREEN_SCALE);
            }
        }
    }
}

void mapMousePosition() {
    float[] shapeCoords = toShapeCoordinates(mouseX, mouseY);
    mouseShapeCoordX = shapeCoords[0];
    mouseShapeCoordY = shapeCoords[1];
}

float[] toShapeCoordinates(float x, float y) {
    float[] result = new float[2];
    result[0] = (x - START_X) / SCREEN_SCALE;
    result[1] = (y - (START_Y + SCREEN_MAX_Y)) / -SCREEN_SCALE;
    return result;
}

boolean isContained(float x, float y) {
    RPoint p1 = shape.getTopLeft();
    RPoint p2 = shape.getBottomRight();
    return (x >= p1.x && x <= p2.x && y >= p1.y && y <= p2.y);
}
