import dough.Window;

var window = new Window();

function main() {
    window.width = 1280;
    window.height = 720;
    window.title = "Haxejam 2022 - Summer";
    window.resolution = {w: 640, h: 360};
    window.run(Menu);
}