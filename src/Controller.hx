import Rl;

class KeyboardController {
	var bindings:ActionBindings;

	public function new(bindings:ActionBindings) {
		this.bindings = bindings;
	}

	public function update() {
		if (Rl.isKeyPressed(ENTER)) {
			bindings.startPress();
		}

		if (Rl.isKeyReleased(ENTER)) {
			bindings.startRelease();
		}

		if (Rl.isKeyPressed(TAB)) {
			bindings.selectPress();
		}

		if (Rl.isKeyReleased(TAB)) {
			bindings.selectRelease();
		}

		if (Rl.isKeyPressed(UP)) {
			bindings.upPress();
		}

		if (Rl.isKeyReleased(UP)) {
			bindings.upRelease();
		}

		if (Rl.isKeyPressed(DOWN)) {
			bindings.downPress();
		}

		if (Rl.isKeyReleased(DOWN)) {
			bindings.downRelease();
		}

		if (Rl.isKeyPressed(LEFT)) {
			bindings.leftPress();
		}

		if (Rl.isKeyReleased(LEFT)) {
			bindings.leftRelease();
		}

		if (Rl.isKeyPressed(RIGHT)) {
			bindings.rightPress();
		}

		if (Rl.isKeyReleased(RIGHT)) {
			bindings.rightRelease();
		}

		if (Rl.isKeyPressed(W)) {
			bindings.upPress();
		}

		if (Rl.isKeyReleased(W)) {
			bindings.upRelease();
		}

		if (Rl.isKeyPressed(S)) {
			bindings.downPress();
		}

		if (Rl.isKeyReleased(S)) {
			bindings.downRelease();
		}

		if (Rl.isKeyPressed(A)) {
			bindings.leftPress();
		}

		if (Rl.isKeyReleased(A)) {
			bindings.leftRelease();
		}

		if (Rl.isKeyPressed(D)) {
			bindings.rightPress();
		}

		if (Rl.isKeyReleased(D)) {
			bindings.rightRelease();
		}

		if (Rl.isKeyPressed(G)) {
			bindings.aPress();
		}

		if (Rl.isKeyReleased(G)) {
			bindings.aRelease();
		}

		if (Rl.isKeyPressed(H)) {
			bindings.bPress();
		}

		if (Rl.isKeyReleased(H)) {
			bindings.bRelease();
		}
	}
}

@:structInit
@:publicFields
class ActionBindings {
	var startPress:Void->Void = () -> return;
	var startRelease:Void->Void = () -> return;

	var selectPress:Void->Void = () -> return;
	var selectRelease:Void->Void = () -> return;

	var aPress:Void->Void = () -> return;
	var aRelease:Void->Void = () -> return;

	var bPress:Void->Void = () -> return;
	var bRelease:Void->Void = () -> return;

	var upPress:Void->Void = () -> return;
	var upRelease:Void->Void = () -> return;

	var downPress:Void->Void = () -> return;
	var downRelease:Void->Void = () -> return;

	var leftPress:Void->Void = () -> return;
	var leftRelease:Void->Void = () -> return;

	var rightPress:Void->Void = () -> return;
	var rightRelease:Void->Void = () -> return;
}
