package dough;

class Window {
    public var width:Int = 1280;
    public var height:Int = 720;
    public var resolution:{w:Int, h:Int} = {w: 1280, h: 720};
    public var title:String = "WINDOW";

    public var pause:Bool = false;

    private static var renderTexture:Rl.RenderTexture;
    private static var sourceRec:Rl.Rectangle;
    private static var destRec:Rl.Rectangle;

    var updatesPerSecond:Int;

    static var timeStep:Float;
    static var timeCounter = 0.0;

    public function new(updatesPerSecond:Int=60) {
        this.updatesPerSecond = updatesPerSecond;
        timeStep = 1 / updatesPerSecond;
        
    }

    public function run(process:Class<Process>) {
        Rl.setConfigFlags(Rl.ConfigFlags.VSYNC_HINT);
        Rl.initWindow(width, height, title);
        Rl.setTargetFPS(60);
        Rl.setExitKey(Rl.Keys.NULL);

        var ratio = width / resolution.w;

        renderTexture = Rl.loadRenderTexture(resolution.w, resolution.h);
        sourceRec = Rl.Rectangle.create(0, 0, resolution.w, -resolution.h);
        destRec = Rl.Rectangle.create(-ratio, -ratio, width + (ratio * 2), height + (ratio * 2));

        Process.current = Type.createInstance(process, [this]); 
        Process.current.create(); // create scene here <--

        #if emscripten
        emscripten.Emscripten.setMainLoop(cpp.Callable.fromStaticFunction(update), 70, 1);
        #else
        while(!Rl.windowShouldClose()) {
            update();
        }
        #end

        // unload everything here please!
        Process.current.unload();
        Rl.unloadRenderTexture(renderTexture);
        
        // destroy everything here
        Rl.closeWindow();
    }

    private function update() {
        timeCounter += Rl.getFrameTime();
        
        while(timeCounter > timeStep) {
            Process.current.update(); // update here
            timeCounter -= timeStep;
        }

        Rl.beginTextureMode(renderTexture);
        Rl.clearBackground(Rl.Colors.BLACK);
               
        Process.current.draw();

        Rl.endTextureMode();

        Rl.beginDrawing();
        Rl.clearBackground(Rl.Colors.RED);

        Rl.drawTexturePro(renderTexture.texture, sourceRec, destRec, Rl.Vector2.zero(), 0, Rl.Colors.WHITE);
        Process.current.drawUI();
        Rl.endDrawing();
    }

    public function toFrameCount(seconds:Float):Float{
        return seconds / timeStep;
    }

    public function toFrameDistance(distance:Float) {
        return distance * timeStep;
    }
}