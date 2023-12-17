package dough.ui;

import Main.window;
import Rl.Font;
import dough.ui.ColorScheme;

class UI {
    public var font:Font;
    public var colors:ColorScheme;

    public function new(c:ColorScheme, font:Font) {
        colors = c;
        this.font = font;
        Rl.setTextureFilter(this.font.texture, Rl.TextureFilter.BILINEAR);
    }

    public function button(text:String, x:Float, y:Float, w:Int, h:Int):Bool {
        var rec = Rl.Rectangle.create(x, y, w, h);
        Rl.drawRectangleRec(rec, colors.bg);
        if(!Rl.checkCollisionPointRec(Rl.getMousePosition(), rec)) {
            Rl.drawRectangleLinesEx(rec, 1, colors.border);
        } else {
            Rl.drawRectangleLinesEx(rec, 1, colors.selectedBorder);
            if(Rl.isMouseButtonPressed(Rl.MouseButton.LEFT)) {
                return true;
            }
        }

        // text
        var pos = Rl.Vector2.create(x+w/4-text.length, y+h/4+8);
        Rl.drawTextEx(font, text, pos, 32, 0, colors.fg);

        return false;
    }

    public function popup(w:Float, h:Float):Bool {
        // fade everything else out
        Rl.drawRectangle(0, 0, window.width, window.height, Rl.Color.create(0, 0, 0, 150));
        var rec = Rl.Rectangle.create(window.width /2 - w/2, window.height /2 - (h+120)/2, w, h);
        Rl.drawRectangleRec(rec, colors.bg);
        Rl.drawRectangleLinesEx(rec, 1, colors.border);

        if(button("Done", window.width/2 - w/2, window.height/2+(h-100)/2, 120, 75)) return true;
        else return false;
    }
}