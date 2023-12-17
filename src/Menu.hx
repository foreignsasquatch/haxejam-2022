import dough.ui.ColorScheme;
import dough.Process;
import dough.ui.UI;

class Menu extends Process {
    public var ui:UI;

    override function create() {
        var colors:ColorScheme = {
            bg: Rl.getColor(0x18191AFF),
            fg: Rl.getColor(0xE4E6EBFF),
            border: Rl.getColor(0x242526FF),
            selectedBorder: Rl.getColor(0xB0B3B8FF)
        }
        ui = new UI(colors, Rl.loadFont("resources/font/ubuntu.ttf"));
    }

    override function update() {
    }

    override function draw() {
    }

    override function drawUI() {
        if(ui.button("play", 10, 10, 200, 100)) Process.set(Game);
    }

    override function unload() {
        Rl.unloadFont(ui.font);
    }
}