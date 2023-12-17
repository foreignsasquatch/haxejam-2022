import dough.tilemap.CollisionData;
import entity.Hero;
import dough.Process;

class Game extends Process {
    public var hero:Hero;

    override function create() {
        hero = new Hero(10, 10, new CollisionData(256, 256, []));
    }

    override function update() {
        hero.update();
    }

    override function draw() {
        hero.draw();
    }

    override function drawUI() {
    }

    override function unload() {
        hero.unload();
    }
}