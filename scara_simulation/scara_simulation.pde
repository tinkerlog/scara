/**
 * This is a simple simulation of a SCARA robot arm.
 *
 *
 * Links
 * -----
 * Intersection of two circles, Paul Bourke: http://paulbourke.net/geometry/circlesphere/
 * Hershey Font for Processing: https://github.com/ixd-hof/HersheyFont
 * Hershey Font Showcase: http://soft9000.com/HersheyShowcase/
 *
 */


import java.util.*;


int SIZE_X = 800;
int SIZE_Y = 800;
int FRAMERATE = 60;

int STATUS_WIDTH = 270;
int STATUS_HEIGHT = 100;
int STATUS_X = 40;
int STATUS_Y = SIZE_Y - (STATUS_HEIGHT + 40);

float SCALE = 0.3;

// colors (monokai)
color bgColor = 0xFF272822;  
color lineColor = 0xFFF92672;
color axisColor = 0xFFFD971F;
color systemColor = 0xFFA6E22E;
color armColor = 0xFF66D9EF;

float MAX_LINE_DISTANCE = 50.0; // lines with length more than 50mm gets broken up into smaller line segments

float ARM_A_LENGTH = 700.0;  // length upper arm (mm)
float ARM_B_LENGTH = 700.0;  // length forearm (mm)

float MIN_X =  150; // 850x950 
float MAX_X = 1000;
float MIN_Y =    0;
float MAX_Y =  950;

float MAX_REACH = ARM_A_LENGTH + ARM_B_LENGTH;
float ARM_A_LENGTH2 = sq(ARM_A_LENGTH);
float ARM_B_LENGTH2 = sq(ARM_B_LENGTH);

int STEPS_PER_DEGREE_A = 95;
int STEPS_PER_DEGREE_B = 89;

int FEEDRATE_A = 20;  // 15 degrees / sec.
int FEEDRATE_B = 30;  // 15 degrees / sec.
int stepsPerFrameA = (int)((FEEDRATE_A * STEPS_PER_DEGREE_A) * (1 / 40.0));
int stepsPerFrameB = (int)((FEEDRATE_B * STEPS_PER_DEGREE_B) * (1 / 40.0));

// "endstops" for theta and psi
float THETA_MAX_RAD = radians( 100.0); 
float THETA_MIN_RAD = radians(-100.0); 
float PSI_MAX_RAD = radians( 170.0); 
float PSI_MIN_RAD = radians(-170.0);


float stepsA = 0;
float stepsB = 0;
float startStepsA = 0;
float startStepsB = 0;

float iterStepsA = 0;
float iterStepsB = 0;
int iterations = 0;

PVector origin = new PVector(0, 0);
PVector currentHandPos = new PVector(0, 0);
PVector currentElbowPos = new PVector(0, 0);

float thetaRad = 0;
float psiRad = 0;

Command currentCmd = null;
PVector targetPos = null;

List<float[]> canvasLines = new ArrayList<float[]>();
Queue<Command> posQueue = new LinkedList<Command>();

enum State {
    HOMING,
    HOMING_A1,
    HOMING_A2,
    HOMING_B1,
    HOMING_B2,
    IDLE,
    WORKING,
    ERROR
}

State state = State.HOMING;

boolean doHoming = false;

void setup() { 
    size(800, 800);
    frameRate(FRAMERATE);

    if (doHoming) {
        state = State.HOMING;
        startStepsA = random(5000) - 2500;  // fake a random arm position
        startStepsB = random(5000) - 2500;
    }
    else {
        state = State.IDLE;
        startStepsA = 0;
        startStepsB = 0;
    }    
    
    // hf = new HersheyFont(this, "timesr.jhf");
    HersheyFont hf = new HersheyFont(this, "cursive.jhf");
    // HersheyFont hf = new HersheyFont(this, "futural.jhf");
    hf.textSize(120);
    convertShape(hf.getShape("Hello"), posQueue, "", 850, 400);
    convertShape(hf.getShape("W"), posQueue, "",    850, 250);
    convertShape(hf.getShape("orld"), posQueue, "", 930, 250);

    /*
    posQueue.offer(new Command( 300,  600, Cmd.MOVE));
    posQueue.offer(new Command(1200,  600, Cmd.DRAW));
    posQueue.offer(new Command(1200,    0, Cmd.DRAW));
    posQueue.offer(new Command( 300,    0, Cmd.DRAW));
    posQueue.offer(new Command( 300,  600, Cmd.MOVE));
    posQueue.offer(new Command( 300,    0, Cmd.DRAW));
    posQueue.offer(new Command(-500,    0, Cmd.MOVE));
    */

    /*
    posQueue.offer(new Command( MIN_X, MAX_Y, Cmd.MOVE));
    posQueue.offer(new Command( MAX_X, MAX_Y, Cmd.DRAW));
    posQueue.offer(new Command( MAX_X, MIN_Y, Cmd.DRAW));
    posQueue.offer(new Command( MIN_X, MIN_Y, Cmd.DRAW));
    posQueue.offer(new Command( MIN_X, MAX_Y, Cmd.MOVE));
    posQueue.offer(new Command( MIN_X, MIN_Y, Cmd.DRAW));
    posQueue.offer(new Command( MIN_X, MIN_Y, Cmd.MOVE));
    */
    posQueue.offer(new Command(  1400,  0, Cmd.MOVE));
    // posQueue.offer(new Command(   500,  -250, Cmd.MOVE));
    
    posQueue = preProcess(posQueue);
    exportToFile("hello.gcode", posQueue);
    
    computeForwardKinematics();
}

void convertShape(PShape shape, Queue<Command> posQueue, String indent, float transX, float transY) {

    switch (shape.getFamily()) {
    case GROUP:
        println(indent + "shape, childs: " + shape.getChildCount());
        for (int i = 0; i < shape.getChildCount(); i++) {
            convertShape(shape.getChild(i), posQueue, indent + "  ", transX, transY);
        }
        break;
    case PShape.GEOMETRY:
        println(indent + "geometry, vertex: " + shape.getVertexCount());
        PVector v2Old = null;
        for (int i = 0; i < shape.getVertexCount(); i += 2) {            
            PVector v1 = shape.getVertex(i);
            PVector v2 = shape.getVertex(i+1);
            if (v2Old == null || !v1.equals(v2Old)) {
                posQueue.offer(new Command(transX + v1.x, transY - v1.y, Cmd.MOVE));
                posQueue.offer(new Command(transX + v2.x, transY - v2.y, Cmd.DRAW));
            }
            else if (v1.equals(v2Old)) {
                posQueue.offer(new Command(transX + v2.x, transY - v2.y, Cmd.DRAW));
            }
            v2Old = v2;
        }
        break;
    default:
        println("unknown shape family: " + shape.getFamily());
        break;
    }
    
}


void exportToFile(String fileName, Queue<Command> posQueue) {

    PrintWriter output = createWriter(fileName);

    output.println("M280 P0 S60");

    Command c1 = null;
    Command c2 = null;
    boolean isMove = true;
    for (Iterator it = posQueue.iterator(); it.hasNext(); ) {
        c2 = (Command)it.next();
        if (c1 != null && c1.command != c2.command) {
            if (c2.command == Cmd.DRAW) {
                output.println("M400");
                output.println("M280 P0 S130");
                output.println("G4 P1000");
                isMove = false;
            }
            else {
                output.println("M400");
                output.println("M280 P0 S60");
                output.println("G4 P500");
                isMove = true;
            }
        }
        if (isMove) {
            output.println(String.format(Locale.US, "G0 X%.1f Y%.1f", c2.pos.x, c2.pos.y));
        }
        else {
            output.println(String.format(Locale.US, "G1 X%.1f Y%.1f", c2.pos.x, c2.pos.y));
        }
        
        c1 = c2;
    }

    
    output.flush();
    output.close();

}

Queue<Command> preProcess(Queue posQueue) {
    Queue<Command> newQueue = new LinkedList<Command>();
    Command c1 = null;
    Command c2 = null;
    for (Iterator it = posQueue.iterator(); it.hasNext(); ) {
        c2 = (Command)it.next();
        if (c1 == null) {
            newQueue.offer(c2);
        }
        else {
            if (c2.command == Cmd.MOVE) {
                newQueue.offer(c2);
            }
            else {
                float distance = PVector.dist(c1.pos, c2.pos);
                if (distance > MAX_LINE_DISTANCE) {
                    newQueue.addAll(generateSupportPoints(c1, c2));		    
                }
                else {
                    newQueue.offer(c2);
                }
            }
        }
        c1 = c2;
    }
    return newQueue;
}

List<Command> generateSupportPoints(Command c1, Command c2) {
    List<Command> points = new ArrayList<Command>();
    float distance = PVector.dist(c1.pos, c2.pos);
    float dc = distance / MAX_LINE_DISTANCE;
    int dcr = round(dc + 0.5);
    float dx = c2.pos.x - c1.pos.x;
    float dy = c2.pos.y - c1.pos.y;
    float ddx = dx / dcr;
    float ddy = dy / dcr;
    float x = c1.pos.x;
    float y = c1.pos.y;
    int i = 0;
    while (i < dcr) {
        x += ddx;
        y += ddy;
        points.add(new Command(x, y, c2.command));
        i++;
    }        
    points.add(c2);
    return points;
}

void update() {
    updateState();
}

int targetStepsB2 = 0;
int targetStepsA2 = 0;

void updateState() {
    switch (state) {
    case HOMING:
        state = State.HOMING_A1;
        break;
    case HOMING_A1:  // moving upper arm and forearm until we hit the endstop
        stepsA -= 5;
        stepsB -= 5;
        try {
            updateMotors();
            computeForwardKinematics();
        }
        catch (EndStopException ex) {
            state = State.HOMING_A2;
            targetStepsA2 = (int)(stepsA - (degrees(THETA_MIN_RAD) * STEPS_PER_DEGREE_A));
            println("stepsA: " + stepsA + ", target: " + targetStepsA2);
        }
        break;
    case HOMING_A2:  // moving upper arm to 0° 
        if (stepsA < targetStepsA2) {
            stepsA += 5;
            stepsB += 5;
            updateMotors();
            computeForwardKinematics();
        }
        else {
            stepsA = targetStepsA2;
            state = State.HOMING_B1;
        }
        break;
    case HOMING_B1:  // moving forearm until we hit the endstop
        stepsB += 5;
        try {
            updateMotors();
            computeForwardKinematics();
        }
        catch (EndStopException ex) {
            state = State.HOMING_B2;
            targetStepsB2 = (int)(stepsB - (degrees(PSI_MAX_RAD) * STEPS_PER_DEGREE_B));
            println("stepsB: " + stepsB + ", target: " + targetStepsB2);
        }
        break;
    case HOMING_B2:  // moving the forearm to 0° 
        if (stepsB > targetStepsB2) {
            stepsB -= 5;
            updateMotors();
            computeForwardKinematics();
        }
        else {
            stepsB = targetStepsB2;
            state = State.IDLE;
        }
        break;
    case IDLE:
        if (!posQueue.isEmpty()) {
            currentCmd = posQueue.poll();
            targetPos = currentCmd.pos;
            computeInverseKinematics(targetPos);
            state = State.WORKING;
        }
        else {
            state = State.IDLE;
        }
        break;
    case WORKING:
        updateMotors();
        PVector oldHandPos = currentHandPos.copy();
        computeForwardKinematics();
        if (currentCmd.command == Cmd.DRAW) {
            float[] line = new float[4];
            line[0] = oldHandPos.x;
            line[1] = oldHandPos.y;
            line[2] = currentHandPos.x;
            line[3] = currentHandPos.y;
            canvasLines.add(line);
        }
        if (iterations <= 0 || targetPos.dist(currentHandPos) < 0.001) {
            state = State.IDLE;
        }
        break;
    }

}

void updateMotors() {
    iterations--;
    stepsA += iterStepsA;
    stepsB += iterStepsB;
    thetaRad = radians((float)(stepsA+startStepsA) / STEPS_PER_DEGREE_A);
    psiRad = radians((float)(stepsB+startStepsB) / STEPS_PER_DEGREE_B);
    
    thetaRad = limitAnglePi(thetaRad);
    checkThetaEndStop(thetaRad);
    
    psiRad = limitAnglePi(psiRad);
    checkPsiEndStop(psiRad, thetaRad);
}

void checkThetaEndStop(float thetaRad) {
    if (thetaRad < THETA_MIN_RAD) {
        throw new EndStopException("hitting the theta min stop: " + degrees(thetaRad));
    }
    else if (thetaRad > THETA_MAX_RAD) {
        throw new EndStopException("hitting the theta max stop: " + degrees(thetaRad));
    }
}

void checkPsiEndStop(float psiRad, float thetaRad) {
    float relPsiRad = psiRad - thetaRad;
    if (relPsiRad < PSI_MIN_RAD) {
        throw new EndStopException("hitting the psi min stop: " + degrees(relPsiRad));
    }
    else if (relPsiRad > PSI_MAX_RAD) {
        throw new EndStopException("hitting the psi max stop: " + degrees(relPsiRad));
    }
}

void computeForwardKinematics() {
    currentElbowPos = computePosition(thetaRad, ARM_A_LENGTH);
    currentHandPos = currentElbowPos.copy().add(computePosition(psiRad, ARM_B_LENGTH));
}

PVector computePosition(float angle, float radius) {
    float x = cos(angle) * radius;
    float y = sin(angle) * radius;
    return new PVector(x, y);
}

void computeInverseKinematics(PVector target) {

    // compute intersection of two circles
    // http://paulbourke.net/geometry/circlesphere/

    // println("target: " + target.x + ", " + target.y);
    
    float d = PVector.dist(target, origin);
    // println("distance: " + d);
    
    if (d > MAX_REACH) {
        throw new IllegalArgumentException("target not reachable");
    }
    
    float a = (ARM_A_LENGTH2 - ARM_B_LENGTH2 + sq(d)) / (2.0 * d);
    float h = sqrt(ARM_A_LENGTH2 - sq(a));
    // println("a: " + a + ", h: " + h);

    float dx = target.x - origin.x;
    float dy = target.y - origin.y;

    float x2 = origin.x + dx * a / d;
    float y2 = origin.y + dy * a / d;
    // println("x2/y2: " + x2 + ", " + y2);

    float rx = -dy * h / d;
    float ry =  dx * h / d;
    
    float x31 = x2 + rx;
    float y31 = y2 + ry;
    float x32 = x2 - rx;
    float y32 = y2 - ry;

    PVector elbow1 = new PVector(x31, y31);
    PVector elbow2 = new PVector(x32, y32);
    // println(String.format("elbow1 x/y: %.2f %.2f", elbow1.x, elbow1.y));
    // println(String.format("elbow2 x/y: %.2f %.2f", elbow2.x, elbow2.y));

    float d1 = PVector.dist(currentElbowPos, elbow1);
    float d2 = PVector.dist(currentElbowPos, elbow2);
    PVector targetElbow;
    PVector altElbow;
    
    if (d1 < d2) {
        // println("choosing elbow 1");
        targetElbow = elbow1;
        altElbow = elbow2;
    }
    else {
        // println("choosing elbow 2");
        targetElbow = elbow2;
        altElbow = elbow1;
    }
   
    float targetTheta = acos(targetElbow.x / ARM_A_LENGTH);
    if (targetElbow.y < 0) targetTheta *= -1;
    if (!canReachTargetTheta(targetTheta)) {
        throw new IllegalArgumentException("theta: can not reach " + degrees(targetTheta));
    }
    
    PVector deltaTargetElbow = PVector.sub(target, targetElbow);
    float targetPsi = acos(deltaTargetElbow.x / ARM_B_LENGTH);
    if (deltaTargetElbow.y < 0) targetPsi *= -1;
    if (!canReachTargetPsi(targetPsi, targetTheta)) {
        throw new IllegalArgumentException("psi: can not reach " + degrees(targetPsi));
    }

    float deltaTheta = limitAnglePi(targetTheta - thetaRad);
    float deltaPsi = limitAnglePi(targetPsi - psiRad);
    // println("theta: " + degrees(thetaRad) + ", target: " + degrees(targetTheta) + ", delta: " + degrees(deltaTheta));
    // println("psi:  " + degrees(psiRad) + ", target: " + degrees(targetPsi) + ", delta: " + degrees(deltaPsi));
    // println("psi2: " + degrees(psiRad-thetaRad) + ", target: " + degrees(targetPsi-targetTheta));

    float deltaThetaDeg = degrees(deltaTheta);
    float deltaPsiDeg = degrees(deltaPsi);

    float thetaTime = abs(deltaThetaDeg / FEEDRATE_A);
    float psiTime = abs(deltaPsiDeg / FEEDRATE_B);

    // println("time for theta: " + thetaTime + ", psi: " + psiTime);

    iterations = 0;
    if (thetaTime > psiTime) {
        iterations = (int)(thetaTime * FRAMERATE);
    }
    else {
        iterations = (int)(psiTime * FRAMERATE);
    }
    // println("iterations: " + iterations);
    float thetaSteps = degrees(deltaTheta) * STEPS_PER_DEGREE_A;
    float psiSteps = degrees(deltaPsi) * STEPS_PER_DEGREE_B;
    if (iterations > 0) {
        iterStepsA = thetaSteps / iterations;
        iterStepsB = psiSteps / iterations;
    }
    else {
        iterStepsA = 0f;
        iterStepsB = 0f;	
    }

    // println("steps: theta: " + thetaSteps + ", psi: " + psiSteps);
    // println("iterSteps: A: " + iterStepsA + ", B: " + iterStepsB);    
}

/*
boolean canReach(PVector elbow, PVector target) {
    float targetTheta = acos(elbow.x / ARM_A_LENGTH);
    if (elbow.y < 0) targetTheta *= -1;
    if (!canReachTargetTheta(targetTheta)) {
        println("canReach: theta: false");
        return false;
    }
    PVector deltaTargetElbow = PVector.sub(target, elbow);
    float targetPsi = acos(deltaTargetElbow.x / ARM_B_LENGTH);
    if (deltaTargetElbow.y < 0) targetPsi *= -1;
    if (!canReachTargetPsi(targetPsi, targetTheta)) {
        println("canReach: psi: false");
        return false;
    }
    println("canReach: true");
    return true;
}
*/

boolean canReachTargetTheta(float targetTheta) {
    return (targetTheta < THETA_MAX_RAD) && (targetTheta > THETA_MIN_RAD);
}

boolean canReachTargetPsi(float targetPsi, float currentTheta) {
    float relTargetPsi = targetPsi - currentTheta;
    return (relTargetPsi < PSI_MAX_RAD) && (relTargetPsi > PSI_MIN_RAD);
}

float limitAnglePi(float angle) {
    return (angle < -PI) ? angle + TWO_PI : (angle > PI) ? angle - TWO_PI : angle;    
}

void draw() {
    update();
    
    background(bgColor);
    strokeWeight(1);

    pushMatrix();
    translate(200, 400);
    scale(SCALE, -SCALE); 
    
    drawOrigin();
    drawLines();
    drawArm();

    popMatrix();
    drawStatus();
}

void drawStatus() {
    stroke(systemColor);
    fill(bgColor);
    strokeWeight(1);
    textSize(14);
    rect(STATUS_X, STATUS_Y, STATUS_WIDTH, STATUS_HEIGHT);

    fill(systemColor);
    translate(STATUS_X + 10, STATUS_Y);

    translate(0, 20);
    textAlign(LEFT);
    text("State: " + state, 0, 0);
    
    translate(0, 20);
    text("Steps A/B:\nTheta/Psi:\nX/Y:", 0, 0);
    
    textAlign(RIGHT);
    translate(130, 0);
    String s1 = null;
    String s2 = null;
    switch (state) {
    case HOMING_A1:
        s1 = String.format("%5.1f\n%4.2f\n%3.1f", stepsA, 0f, 0f);
        s2 = String.format("%5.1f\n%4.2f\n%3.1f", stepsB, 0f, 0f);
        break;
    case HOMING_A2:
    case HOMING_B1:
        s1 = String.format("%5.1f\n%4.2f\n%3.1f", stepsA, degrees(thetaRad), 0f);
        s2 = String.format("%5.1f\n%4.2f\n%3.1f", stepsB, 0f, 0f);
        break;
    case HOMING_B2:
        s1 = String.format("%5.1f\n%4.2f\n%3.1f", stepsA, degrees(thetaRad), 0f);
        s2 = String.format("%5.1f\n%4.2f\n%3.1f", stepsB, degrees(psiRad), 0f);
        break;        
    default:
        s1 = String.format("%5.1f\n%4.2f\n%3.1f", stepsA, degrees(thetaRad), currentHandPos.x);            
        s2 = String.format("%5.1f\n%4.2f\n%3.1f", stepsB, degrees(psiRad), currentHandPos.y);
    }
    text(s1, 0, 0);

    translate(90, 0);
    text(s2, 0, 0);
}

void drawLines() {
    stroke(lineColor);
    strokeWeight(4);
    for (float[] l : canvasLines) {
        line(l[0], l[1], l[2], l[3]); 
    }
}

void drawArm() {
    strokeWeight(4);
    noFill();
    stroke(armColor);
    circle(0, 0, 60);

    line(0, 0, currentElbowPos.x, currentElbowPos.y);
    circle(currentElbowPos.x, currentElbowPos.y, 40);

    line(currentElbowPos.x, currentElbowPos.y, currentHandPos.x, currentHandPos.y);
    if (currentCmd != null && currentCmd.command == Cmd.DRAW) {
        fill(armColor);
    }
    circle(currentHandPos.x, currentHandPos.y, 40);    
}

void drawOrigin() {  
    strokeWeight(1.5);
    stroke(axisColor);
    for (int y = 1500; y >= -1500; y -= 500) {
        line(-1000, y, 2500, y);
    }
    for (int x = -500; x <= 2000; x += 500) {
        line(x, -2000, x, 2000);
    }    
}

enum Cmd {
    MOVE,
    DRAW
}

class Command {
    public PVector pos;
    public Cmd command;
    Command(float x, float y, Cmd command) {
        this.pos = new PVector(x, y);
        this.command = command;
    }
}

class EndStopException extends RuntimeException  {
    EndStopException(String message) {
        super(message);
    }
}
