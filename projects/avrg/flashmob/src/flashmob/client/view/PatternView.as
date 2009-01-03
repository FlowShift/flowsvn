package flashmob.client.view {

import com.threerings.flash.DisplayUtil;
import com.threerings.util.Log;
import com.whirled.contrib.simplegame.objects.SceneObject;

import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;

import flashmob.client.*;
import flashmob.data.*;
import flashmob.util.SpriteUtil;

public class PatternView extends SceneObject
{
    public function PatternView (pattern :Pattern, draggedCallback :Function = null)
    {
        _pattern = pattern;
        _draggedCallback = draggedCallback;

        var draggable :Boolean = (draggedCallback != null);
        _sprite = SpriteUtil.createSprite(false, draggable);

        if (_pattern.locs.length > 0) {
            var shape :Shape = new Shape();
            var g :Graphics = shape.graphics;

            for each (var loc :PatternLoc in _pattern.locs) {
                g.lineStyle(2, 0);
                g.beginFill(0xFFFFFF);
                g.drawCircle(loc.x, loc.y, 12);
                g.endFill();
            }

            _sprite.addChild(shape);
        }

        if (draggable) {
            registerListener(_sprite, MouseEvent.MOUSE_DOWN, startDrag);
        }
    }

    protected function startDrag (...ignored) :void
    {
        if (!_dragging) {
            _dragOffsetX = -_sprite.mouseX;
            _dragOffsetY = -_sprite.mouseY;
            _dragging = true;

            registerListener(_sprite, MouseEvent.MOUSE_UP, endDrag);
        }
    }

    protected function endDrag (...ignored) :void
    {
        unregisterListener(_sprite, MouseEvent.MOUSE_UP, endDrag);
        updateDraggedLocation();

        _dragging = false;
    }

    protected function updateDraggedLocation () :void
    {
        if (_sprite.parent != null) {
            var newX :Number = _sprite.parent.mouseX + _dragOffsetX;
            var newY :Number = _sprite.parent.mouseY + _dragOffsetY;
            if (newX != this.x || newY != this.y) {
                this.x = newX;
                this.y = newY;
                _draggedCallback(newX, newY);
            }
        }
    }

    override protected function update (dt :Number) :void
    {
        super.update(dt);

        if (_dragging) {
            updateDraggedLocation();
        }
    }

    override public function get displayObject () :DisplayObject
    {
        return _sprite;
    }

    protected static function get log () :Log
    {
        return FlashMobClient.log;
    }

    protected var _pattern :Pattern;
    protected var _draggedCallback :Function;

    protected var _sprite :Sprite;

    protected var _dragOffsetX :Number;
    protected var _dragOffsetY :Number;
    protected var _dragging :Boolean;
}

}