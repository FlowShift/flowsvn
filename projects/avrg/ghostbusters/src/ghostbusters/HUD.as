//
// $Id$

package ghostbusters {

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.text.TextField;
import flash.geom.Point;

import flash.events.Event;
import flash.events.MouseEvent;

import flash.utils.ByteArray;
import flash.utils.setTimeout;

import com.threerings.flash.DisplayUtil;
import com.threerings.flash.MathUtil;
import com.threerings.util.CommandEvent;

import ghostbusters.ClipHandler;
import ghostbusters.GameController;

import com.whirled.AVRGameAvatar;
import com.whirled.AVRGameControlEvent;

public class HUD extends Sprite
{
    public static const LOOT_LANTERN :int = 0;
    public static const LOOT_BLASTER :int = 1;
    public static const LOOT_OUIJA :int = 2;
    public static const LOOT_POTIONS :int = 3;

    public function HUD ()
    {
        _hud = new ClipHandler(ByteArray(new Content.HUD_VISUAL()), handleHUDLoaded);

        Game.control.state.addEventListener(
            AVRGameControlEvent.ROOM_PROPERTY_CHANGED, roomPropertyChanged);

        _listener = new PropertyListener(playerPropertyChanged);
    }

    public function shutdown () :void
    {
    }

    override public function hitTestPoint (
        x :Number, y :Number, shapeFlag :Boolean = false) :Boolean
    {
        return _hud != null && _hud.hitTestPoint(x, y, shapeFlag);
    }

    public function reloadView () :void
    {
        if (_hud.parent != null) {
            placeHud();
            teamUpdated();
        }
    }

    public function playerHealthUpdated (id :int) :void
    {
        setPlayerHealth(Game.model.getRelativeHealth(id));
    }

    public function ghostHealthUpdated () :void
    {
        setGhostHealth(Game.model.getRelativeGhostHealth(), false);
    }

    public function ghostZestUpdated () :void
    {
        setGhostHealth(Game.model.ghostRelativeZest, true);
    }

    public function getWeaponType () :int
    {
        return _lootIx;
    }

    public function teamUpdated () :void
    {
        if (_hud.parent == null || _visualHud == null) {
            // not ready yet
            return;
        }
        var players :Array = Game.control.getPlayerIds();
        if (players == null) {
            // offline mode -- don't flip out
            return;
        }
        var teamIx :int = 0;
        var hudIx :int = 0;
        while (hudIx < 6) {
            var bar :MovieClip = MovieClip(_playerHealthBars[hudIx]);
            var name :TextField = TextField(_playerNamePanels[hudIx]);
            if (teamIx >= players.length) {
                bar.visible = name.visible = false;
                hudIx ++;
                continue;
            }
//            if (players[teamIx] == Game.ourPlayerId) {
//                teamIx ++;
//                continue;
//            }
            var info :AVRGameAvatar = Game.control.getAvatarInfo(players[teamIx]);
            if (info == null) {
                // most likely explanation: they are not in our room
                teamIx ++;
                continue;
            }
            bar.visible = name.visible = true;
            bar.gotoAndStop(100 * Game.model.getRelativeHealth(players[teamIx]));
            name.text = info.name;
            teamIx ++;
            hudIx ++;
        }
    }

    protected function handleHUDLoaded (... ignored) :void
    {
        safelyAdd(HELP, helpClick);
        safelyAdd(CLOSE, closeClick);

        _playerHealthBars = new Array();
        _playerNamePanels = new Array();
        for (var ii :int = 1; ii <= 6; ii ++) {
            var bar :DisplayObject = findSafely(PLAYER_HEALTH_BAR + ii);
            if (bar == null) {
                Game.log.warning("Failed to find player health bar #" + ii);
                continue;
            }
            Game.log.debug("bar: " + bar);
            _playerHealthBars.push(bar);

            var panel :DisplayObject = findSafely(PLAYER_NAME_PANEL + ii);
            if (panel == null) {
                Game.log.warning("Failed to find player name panel #" + ii);
                continue;
            }
            Game.log.debug("panel: " + panel);
            _playerNamePanels.push(panel);
        }

        _yourHealthBar = MovieClip(findSafely(YOUR_HEALTH_BAR));
        _ghostHealthBar = MovieClip(findSafely(GHOST_HEALTH_BAR));
        _ghostCaptureBar = MovieClip(findSafely(GHOST_CAPTURE_BAR));

        _lanternLoot = SimpleButton(findSafely(EQP_LANTERN));
        _lanternLoot.addEventListener(MouseEvent.CLICK, lanternClick);

        _blasterLoot = SimpleButton(findSafely(EQP_BLASTER));
        _blasterLoot.addEventListener(MouseEvent.CLICK, lanternClick);

        _ouijaLoot = SimpleButton(findSafely(EQP_OUIJA));
        _ouijaLoot.addEventListener(MouseEvent.CLICK, lanternClick);

        _potionsLoot = SimpleButton(findSafely(EQP_POTIONS));
        _potionsLoot.addEventListener(MouseEvent.CLICK, lanternClick);

        _loots = [ _lanternLoot, _blasterLoot, _ouijaLoot, _potionsLoot ];
        _lootIx = 0;

        _inventory = MovieClip(findSafely(INVENTORY));
        _inventory.visible = true;

        _ghostInfo = MovieClip(findSafely(GHOST_INFO));
        _ghostInfo.visible = false; 

//        _weaponDisplay = MovieClip(findSafely(WEAPON_DISPLAY));
//        _weaponDisplay.visible = false; 

        safelyAdd(CHOOSE_LANTERN, function (evt :Event) :void { _lootIx = 0; });
        safelyAdd(CHOOSE_BLASTER, function (evt :Event) :void { _lootIx = 1; });
        safelyAdd(CHOOSE_OUIJA, function (evt :Event) :void { _lootIx = 2; });
        safelyAdd(CHOOSE_POTIONS, function (evt :Event) :void { _lootIx = 3; });

        _visualHud = MovieClip(findSafely(VISUAL_BOX));

        this.addChild(_hud);
        placeHud();
        teamUpdated();

        setGhostHealth(1, false);
        setGhostHealth(1, true);
    }

    protected function placeHud () :void
    {
        Game.log.debug("Looks like HUD's width is: " + _hud.width);
        Game.log.debug("Looks like Visual HUD's width is: " + _visualHud.width);

        // put the HUD to the right of the visible screen, or flush with the stage edge
        var x :int = Math.max(0, Math.min(Game.scrollSize.width - MARGIN_LEFT - BORDER_LEFT,
                                          Game.stageSize.right - _visualHud.width - MARGIN_LEFT));

        _hud.x = x;
        _hud.y = 0;

        Game.log.debug("Placing hud at (" + x + ", 0)...");

//        var width :int = Game.stageSize.right - Game.scrollSize.right;
//        if (width > 0) {
//            this.graphics.beginFill(0);
//            this.graphics.drawRect(Game.scrollSize.right + 1, 1,
//                                   width, Game.scrollSize.height);
//            this.graphics.endFill();
//        }
    }

    protected function findSafely (name :String) :DisplayObject
    {
        var o :DisplayObject = DisplayUtil.findInHierarchy(_hud, name);
        if (o == null) {
            throw new Error("Cannot find object: " + name);
        }
        return o;
    }

    protected function safelyAdd (name :String, callback :Function) :void
    {
        findSafely(name).addEventListener(MouseEvent.CLICK, callback);
    }

    protected function roomPropertyChanged (name :String, value :Object) :void
    {
        if (name == Codes.PROP_GHOST_HEALTH) {
            ghostHealthUpdated();

        } else if (name == Codes.PROP_GHOST_CUR_ZEST) {
            ghostZestUpdated();
        }
    }

    protected function playerPropertyChanged(memberId :int, name :String, value :Object) :void
    {
        if (name == Codes.PROP_PLAYER_HEALTH) {
            playerHealthUpdated(memberId);
        }
    }


//        _yourHealthBar.gotoAndStop(
//            100 * Game.gameController.model.getRelativeHealth(Game.ourPlayerId));

//        for (var ii :int = 0; ii < _loots.length; ii ++) {
//            SimpleButton(_loots[ii]).visible = (ii == _lootIx);
//        }


    protected function lanternClick (evt :Event) :void
    {
        CommandEvent.dispatch(this, GameController.TOGGLE_LANTERN);
    }

    protected function closeClick (evt :Event) :void
    {
        CommandEvent.dispatch(this, GameController.END_GAME);
    }

    protected function helpClick (evt :Event) :void
    {
        CommandEvent.dispatch(this, GameController.HELP);
    }

    protected function setGhostHealth (health :Number, isCapture :Boolean) :void
    {
        if (_ghostHealthBar == null || _ghostCaptureBar == null) {
            return;
        }
        var bar :MovieClip;
        var other :MovieClip;

        if (isCapture) {
            bar = _ghostCaptureBar;
            other = _ghostHealthBar;
        } else {
            bar = _ghostHealthBar;
            other = _ghostCaptureBar;
        }
        bar.visible = true;
        other.visible = false;

        // TODO: make use of all 100 frames!
        var frame :int = 76 - 75 * MathUtil.clamp(health, 0, 1);
        bar.gotoAndStop(frame);
        Game.log.debug("Moved " + bar + " to frame #" + frame);

        DisplayUtil.applyToHierarchy(bar, function (disp :DisplayObject) :void {
            if (disp is MovieClip) {
                MovieClip(disp).stop();
            }
        });
        DisplayUtil.applyToHierarchy(other, function (disp :DisplayObject) :void {
            if (disp is MovieClip) {
                MovieClip(disp).stop();
            }
        });
    }

    protected function setPlayerHealth (health :Number) :void
    {
        if (_playerHealthBars == null) {
            return;
        }
        var bar :MovieClip = _playerHealthBars[0];
        bar.visible = true;

        // TODO: make use of all 100 frames!
        var frame :int = 99 - 98 * MathUtil.clamp(health, 0, 1);
        bar.gotoAndStop(frame);
        Game.log.debug("Moved " + bar + " to frame #" + frame);

        DisplayUtil.applyToHierarchy(bar, function (disp :DisplayObject) :void {
            if (disp is MovieClip) {
                MovieClip(disp).stop();
            }
        });
    }

    protected var _listener :PropertyListener;

    protected var _hud :ClipHandler;
    protected var _visualHud :MovieClip;

    protected var _playerHealthBars :Array;
    protected var _playerNamePanels :Array;

    protected var _ghostHealthBar :MovieClip;
    protected var _ghostCaptureBar :MovieClip;
    protected var _yourHealthBar :MovieClip;

    protected var _lanternLoot :SimpleButton;
    protected var _blasterLoot :SimpleButton;
    protected var _ouijaLoot :SimpleButton;
    protected var _potionsLoot :SimpleButton;
    protected var _loots :Array;
    protected var _lootIx :int;

    protected var _inventory :MovieClip;
    protected var _ghostInfo :MovieClip;
//    protected var _weaponDisplay :MovieClip;

    protected static const HELP :String = "helpbutton";
    protected static const CLOSE :String = "closeButton";

    protected static const PLAYER_NAME_PANEL :String = "PlayerPanel";
    protected static const PLAYER_HEALTH_BAR :String = "PlayerHealth";
    protected static const YOUR_HEALTH_BAR :String = "YourHealth";

    protected static const GHOST_HEALTH_BAR :String = "GhostHealthBar";
    protected static const GHOST_CAPTURE_BAR :String = "GhostCaptureBar";

    protected static const VISUAL_BOX :String = "HUDmain";
    protected static const JUNK_BOX :String = "HUDtopbox";

    protected static const EQP_LANTERN :String = "equipped_lantern";
    protected static const EQP_BLASTER :String = "equipped_blaster";
    protected static const EQP_OUIJA :String = "equipped_ouija";
    protected static const EQP_POTIONS :String = "equipped_heal";

    protected static const INVENTORY :String = "inventory1";
    protected static const GHOST_INFO :String = "GhostInfoBox";
//    protected static const WEAPON_DISPLAY :String = "WeaponDisplay";

    protected static const CHOOSE_LANTERN :String = "choose_lantern";
    protected static const CHOOSE_BLASTER :String = "choose_blaster";
    protected static const CHOOSE_OUIJA :String = "choose_ouija";
    protected static const CHOOSE_POTIONS :String = "choose_heal";

    protected static const MARGIN_LEFT :int = 22;
    protected static const BORDER_LEFT :int = 33;
}
}
