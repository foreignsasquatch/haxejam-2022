package dough.tilemap;

class CollisionData {
    public var width:Int;
    public var height:Int;
    public var gridSize:Int = 16;
    public var data:Array<Int> = [];
    
    public function new(w:Int, h:Int, d:Array<Int>) {
        width = w;
        height = h;
        data = d;
    }

    public function exists(cx:Int, cy:Int):Bool {
        return data[width * cx + cy] == 1;
    }
}