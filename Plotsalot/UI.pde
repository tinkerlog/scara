

ControlP5 gui;

void setupUI() {
    gui = new ControlP5(this);
    gui.addBang("load")
        .setSize(130, 30)
        .setTriggerEvent(Bang.RELEASE)
        .setCaptionLabel("Load image")
        .setPosition(10, 10)
        .setColorCaptionLabel(color(255));
    gui.getController("load")
        .getCaptionLabel()
        .align(ControlP5.CENTER, ControlP5.CENTER);
    
    gui.addBang("export")
        .setSize(130, 30)
        .setTriggerEvent(Bang.RELEASE)
        .setCaptionLabel("Export gcode")
        .setPosition(10, 50)
        .setColorCaptionLabel(color(255));
    gui.getController("export")
        .getCaptionLabel()
        .align(ControlP5.CENTER, ControlP5.CENTER);

    gui.addToggle("tglFill")
        .setCaptionLabel("Fill")
        .setPosition(10, 110)
        .setValue(false)
        .setMode(ControlP5.SWITCH)
        .setColorCaptionLabel(color(0));
    gui.getController("tglFill")
        .getCaptionLabel()
        .align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);
    
}

void load() {  
    selectInput("Select an SVG file to open:", "fileSelected"); 
}

void fileSelected(File selection) {
    if (selection == null) {
        println("Window was closed or the cancel selected.");
    }
    else {
        String path = selection.getAbsolutePath();
        println("Selected file: " + path); 
        String[] p = splitTokens(path, ".");

        if (p[p.length-1].toLowerCase().equals("svg")) {
            filename = path;
            loadSvg(path);
        }
        else {
            println("Not an SVG: " + path);
        }
    }
}

void export() {
    exportFile();
}

void tglFill() {
    toggleFillStroke();
}
