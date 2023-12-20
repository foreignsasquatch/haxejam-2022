import dough.tilemap.CollisionData;
import Rl;
import dough.Process;
import Controller;

class Test extends Process {
	var car:Vehicle;
	var steeringController:SteeringController;
	var controller:KeyboardController;
	var font:Font;
	var levelTiles:Array<Rectangle> = [];
	var collisionData:CollisionData;
	var background:Texture2D;
	var backgroundSize:Rectangle;

	override function create() {
		
		Rl.setExitKey(ESCAPE);

		font = Rl.loadFont("resources/font/ubuntu.ttf");
		var backgroundImage = Rl.loadImage("resources/png/track_example.png");
		background = Rl.loadTextureFromImage(backgroundImage);
		backgroundSize = Rl.Rectangle.create(0,0,background.width, background.height);

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

		var secondsForAcceleratorToReachMaximum = 2.2;
		var framesForAcceleratorToReachMaximum = window.toFrameCount(secondsForAcceleratorToReachMaximum);

		car = new Vehicle(framesForAcceleratorToReachMaximum);
		car.setCoords(100, 100, gridSize);

		steeringController = {
			onPressLeft: () -> car.changeRotationDirection(-1),
			onPressRight: () -> car.changeRotationDirection(1),
			onReleaseLeft: () -> car.changeRotationDirection(0),
			onReleaseRight: () -> car.changeRotationDirection(0),
		}

		controller = new KeyboardController({
			leftPress: () -> steeringController.controlLeft(true),
			leftRelease: () -> steeringController.controlLeft(false),

			rightPress: () -> steeringController.controlRight(true),
			rightRelease: () -> steeringController.controlRight(false),

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
		updateCameraCenter(car.center.x, car.center.y);
	}

		/**
		Center camera on target
	**/
	public function updateCameraCenter(targetX:Float, targetY:Float) {
		window.camera.offset.x = window.resolution.w / 2;
		window.camera.offset.y = window.resolution.h / 2;
		window.camera.target.x = targetX;
		window.camera.target.y = targetY;
	}

	override function draw() {

		Rl.drawTexture(background, 0,0, Colors.WHITE);
		// Rl.imageDraw(background, background, backgroundSize, backgroundSize, Colors.WHITE);

		car.draw();
		for (rect in levelTiles) {
			Rl.drawRectangle(Std.int(rect.x), Std.int(rect.y), Std.int(rect.width), Std.int(rect.height), Colors.VIOLET);
		}
		var carCoords = '${Std.int(car.gridX)},${Std.int(car.gridY)}';
		var carThrottle = '${car.throttle}'.substr(0, 3);
		Rl.drawTextEx(font, '$carCoords $carThrottle', car.center, 16, 0, Colors.LIGHTGRAY);
	}

	override function unload() {
		Rl.unloadFont(font);
		Rl.unloadTexture(background);
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
	var acceleratorEasing:Ease;
	var throttleOpeningRate:Float;

	public function new(framesForAcceleratorToReachMaximum:Float) {
		positionX = 0;
		positionY = 0;
		width = 16;
		height = 16;

		rect = Rl.Rectangle.create(positionX, positionY, width, height);
		origin = Rl.Vector2.create(width / 2, height / 2);
		center = Rl.Vector2.create(positionX - origin.x, positionY - origin.y);
		
		angle = 0.0;
		rotationSpeed = 2.5;  // angle per frame
		rotationDirection = 0;

		speed = 7.5; // pixels per frame
		throttle = 0.0;
		throttleOpeningRate = 0.6;
		isAccelerating = false;
		isBraking = false;

		acceleratorEasing = new Ease(framesForAcceleratorToReachMaximum, smoothStart2);
	}

	public function update() {
		angle += rotationSpeed * rotationDirection;
		radians = angle * 0.0174444;

		deltaX = Math.cos(radians);
		deltaY = Math.sin(radians);

		if (isAccelerating) {
			throttle += throttleOpeningRate * acceleratorEasing.step(1);
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
		acceleratorEasing.resetTime();
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

typedef Transformation = (t: Float) -> Float;

var linear: Transformation = t -> t;
var smoothStart2: Transformation = t -> t * t;
var smoothStart3: Transformation = t -> t * t * t;
var smoothStart5: Transformation = t -> t * t * t * t * t;
var smoothStop3: Transformation = t -> (t - 1) * (t - 1) * (t - 1) + 1;


class Ease
{
	var minimum: Float = 0;
	var maximum: Float = 1;
	var duration: Float;
	var transformation: Transformation;
	var time: Float;

	public function new(duration: Float, transformation: Transformation)
	{
		reset(
			duration,
			transformation
		);
	}

	public function reset(duration: Float, transformation: Transformation)
	{
		this.time = 0;
		this.duration = duration;
		this.transformation = transformation;
	}

	/** 
		advance internal time and return interpolated value
	**/
	public function step(delta: Float): Float
	{
		var valueStepped = valueAtTime(time);
		time += delta;
		trace(valueStepped);
		return valueStepped;
	}

	/**
		return interpolated value for the absolute time
	**/
	public inline function valueAtTime(absoluteTime: Float)
	{
		return absoluteTime > duration ? maximum : interpolate(absoluteTime);
	}

	public function resetTime()
	{
		time = 0;	
	}

	inline function interpolate(time: Float)
	{
		var t = (minimum * (1 - time) + maximum * time) /= duration;
		var a: Float = transformation(t);
		return maximum * a + minimum * (1 - a);
	}
}

@:structInit
class SteeringController {
	var onPressLeft:() -> Void = () -> return;
	var onPressRight:() -> Void = () -> return;
	var onReleaseLeft:() -> Void = () -> return;
	var onReleaseRight:() -> Void = () -> return;
	var isPressedLeft:Bool = false;
	var isPressedRight:Bool = false;

	public function controlLeft(isButtonPressed:Bool) {
		if (isButtonPressed) {
			isPressedLeft = true;
			onPressLeft();
		} else {
			isPressedLeft = false;
			if (isPressedRight) {
				onPressRight();
			} else {
				onReleaseLeft();
			}
		}
	}

	public function controlRight(isButtonPressed:Bool) {
		if (isButtonPressed) {
			isPressedRight = true;
			onPressRight();
		} else {
			isPressedRight = false;
			if (isPressedLeft) {
				onPressLeft();
			} else {
				onReleaseRight();
			}
		}
	}
}
