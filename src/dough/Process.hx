package dough;

class Process {
    public static var current:Process;

    public function new() {}
    public function create() {}
    public function update() {}
    public function draw() {}
    public function drawUI() {}
    public function unload() {}

    public static function set(process:Class<Process>) {
        if(current != null) current.unload();
        if(current != null) current = null;
        current = Type.createInstance(process, []);
        current.create();
    }
}