package vampire.feeding.client {

import com.threerings.util.ArrayUtil;
import com.whirled.contrib.simplegame.*;
import com.whirled.contrib.simplegame.objects.*;

public class TipFactory
{
    public static const GRAB_WHITE :int = 0;
    public static const DROP_WHITE :int = 1;
    public static const GET_MULTIPLIER :int = 2;
    public static const GET_SPECIAL :int = 3;
    public static const POP_RED :int = 4;
    public static const CASCADE :int = 5;

    public static const NUM_TIPS :int = 6;

    public function createTip (type :int, owner :SceneObject) :SimObjectRef
    {
        // Have we already displayed this tip enough?
        if (MAX_TIP_COUNT[type] >= 0 && _tipCounts[type] >= MAX_TIP_COUNT[type]) {
            return SimObjectRef.Null();
        }

        // Are we already displaying a tip? Has it existed for longer than a few seconds?
        var existingTip :Tip = GameCtx.gameMode.getObjectNamed("Tip") as Tip;
        if (existingTip != null) {
            if (existingTip.type == type || existingTip.lifeTime < 5) {
                return SimObjectRef.Null();
            } else {
                existingTip.die();
            }
        }

        var tip :Tip = new Tip(type, owner);
        tip.offset.x = -tip.width * 0.5;
        tip.offset.y = -tip.height - 10;
        GameCtx.gameMode.addSceneObject(tip, GameCtx.uiLayer);

        _tipCounts[type] += 1;

        return tip.ref;
    }

    protected var _tipCounts :Array = ArrayUtil.create(NUM_TIPS, 0);

    protected static const MAX_TIP_COUNT :Array = [ -1, -1, -1, -1, 1, 2 ];
}

}

const TIP_TEXT :Array = [
    "Grab White Cells\nbefore they corrupt",
    "Drag White Cells\nto the arteries",
    "Catch Multipliers\nin cascades",
    "Catch Special Strains\nin cascades",
    "Pop Red Cells\nto create cascades",
    "Larger cascades\nscore more points",
];

function createTipText (type :int) :TextField
{
    return TextBits.createText(TIP_TEXT[type], 1.3, 0, 0xffffff, "center", TextBits.FONT_ARNO);
}

import com.whirled.contrib.simplegame.SimObject;
import com.whirled.contrib.simplegame.SimObjectRef;
import com.whirled.contrib.simplegame.objects.SceneObject;
import com.whirled.contrib.simplegame.components.SceneComponent;
import flash.text.TextField;

import vampire.feeding.client.*;
import com.threerings.flash.Vector2;
import com.threerings.whirled.data.SceneCodes;
import flash.geom.Point;
import flash.display.DisplayObject;
import com.whirled.contrib.simplegame.tasks.SerialTask;
import com.whirled.contrib.simplegame.tasks.AlphaTask;
import com.whirled.contrib.simplegame.tasks.SelfDestructTask;

class Tip extends SceneObject
{
    public var offset :Vector2 = new Vector2();

    public function Tip (type :int, owner :SceneObject)
    {
        _type = type;
        _tf = createTipText(type);
        _ownerRef = owner.ref;

        // Start invisible, so if a frame passes before we update our location, we
        // don't appear in the wrong place
        this.alpha = 0;
        addTask(new AlphaTask(1, 0.5));
    }

    public function die () :void
    {
        var deadTip :DeadTip = new DeadTip(_type);
        deadTip.x = this.x;
        deadTip.y = this.y;
        GameCtx.gameMode.addSceneObject(deadTip, GameCtx.uiLayer);

        destroySelf();
    }

    public function get type () :int
    {
        return _type;
    }

    public function get lifeTime () :Number
    {
        return _lifeTime;
    }

    override public function get displayObject () :DisplayObject
    {
        return _tf;
    }

    /*override public function getObjectGroup (groupNum :int) :String
    {
        switch (groupNum) {
        case 0:     return "Tip";
        case 1:     return "Tip_" + _type;
        default:    return super.getObjectGroup(groupNum - 2);
        }
    }*/

    override public function get objectName () :String
    {
        return "Tip";
    }

    override protected function update (dt :Number) :void
    {
        if (_dead) {
            return;
        }

        var owner :SceneObject = _ownerRef.object as SceneObject;
        if (owner == null || owner.displayObject == null || owner.displayObject.parent == null) {
            destroySelf();
            return;
        }

        _lifeTime += dt;

        var loc :Point = owner.displayObject.parent.localToGlobal(new Point(owner.x, owner.y));
        loc.x += offset.x;
        loc.y += offset.y;
        loc = this.displayObject.parent.globalToLocal(loc);
        this.x = loc.x;
        this.y = loc.y;
    }

    protected var _type :int;
    protected var _tf :TextField;
    protected var _ownerRef :SimObjectRef;
    protected var _lifeTime :Number = 0;
    protected var _dead :Boolean;
}

class DeadTip extends SceneObject
{
    public function DeadTip (type :int)
    {
        _tf = createTipText(type);
        addTask(new SerialTask(new AlphaTask(0, 0.5), new SelfDestructTask()));
    }

    override public function get displayObject () :DisplayObject
    {
        return _tf;
    }

    protected var _tf :TextField;
}
