import dough.Window;

var window = new Window();

function main() {
    window.width = 1280;
    window.height = 720;
    window.title = "Haxejam 2022 - Summer";
    window.resolution = {w: 320, h: 180};
    window.run(Menu);
}