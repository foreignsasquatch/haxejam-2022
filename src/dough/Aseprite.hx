package dough;

import Rl.Vector2;
import ase.chunks.TagsChunk;
import Rl.RlImage;
import cpp.Pointer;
import Rl.Rectangle;
import Rl.Texture;
import ase.Frame;
import ase.Ase;

typedef ALayer = {
    tex:Texture,
    layerId:Int,
    frameId:Int,
}

@:structInit
class Tag {
  public var name(default, null):String;
  public var startFrame(default, null):Int;
  public var endFrame(default, null):Int;
  public var animationDirection(default, null):Int;

  public static function fromChunk(chunk:ase.chunks.TagsChunk.Tag):Tag {
    return {
      name: chunk.tagName,
      startFrame: chunk.fromFrame,
      endFrame: chunk.toFrame,
      animationDirection: chunk.animDirection
    }
  }
}

class Aseprite {
    public var ase:Ase;
    public var intermediateLayers:Array<ALayer> = [];
    public var intermediateFrames:Map<Int, Texture> = [];
    public var spritesheet:Texture;

    public var tags:Map<String, Tag> = [];
    // frame => duration
    // key is frame and value is duration
    public var duration:Map<Int, Float> = [];

    public var currentFrame:Int = 0;
    public var currentFrameDuration:Float;
    public var playingAnim:Bool = false;

    public var squashX:Float = 1;
    public var squashY:Float = 1;

    public var x:Float;
    public var y:Float;
    public var direction:Int = 1;

    public function new(x:Float, y:Float, file:String) {
        this.x = x;
        this.y = y;

        #if emscipten
        var aseBytes = haxe.Resource.getBytes(file);
        #else
        var aseBytes = sys.io.File.getBytes(file);
        #end
        ase = Ase.fromBytes(aseBytes);

        // generate intermediate layers
        for(f in 0...ase.frames.length) {
            var frame = ase.frames[f];
            for(layer in 0...ase.layers.length) {
                var t = texFromSingleLayer(layer, frame);
                intermediateLayers.push({tex: t, layerId: layer, frameId: f});
            }
        }

        for(f in 0...ase.frames.length) {
            var rt = Rl.loadRenderTexture(ase.width, ase.height);
            for(il in intermediateLayers) {
                if(il.frameId == f) {
                    var sourceRec = Rectangle.create(0, 0, ase.frames[f].cel(il.layerId).width, ase.frames[f].cel(il.layerId).height);

                    Rl.beginTextureMode(rt);
                    Rl.drawTexturePro(il.tex, sourceRec, Rl.Rectangle.create(ase.frames[f].cel(il.layerId).xPosition, ase.frames[f].cel(il.layerId).yPosition, ase.frames[f].cel(il.layerId).width, ase.frames[f].cel(il.layerId).height), Rl.Vector2.zero(), 0, Rl.Colors.WHITE);
                    Rl.endTextureMode();
                }
            }
            var it:RlImage = Rl.loadImageFromTexture(rt.texture);
            Rl.imageFlipVertical(cast(it));
            var ft = Rl.loadTextureFromImage(it);
            intermediateFrames.set(f, ft);
            Rl.unloadRenderTexture(rt);
        }

        // generate spritesheet
        var sprt = Rl.loadRenderTexture(ase.width * ase.frames.length, ase.height);
        var noi = 0;
        for(r in 0...ase.frames.length) {
            var i = intermediateFrames[r];
            Rl.beginTextureMode(sprt);
            Rl.drawTexture(i, 0 + (i.width * noi), 0, Rl.Colors.WHITE);
            Rl.endTextureMode();
            noi++;
        }
        var it:RlImage = Rl.loadImageFromTexture(sprt.texture);
        Rl.imageFlipVertical(cast(it));
        spritesheet = Rl.loadTextureFromImage(it);
        Rl.unloadRenderTexture(sprt);

        // delete all intermediates cause who needs them now
        for(i in intermediateFrames) {
            Rl.unloadTexture(i);
        }
        intermediateFrames.clear();

        for(i in intermediateLayers) {
            Rl.unloadTexture(i.tex);
            intermediateLayers.remove(i);
        }

        // get tags and duration
        for(frame in ase.frames) {
            for(chunk in frame.chunks) {
                switch (chunk.header.type) {
                    case TAGS:
                        var frameTags:TagsChunk = cast chunk;

                        for(frameTagData in frameTags.tags) {
                            var animationTag = Tag.fromChunk(frameTagData);

                            if(tags.exists(frameTagData.tagName)) {
                                throw 'ERROR: This file already contains a tag named ${frameTagData.tagName}';
                            } else  {
                                tags[frameTagData.tagName] = animationTag;
                            }
                        }
                    case _:
                }
            }

            duration[ase.frames.indexOf(frame)] = frame.duration;
        }

        currentFrameDuration = duration[currentFrame];
    }

    public function texFromSingleLayer(layer:Int, frame:Frame):Rl.Texture {
        var layerIndex:Int = layer;
        var celWidth:Int = frame.cel(layer).width;
        var celHeight:Int = frame.cel(layer).height;
        var celPixelData:haxe.io.Bytes = frame.cel(layerIndex).pixelData;
        var celDataPointer:cpp.Pointer<cpp.Void> = cpp.NativeArray.address(celPixelData.getData(), 0).reinterpret();
        var celImage = Rl.Image.create(celDataPointer.raw, celWidth, celHeight, 1, Rl.PixelFormat.UNCOMPRESSED_R8G8B8A8);
        var celTexture = Rl.loadTextureFromImage(celImage); 
        return celTexture;
    }

    public function play(name:String, loop:Bool = false) {
        var tag = tags[name];
        if(playingAnim) currentFrameDuration -= 100/6; // 1000/60 is 60fps in milliseconds
        if(currentFrameDuration <= 0) {
            if(currentFrame < tag.endFrame) currentFrame++;
            else if(currentFrame == tag.endFrame && !loop) playingAnim = false;
            else if(currentFrame == tag.endFrame && loop) currentFrame = tag.startFrame;

            currentFrameDuration = duration[currentFrame];
        }
    }

    public function draw() {
        var widthVisual = ase.width * squashX;
        var widthDif = ase.width - widthVisual;
        var xOffset = x + (widthDif / 2);

        var heightVisual = ase.height * squashY;
        var heightDif = ase.height - heightVisual;
        var yOffset = y + (heightDif / 2);

        Rl.drawTexturePro(spritesheet, Rl.Rectangle.create(0 + (ase.width * currentFrame), 0, ase.width * direction, ase.height), Rl.Rectangle.create(xOffset, yOffset, ase.width * squashX, ase.height *  squashY), Rl.Vector2.zero(), 0, Rl.Colors.WHITE);

        squashX += (1 - squashX) * Math.min(1, 0.2 * 0.6);
        squashY += (1 - squashY) * Math.min(1, 0.2 * 0.6);
    }

    public function unload() {
        Rl.unloadTexture(spritesheet);
    }

    public static function loadTexture(file:String):Rl.Texture {
        var aseBytes = sys.io.File.getBytes(file);
        var ase:ase.Ase = ase.Ase.fromBytes(aseBytes);
        var layerIndex:Int = 0;
        var frame = ase.frames[0];
        var celWidth:Int = frame.cel(layerIndex).width;
        var celHeight:Int = frame.cel(layerIndex).height;
        var celPixelData:haxe.io.Bytes = frame.cel(layerIndex).pixelData;
        var celDataPointer:cpp.Pointer<cpp.Void> = cpp.NativeArray.address(celPixelData.getData(), 0).reinterpret();
        var celImage = Rl.Image.create(celDataPointer.raw, celWidth, celHeight, 1, Rl.PixelFormat.UNCOMPRESSED_R8G8B8A8);
        var celTexture = Rl.loadTextureFromImage(celImage); 
        return celTexture; 
    }

    public function setSquashX(scaleX:Float) {
        squashY = 2 - scaleX;
        squashX = scaleX;
    }
    
    public function setSquashY(scaleY:Float) {
        squashX = 2 - scaleY;
        squashY = scaleY;
    }
}