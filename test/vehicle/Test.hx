import Rl;
import dough.Process;

import Controller;

class Test extends Process {
	var car:Vehicle;
	var controller:KeyboardController;

	override function create() {
		car = new Vehicle(100, 100);
		Rl.setExitKey(ESCAPE);
		

		controller = new KeyboardController({
			leftPress: () -> car.changeRotationDirection(-1),
			leftRelease: () -> car.changeRotationDirection(0),

			rightPress: () -> car.changeRotationDirection(1),
			rightRelease: () -> car.changeRotationDirection(0),

			aPress: () -> car.pressAccelerate(),
			aRelease: () -> car.releaseAccelerate()
		});

	}

	override function update() {
		controller.update();
		car.update();
	}

	override function draw() {
		car.draw();
	}

}


class Vehicle{
	var width:Float;
	var height:Float;
	var positionX:Float;
	var positionY:Float;
	var angle:Float;
	var rotationDirection:Int;
	var rotationSpeed:Float;
	var forwardSpeed:Float;
	var reverseSpeed:Float;
	var sin:Float;
	var cos:Float;
	var deltaX:Float;
	var deltaY:Float;
	var isAccelerating:Bool;
	var rect:Rectangle;
	var origin:RlVector2;
	var radians:Float;

	public function new(x:Float, y:Float){
		positionX = x;
		positionY = y;
		width = 16;
		height = 16;
		angle = 0.0;
		rotationDirection = 0;
		rotationSpeed = 1.5;
		forwardSpeed = 1.5;
		reverseSpeed = 1.5;
		isAccelerating = false;

		rect = Rl.Rectangle.create(positionX, positionY, width, height);
		origin = Rl.Vector2.create(width / 2, height / 2);
	}

	public function update()
	{
		angle += rotationSpeed * rotationDirection;
		radians = angle * 0.0174444;
		deltaX = Math.cos(radians);
		deltaY = Math.sin(radians);
				
		if(isAccelerating)
		{
			positionX += deltaX * forwardSpeed;
			positionY += deltaY * forwardSpeed;
		}

	}

	public function draw()
	{
		rect.x = positionX;
		rect.y = positionY;
		origin.x = width / 2;
		origin.y = height / 2;
		Rl.drawRectanglePro(rect, origin, angle, Colors.DARKBLUE);
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
}
