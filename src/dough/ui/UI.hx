package dough.ui;

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
        var pos = Rl.Vector2.create(x+w/4+16, y+h/4+8);
        Rl.drawTextEx(font, text, pos, 32, 0, colors.fg);

        return false;
    }
}