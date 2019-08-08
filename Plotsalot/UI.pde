

ControlP5 gui;
int shapeCount = 0;

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

    gui.addTextlabel("Shapes")
        .setText("SHAPES")
        .setPosition(10, 180)
        .setFont(gui.getFont());

}

void addShapeButtons(final RShape shape) {
    CheckBox cb = gui.addCheckBox("cb" + shapeCount)
        .setPosition(10, 200 + shapeCount * 22)
        .setSize(15, 15)
        .setItemsPerRow(1)
        .setSpacingColumn(35)
        .addItem("on " + shapeCount, 1);
    cb.getItem(0).setState(true);
    gui.getController("on " + shapeCount).addListener(new ControlListener() {
            public void controlEvent(ControlEvent event) {
                shapeConfigs.get(shape).doDraw = event.getController().getValue() > 0;
            }
        });

    DropdownList ddl = gui.addDropdownList("dd " + shapeCount)
        .setPosition(55, 200 + shapeCount * 22)
        .setItemHeight(20)
        .setWidth(85)
        .setBarHeight(15)        
        .addItem("POLY", "poly")
        .addItem("STROKE", "stroke")
        .addItem("HATCH", "hatch")
        .addItem("STROKE & HATCH", "strokeHatch");
    ddl.getCaptionLabel().set("POLY");
    ddl.close();
    ddl.setValue(0f);

    ddl.onEnter(new CallbackListener() {
            public void controlEvent(CallbackEvent event) {
                event.getController().bringToFront();
            }
        });
    gui.getController("dd " + shapeCount).addListener(new ControlListener() {
            public void controlEvent(ControlEvent event) {
                int style = (int)event.getController().getValue();
                println("dropdown: " + event.getController().getValue() + ", " + event.getController().getStringValue());
                switch (style) {
                case STYLE_POLY:
                    setPolyStyle(shape, style);
                    break;
                case STYLE_STROKE:
                    setStrokeStyle(shape, style);
                    break;
                case STYLE_HATCH:
                    setHatchStyle(shape, style);
                    break;
                case STYLE_STROKE_HATCH:
                    setStrokeHatchStyle(shape, style);
                    break;
                }
            }            
        });

    shapeCount++;
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
            noLoop();
            loadSvg(path);
            loop();
        }
        else {
            println("Not an SVG: " + path);
        }
    }
}

void export() {
    exportFile();
}


