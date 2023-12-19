import dough.tilemap.CollisionData;
import Rl;
import dough.Process;
import Controller;

class Test extends Process {
	var car:Vehicle;
	var controller:KeyboardController;
	var font:Font;
	var levelTiles:Array<Rectangle> = [];
	var collisionData:CollisionData;

	override function create() {
		Rl.setExitKey(ESCAPE);
		
		font = Rl.loadFont("resources/font/ubuntu.ttf");

		var gridSize = 16;
		var tilesWide = 200;
		var tilesHigh = 100;

		// set some test tiles on the first column of the grid
		var isFirstColumn:Int->Bool = index -> index % tilesWide == 0;
		var tileMap = [for (index in 0...tilesWide * tilesHigh) isFirstColumn(index) ? 1 : 0];
		collisionData = new CollisionData(tilesWide, tilesHigh, tileMap);

		// init tile rects to draw
		levelTiles = [];
		for (index => tileId in collisionData.data) {
			if (tileId == 1) {
				var x = collisionData.column(index) * gridSize;
				var y = collisionData.row(index) * gridSize;
				var rect:Rectangle = Rl.Rectangle.create(x, y, gridSize, gridSize);
				levelTiles.push(rect);
			}
		}

		car = new Vehicle();
		car.setCoords(100, 100, gridSize);

		controller = new KeyboardController({
			leftPress: () -> car.changeRotationDirection(-1),
			leftRelease: () -> car.changeRotationDirection(0),

			rightPress: () -> car.changeRotationDirection(1),
			rightRelease: () -> car.changeRotationDirection(0),

			aPress: () -> car.pressAccelerate(),
			aRelease: () -> car.releaseAccelerate(),

			bPress: () -> car.pressBrake(),
			bRelease: () -> car.releaseBrake(),
		});
	}

	override function update() {
		car.handleCollisions(collisionData);
		controller.update();
		car.update();
	}

	override function draw() {
		car.draw();
		for (rect in levelTiles) {
			Rl.drawRectangle(Std.int(rect.x), Std.int(rect.y), Std.int(rect.width), Std.int(rect.height), Colors.VIOLET);
		}
		var carCoords = '${Std.int(car.gridX)},${Std.int(car.gridY)}';
		var carThrottle = '${car.throttle}'.substr(0, 3);
		Rl.drawTextEx(font, '$carCoords $carThrottle', car.center, 16, 0, Colors.LIGHTGRAY);
	}
}

@:publicFields
class Vehicle {
	var gridX:Int;
	var gridY:Int;
	var gridSize:Float;
	var gridRatioX:Float;
	var gridRatioY:Float;

	var positionX:Float;
	var positionY:Float;
	var width:Float;
	var height:Float;
	var rect:Rectangle;
	var origin:RlVector2;
	var center:RlVector2;

	var rotationDirection:Int;
	var rotationSpeed:Float;
	var angle:Float;
	var radians:Float;
	var sin:Float;
	var cos:Float;
	
	var deltaX:Float;
	var deltaY:Float;

	var throttle:Float;
	var speed:Float;
	var isAccelerating:Bool;
	var isBraking:Bool;

	public function new() {
		positionX = 0;
		positionY = 0;
		width = 16;
		height = 16;

		rect = Rl.Rectangle.create(positionX, positionY, width, height);
		origin = Rl.Vector2.create(width / 2, height / 2);
		center = Rl.Vector2.create(positionX - origin.x, positionY - origin.y);
		
		angle = 0.0;
		rotationSpeed = 1.5;  // angle per frame
		rotationDirection = 0;

		speed = 1.5; // pixels per frame
		throttle = 0.0;
		isAccelerating = false;
		isBraking = false;
	}

	public function update() {
		angle += rotationSpeed * rotationDirection;
		radians = angle * 0.0174444;

		deltaX = Math.cos(radians);
		deltaY = Math.sin(radians);

		if (isAccelerating) {
			throttle += 0.015;
		} else {
			throttle -= 0.0075;
		}

		if (isBraking) {
			throttle -= 0.015;
		}

		if (throttle < 0) {
			throttle = 0;
		}

		if (throttle > 1) {
			throttle = 1;
		}

		positionX += deltaX * (speed * throttle);
		positionY += deltaY * (speed * throttle);

		center.x = positionX - origin.x;
		center.y = positionY - origin.y;

		gridY = Std.int(center.y / gridSize);
		gridX = Std.int(center.x / gridSize);
	}

	public function draw() {
		rect.x = positionX;
		rect.y = positionY;
		origin.x = width / 2;
		origin.y = height / 2;

		Rl.drawRectanglePro(rect, origin, angle, Colors.DARKBLUE);
	}

	public function setCoords(x:Float, y:Float, gridSize:Float) {
		this.gridSize = gridSize;
		positionX = x;
		positionY = y;
		gridX = Std.int(x / gridSize);
		gridY = Std.int(y / gridSize);
		gridRatioX = (x - gridX * gridSize) / gridSize;
		gridRatioY = (y - gridY * gridSize) / gridSize;
		center.x = positionX - origin.x;
		center.y = positionY - origin.y;
	}

	public function changeRotationDirection(direction:Int) {
		rotationDirection = direction;
	}

	public function pressAccelerate() {
		isAccelerating = true;
	}

	public function releaseAccelerate() {
		isAccelerating = false;
	}

	public function pressBrake() {
		isBraking = true;
	}

	public function releaseBrake() {
		isBraking = false;
	}

	public function handleCollisions(collisionData:CollisionData) {
		if (throttle > 0 && collisionData.exists(gridX, gridY)) {
			throttle = 0;
		}
	}
}
