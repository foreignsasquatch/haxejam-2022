package dough.tilemap;

class CollisionData {
    public var width:Int;
    public var height:Int;
    public var data:Array<Int> = [];
    
    public function new(w:Int, h:Int, d:Array<Int>) {
        width = w;
        height = h;
        data = d;
    }

    public function exists(cx:Int, cy:Int):Bool {
        return data[index(cx, cy)] == 1;
    }

    public inline function index(column, row):Int{
        return width * row + column;
    }

    public inline function column(index:Int):Int
    {
        return Std.int(index % width);
    }

    public inline function row(index:Int):Int
    {
        return Std.int(index / width);
    }
}