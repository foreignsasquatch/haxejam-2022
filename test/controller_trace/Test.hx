import Rl;

import dough.Process;

import Controller;

class Test extends Process {
	var controller:KeyboardController;

	override function create() {
		Rl.setExitKey(ESCAPE);

		controller = new KeyboardController({
			startPress: () -> trace('start pressed once'),
			startRelease: () -> trace('start released once'),

			selectPress: () -> trace('select pressed once'),
			selectRelease: () -> trace('select released once'),

			upPress: () -> trace('up pressed once'),
			upRelease: () -> trace('up released once'),

			downPress: () -> trace('down pressed once'),
			downRelease: () -> trace('down released once'),

			leftPress: () -> trace('left pressed once'),
			leftRelease: () -> trace('left released once'),

			rightPress: () -> trace('right pressed once'),
			rightRelease: () -> trace('right released once'),
		});
	}

	override function update() {
		controller.update();
	}
}
