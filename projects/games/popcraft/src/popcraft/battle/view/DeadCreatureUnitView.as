package popcraft.battle.view {

import com.whirled.contrib.simplegame.tasks.*;

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;

import popcraft.*;
import popcraft.battle.CreatureUnit;
import popcraft.util.PerfMonitor;

public class DeadCreatureUnitView extends BattlefieldSprite
{
    public function DeadCreatureUnitView (creature :CreatureUnit, facing :int)
    {
        _sprite = new Sprite();

        if (Constants.FACING_NE == facing) {
            facing = Constants.FACING_NW;
            _flipX = true;
        } else if (Constants.FACING_SE == facing) {
            facing = Constants.FACING_SW;
            _flipX = true;
        }

        var playerColor :uint = GameContext.gameData.playerColors[creature.owningPlayerIndex];
        var animName :String = "die_" + Constants.FACING_STRINGS[facing];

        if (PerfMonitor.framerate < Constants.USE_BITMAP_ANIM_FRAMERATE_THRESHOLD) {
            var bitmapAnim :BitmapAnim = CreatureAnimFactory.getBitmapAnim(creature.unitType,
                playerColor, animName);
            if (null == bitmapAnim) {
                bitmapAnim = CreatureAnimFactory.getBitmapAnim(creature.unitType, playerColor,
                    "die");
            }

            _bitmapAnimView = new BitmapAnimView(bitmapAnim);
            GameContext.gameMode.addObject(_bitmapAnimView, _sprite);

            // wait 2 seconds, then self destruct
            this.addTask(After(2, new SelfDestructTask()));

        } else {
            var movie :MovieClip = CreatureAnimFactory.instantiateUnitAnimation(
                creature.unitData, playerColor, animName);
            if (null == movie) {
                movie = CreatureAnimFactory.instantiateUnitAnimation(
                    creature.unitData, playerColor, "die");
            }

            _sprite.addChild(movie);

            // when the movie gets to the end, self-destruct
            this.addTask(new SerialTask(
                new WaitForFrameTask("end", movie),
                new SelfDestructTask()));
        }

        this.updateLoc(creature.x, creature.y);

        GameContext.playGameSound("sfx_death_" + creature.unitData.name);
    }

    override protected function addedToDB () :void
    {
        // BattlefieldSprite will scale us if necessary
        super.addedToDB();

        // flip if necessary
        if (_flipX) {
            _sprite.scaleX *= -1;
        }
    }

    override protected function removedFromDB () :void
    {
        if (_bitmapAnimView != null) {
            _bitmapAnimView.destroySelf();
        }

        super.removedFromDB();
    }

    override public function get displayObject () :DisplayObject
    {
        return _sprite;
    }

    protected var _sprite :Sprite;
    protected var _bitmapAnimView :BitmapAnimView;
    protected var _flipX :Boolean;
}

}
