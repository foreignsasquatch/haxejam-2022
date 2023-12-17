package entity;

import dough.Aseprite;
import dough.Entity;

class Hero extends Entity {
    public var sprite:Aseprite;
    public var shadow:Aseprite;

    override function create() {
        sprite = new Aseprite(positionX, positionY, "resources/ase/car.ase");
        shadow = new Aseprite(positionX, positionY, "resources/ase/car_shadow.ase");
    }

    override function update() {
        super.update(); // physics
        sprite.x = positionX;
        sprite.y = positionY;
        shadow.x = sprite.x;
        shadow.y = sprite.y + 1;
    }

    override function draw() {
        shadow.draw();
        sprite.draw();
    }

    override function unload() {
        sprite.unload();
        super.unload();
    }
}