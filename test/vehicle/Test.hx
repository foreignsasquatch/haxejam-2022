import dough.tilemap.CollisionData;
import Rl;
import dough.Process;
import Controller;

class Test extends Process {
	var car:Vehicle;
	var currentCarIndex:Int;
	var controller:KeyboardController;
	var font:Font;
	var levelTiles:Array<Rectangle> = [];
	var collisionData:CollisionData;
	var background:Texture2D;
	var backgroundSize:Rectangle;
	var camera:Camera2D;

	override function create() {
		camera = Rl.Camera2D.create(Rl.Vector2.create(0, 0), Rl.Vector2.create(0, 0));
		Rl.setExitKey(ESCAPE);

		font = Rl.loadFont("resources/font/ubuntu.ttf");
		var backgroundImage = Rl.loadImage("resources/png/track_example.png");
		background = Rl.loadTextureFromImage(backgroundImage);
		backgroundSize = Rl.Rectangle.create(0, 0, background.width, background.height);

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

		currentCarIndex = 0;
		var config = loadConfig(cars[currentCarIndex]);
		car = new Vehicle(config);

		car.setCoords(67 * gridSize, 65 * gridSize, gridSize);

		var steeringButtons:ButtonPair = {
			onPressA: () -> car.changeRotationDirection(-1),
			onReleaseA: () -> car.changeRotationDirection(0),

			onPressB: () -> car.changeRotationDirection(1),
			onReleaseB: () -> car.changeRotationDirection(0),
		}

		controller = new KeyboardController({
			leftPress: () -> steeringButtons.controlA(true),
			leftRelease: () -> steeringButtons.controlA(false),

			rightPress: () -> steeringButtons.controlB(true),
			rightRelease: () -> steeringButtons.controlB(false),

			aPress: () -> car.pressAccelerate(),
			aRelease: () -> car.releaseAccelerate(),

			bPress: () -> car.pressBrake(),
			bRelease: () -> car.releaseBrake(),

			// press tab to cycle through car configurations
			selectPress: () -> {
				currentCarIndex = (currentCarIndex + cars.length + 1) % cars.length;
				var config = loadConfig(cars[currentCarIndex]);
				car.configure(config);
			}
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
		camera.offset.x = window.resolution.w / 2;
		camera.offset.y = window.resolution.h / 2;
		camera.target.x = targetX;
		camera.target.y = targetY;
	}

	override function draw() {
		Rl.beginMode2D(camera);

		Rl.drawTexture(background, 0, 0, Colors.WHITE);

		car.draw();

		for (rect in levelTiles) {
			Rl.drawRectangle(Std.int(rect.x), Std.int(rect.y), Std.int(rect.width), Std.int(rect.height), Colors.VIOLET);
		}

		var carCoords = '${Std.int(car.gridX)},${Std.int(car.gridY)}';
		var carThrottle = '${car.throttle}'.substr(0, 3);
		Rl.drawTextEx(font, '$carCoords $carThrottle', car.center, 16, 0, Colors.LIGHTGRAY);

		Rl.endMode2D();
	}

	override function unload() {
		Rl.unloadFont(font);
		Rl.unloadTexture(background);
	}

	/** converts configurations with durations expressed in seconds to durations expressed in total frame for that same amount of time **/
	function loadConfig(config:VehicleConfig):VehicleConfig {
		return {
			color: config.color,
			forwardSpeed: config.forwardSpeed,
			rotateSpeed: config.rotateSpeed,
			accelerationCurve: {
				press: {
					easeFunction: config.accelerationCurve.press.easeFunction,
					duration: window.toFrameCount(config.accelerationCurve.press.duration)
				},
				release: {
					easeFunction: config.accelerationCurve.release.easeFunction,
					duration: window.toFrameCount(config.accelerationCurve.release.duration)
				}
			},
			brakeCurve: {
				press: {
					easeFunction: config.brakeCurve.press.easeFunction,
					duration: window.toFrameCount(config.brakeCurve.press.duration)
				},
				release: {
					easeFunction: config.brakeCurve.release.easeFunction,
					duration: window.toFrameCount(config.brakeCurve.release.duration)
				}
			},
			steeringCurve: {
				press: {
					easeFunction: config.steeringCurve.press.easeFunction,
					duration: window.toFrameCount(config.steeringCurve.press.duration)
				},
				release: {
					easeFunction: config.steeringCurve.release.easeFunction,
					duration: window.toFrameCount(config.steeringCurve.release.duration)
				}
			}
		}
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
	var angle:Float;
	var radians:Float;
	var sin:Float;
	var cos:Float;

	var deltaX:Float;
	var deltaY:Float;

	var throttle:Float;
	var accelerator:Curve;
	var brake:Curve;
	var steering:Curve;

	public var config:VehicleConfig;

	var color:Color;

	public function new(config:VehicleConfig) {
		this.config = config;
		positionX = 0;
		positionY = 0;
		width = 16;
		height = 16;

		rect = Rl.Rectangle.create(positionX, positionY, width, height);
		origin = Rl.Vector2.create(width / 2, height / 2);
		center = Rl.Vector2.create(positionX - origin.x, positionY - origin.y);

		angle = 0.0;
		configure(config);
	}

	public function configure(config:VehicleConfig) {
		color = rgbaToColor(config.color);
		accelerator = new Curve(config.accelerationCurve);
		brake = new Curve(config.brakeCurve);
		steering = new Curve(config.steeringCurve);
		this.config = config;
	}

	public function update() {
		angle += (steering.next() * config.rotateSpeed) * rotationDirection;
		radians = angle * 0.0174444;

		deltaX = Math.cos(radians);
		deltaY = Math.sin(radians);

		if (brake.isPressed) {
			throttle -= brake.next();
		} else {
			throttle += accelerator.next();
		}

		if (throttle < 0) {
			throttle = 0;
		}

		if (throttle > 1) {
			throttle = 1;
		}

		positionX += deltaX * (config.forwardSpeed * throttle);
		positionY += deltaY * (config.forwardSpeed * throttle);

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

		Rl.drawRectanglePro(rect, origin, angle, color);
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
		if (rotationDirection == 0) {
			steering.release();
		} else {
			steering.press();
		}
	}

	public function pressAccelerate() {
		if (brake.isPressed) {
			releaseBrake();
		}
		trace('pressAcc');
		accelerator.press();
	}

	public function releaseAccelerate() {
		trace('releaseAcc');
		accelerator.release();
	}

	public function pressBrake() {
		trace('pressBrake');
		brake.press();
	}

	public function releaseBrake() {
		trace('releaseBrake');
		brake.release();
		if (accelerator.isPressed) {
			pressAccelerate();
		}
	}

	public function handleCollisions(collisionData:CollisionData) {
		if (throttle > 0 && collisionData.exists(gridX, gridY)) {
			throttle = 0;
		}
	}
}

typedef Transformation = (t:Float) -> Float;
var instant:Transformation = t -> 1;
var never:Transformation = t -> 0;
var linear:Transformation = t -> t;
var smoothStart2:Transformation = t -> t * t;
var smoothStart3:Transformation = t -> t * t * t;
var smoothStart5:Transformation = t -> t * t * t * t * t;
var smoothStop3:Transformation = t -> (t - 1) * (t - 1) * (t - 1) + 1;

class Ease {
	var minimum:Float = 0;
	var maximum:Float = 1;
	var duration:Float;
	var transformation:Transformation;
	var time:Float;

	public function new(duration:Float, transformation:Transformation) {
		reset(duration, transformation);
	}

	public function reset(duration:Float, transformation:Transformation) {
		this.time = 0;
		this.duration = duration;
		this.transformation = transformation;
	}

	/** 
		advance internal time and return interpolated value
	**/
	public function step(delta:Float):Float {
		var valueStepped = valueAtTime(time);
		time += delta;
		// trace(valueStepped);
		return valueStepped;
	}

	/**
		return interpolated value for the absolute time
	**/
	public inline function valueAtTime(absoluteTime:Float) {
		return absoluteTime > duration ? maximum : interpolate(absoluteTime);
	}

	public function resetTime() {
		time = 0;
	}

	inline function interpolate(time:Float) {
		var t = (minimum * (1 - time) + maximum * time) /= duration;
		var a:Float = transformation(t);
		return maximum * a + minimum * (1 - a);
	}
}

@:publicFields
@:structInit
class CurveConfig {
	var press:Easing;
	var release:Easing;
}

@:publicFields
@:structInit
class Easing {
	var easeFunction:Transformation;
	var duration:Float;
}

class Curve {
	var config:CurveConfig;
	var easePress:Ease;
	var easeRelease:Ease;

	public var isPressed:Bool;

	public function new(config:CurveConfig) {
		this.config = config;
		this.easePress = new Ease(config.press.duration, config.press.easeFunction);
		this.easeRelease = new Ease(config.release.duration, config.release.easeFunction);
		isPressed = false;
	}

	public function next():Float {
		if (isPressed) {
			return easePress.step(1);
		}
		return -easeRelease.step(1);
	}

	public function press() {
		isPressed = true;
		easePress.resetTime();
	}

	public function release() {
		isPressed = false;
		easeRelease.resetTime();
	}
}

@:structInit
@:publicFields
class VehicleConfig {
	var color:Int;
	var forwardSpeed:Float;
	var accelerationCurve:CurveConfig;
	var brakeCurve:CurveConfig;

	var rotateSpeed:Float;
	var steeringCurve:CurveConfig;
}

@:structInit
class ButtonPair {
	var onPressA:() -> Void = () -> return;
	var onReleaseA:() -> Void = () -> return;
	var isPressedA:Bool = false;

	var onPressB:() -> Void = () -> return;
	var onReleaseB:() -> Void = () -> return;
	var isPressedB:Bool = false;

	public function controlA(isButtonPressed:Bool) {
		if (isButtonPressed) {
			isPressedA = true;
			onPressA();
		} else {
			isPressedA = false;
			if (isPressedB) {
				onPressB();
			} else {
				onReleaseA();
			}
		}
	}

	public function controlB(isButtonPressed:Bool) {
		if (isButtonPressed) {
			isPressedB = true;
			onPressB();
		} else {
			isPressedB = false;
			if (isPressedA) {
				onPressA();
			} else {
				onReleaseB();
			}
		}
	}
}


// forward speed is pixels per frame
// rotate speed is angles per frame
// durations are measured in seconds
// speeds are eased towards the full amount and will only change by the defined amount when the duration has expired
// the easing function can be changed
var cars:Array<VehicleConfig> = [
	{
		color: 0x0052acff,
		forwardSpeed: 8.5,
		rotateSpeed: 3.5,
		accelerationCurve: {
			press: {
				easeFunction: t -> smoothStart2(t) + 0.009, // 0.009 is used to raise the minimum above 0 (and start movement immediately) todo: make this offset a parameter
				duration: 22.2, // take 22.2 seconds to reach the speed of 8.5 pixels per frame
			},
			release: {
				easeFunction: smoothStart2,
				duration: 11.2,
			}
		},
		brakeCurve: {
			press: {
				easeFunction: smoothStart2,
				duration: 7.1
			},
			release: {
				easeFunction: never,
				duration: 0
			}
		},
		steeringCurve: {
			press: {
				easeFunction: smoothStop3,
				duration: 0.75
			},
			release: {
				easeFunction: instant,
				duration: 0
			}
		}
	},
	{
		color: 0xaa33acff,
		forwardSpeed: 15.5,
		rotateSpeed: 4.5,
		accelerationCurve: {
			press: {
				easeFunction: t -> smoothStart2(t) + 0.019,
				duration: 12.2,
			},
			release: {
				easeFunction: smoothStart2,
				duration: 19.2,
			}
		},
		brakeCurve: {
			press: {
				easeFunction: smoothStart2,
				duration: 7.1
			},
			release: {
				easeFunction: never,
				duration: 0
			}
		},
		steeringCurve: {
			press: {
				easeFunction: smoothStop3,
				duration: 3.3
			},
			release: {
				easeFunction: instant,
				duration: 0
			}
		}
	},
	{
		color: 0xa8a839ff,
		forwardSpeed: 5.5,
		rotateSpeed: 9.5,
		accelerationCurve: {
			press: {
				easeFunction: t -> smoothStart2(t) + 0.009,
				duration: 40.2,
			},
			release: {
				easeFunction: smoothStart2,
				duration: 10.2,
			}
		},
		brakeCurve: {
			press: {
				easeFunction: smoothStart2,
				duration: 2.1
			},
			release: {
				easeFunction: never,
				duration: 0
			}
		},
		steeringCurve: {
			press: {
				easeFunction: smoothStop3,
				duration: 25.75
			},
			release: {
				easeFunction: instant,
				duration: 0
			}
		}
	}
];

function rgbaToColor(rgba:Int):Color {
	return Rl.Color.create((rgba >> 24) & 255, (rgba >> 16) & 255, (rgba >> 8) & 255, (rgba) & 255);
}
