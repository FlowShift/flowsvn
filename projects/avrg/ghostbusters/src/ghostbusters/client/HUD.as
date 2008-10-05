//
// $Id$

package ghostbusters.client {

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.text.TextField;
import flash.geom.Point;
import flash.geom.Rectangle;

import flash.events.Event;
import flash.events.MouseEvent;

import flash.utils.ByteArray;
import flash.utils.setTimeout;

import com.threerings.flash.DisplayUtil;
import com.threerings.flash.MathUtil;
import com.threerings.util.Command;
import com.threerings.util.Log;

import ghostbusters.client.ClipHandler;
import ghostbusters.client.GameController;
import ghostbusters.data.Codes;
import ghostbusters.client.util.GhostModel;
import ghostbusters.client.util.PlayerModel;

import com.whirled.avrg.AVRGameAvatar;
import com.whirled.avrg.AVRGameControlEvent;
import com.whirled.avrg.AVRGamePlayerEvent;
import com.whirled.net.PropertyChangedEvent;
import com.whirled.net.ElementChangedEvent;

public class HUD extends Sprite
{
    public function HUD ()
    {
        _hud = new ClipHandler(ByteArray(new Content.HUD_VISUAL()), handleHUDLoaded);

        Game.control.room.props.addEventListener(
            PropertyChangedEvent.PROPERTY_CHANGED, roomPropertyChanged);
        Game.control.room.props.addEventListener(
            ElementChangedEvent.ELEMENT_CHANGED, roomElementChanged);

        Game.control.player.props.addEventListener(
            PropertyChangedEvent.PROPERTY_CHANGED, playerPropertyChanged);
        Game.control.player.addEventListener(
            AVRGamePlayerEvent.ENTERED_ROOM, enteredRoom);

        Game.control.local.addEventListener(
            AVRGameControlEvent.SIZE_CHANGED, function (event :Event) :void {
                placeHud();
                teamUpdated();
            });
    }

    override public function hitTestPoint (
        x :Number, y :Number, shapeFlag :Boolean = false) :Boolean
    {
        return _hud != null && _hud.hitTestPoint(x, y, shapeFlag);
    }

    public function getRightEdge () :int
    {
        if (_visualHud != null) {
            var paintable :Rectangle = Game.control.local.getPaintableArea(true);
            if (paintable != null) {
                var scroll :Rectangle = Game.control.local.getPaintableArea(false);
                if (scroll != null) {
                    // put the HUD to the right of the visible screen, or flush with the stage edge
                    return Math.max(0, Math.min(scroll.width - MARGIN_LEFT - BORDER_LEFT,
                                                paintable.right - _visualHud.width - MARGIN_LEFT));
                } else {
                    _log.debug("getRightEdge: paintableArea(false) == null");
                }
            } else {
                _log.debug("getRightEdge: paintableArea(true) == null");
            }
        } else {
            _log.debug("getRightEdge: visualHud == null");
        }
        // wild guess while debugging
        return 700;
    }

    public function chooseWeapon (weapon :int) :void
    {
        _weaponIx = weapon;
        updateLootState();
    }

    public function getWeaponType () :int
    {
        return _weaponIx;
    }

    protected function enteredRoom (evt :AVRGamePlayerEvent) :void
    {
        teamUpdated();
        updateGhostHealth();
    }

    protected function playerPropertyChanged (evt :PropertyChangedEvent) :void
    {
        if (evt.name == Codes.PROP_MY_LEVEL) {
            _myLevel.text = String(evt.newValue);

        } else if (evt.name == Codes.PROP_MY_POINTS) {
            setPlayerPoints(int(evt.newValue));
        }
    }

    protected function roomPropertyChanged (evt :PropertyChangedEvent) :void
    {
        if (PlayerModel.parsePlayerProperty(evt.name) > 0) {
            teamUpdated();
        }
    }

    protected function roomElementChanged (evt :ElementChangedEvent) :void
    {
        if (evt.name == Codes.DICT_GHOST) {
            if (evt.key == Codes.IX_GHOST_CUR_ZEST || evt.key == Codes.IX_GHOST_MAX_ZEST ||
                evt.key == Codes.IX_GHOST_CUR_HEALTH || evt.key == Codes.IX_GHOST_MAX_HEALTH) {
                updateGhostHealth();
            }
            return;
        }

        var playerId :int = PlayerModel.parsePlayerProperty(evt.name);
        if (playerId > 0) {
            playerHealthUpdated(playerId);
        }
    }

    protected function handleHUDLoaded () :void
    {
        _ghostInfo = new GhostInfoView(_hud.clip);

        Command.bind(findSafely(HELP), MouseEvent.CLICK, GameController.HELP);
        Command.bind(findSafely(CLOSE), MouseEvent.CLICK, GameController.END_GAME);

        _playerPanels = new Array();

        for (var ii :int = 1; ii <= Codes.MAX_TEAM_SIZE; ii ++) {
            var panel :PlayerPanel = new PlayerPanel();

            var bar :MovieClip = findSafely(PLAYER_HEALTH_BAR + ii) as MovieClip;
            if (bar == null) {
                _log.warning("Failed to find player health bar #" + ii);
                continue;
            }
            panel.healthBar = bar;

            var plate :TextField = findSafely(PLAYER_NAME_PLATE + ii) as TextField;
            if (plate == null) {
                _log.warning("Failed to find player name plate #" + ii);
                continue;
            }
            panel.namePlate = plate;

            _playerPanels.push(panel);
        }

        _myLevel = findSafely(MY_LEVEL) as TextField;

        _myPointsBar = MovieClip(findSafely(MY_POINTS_BAR));

        _ghostHealthBar = MovieClip(findSafely(GHOST_HEALTH_BAR));
        _ghostCaptureBar = MovieClip(findSafely(GHOST_CAPTURE_BAR));

        _weaponButtons = new Array(BUTTON_NAMES.length);
        for (ii = 0; ii < BUTTON_NAMES.length; ii ++) {
            _weaponButtons[ii] = findSafely(BUTTON_NAMES[ii]);
            Command.bind(_weaponButtons[ii], MouseEvent.CLICK, GameController.TOGGLE_LANTERN);
        }

        _weaponIx = 0;

        _inventory = MovieClip(findSafely(INVENTORY));
        _inventory.visible = false;

        _visualHud = MovieClip(findSafely(VISUAL_BOX));

        this.addChild(_hud);
        placeHud();
        teamUpdated();

        updateGhostHealth();
        updateLootState();

        setPlayerPoints(int(Game.control.player.props.get(Codes.PROP_MY_POINTS)));

        _myLevel.text = String(Game.control.player.props.get(Codes.PROP_MY_LEVEL));
        Command.bind(_myLevel, MouseEvent.CLICK, GameController.GIMME_DEBUG_PANEL);
    }

    protected function updateLootState () :void
    {
        for (var ii :int = 0; ii < _weaponButtons.length; ii ++) {
            SimpleButton(_weaponButtons[ii]).visible = (ii == _weaponIx);
        }
    }

    protected function placeHud () :void
    {
        _log.debug("Looks like HUD's width is: " + _hud.width);
        _log.debug("Looks like Visual HUD's width is: " + _visualHud.width);

        _hud.x = getRightEdge();
        _hud.y = 0;

        _log.debug("Placing hud at (" + x + ", 0)...");
    }

    protected function findSafely (name :String) :DisplayObject
    {
        var o :DisplayObject = DisplayUtil.findInHierarchy(_hud, name);
        if (o == null) {
            throw new Error("Cannot find object: " + name);
        }
        return o;
    }

    protected function playerHealthUpdated (id :int) :void
    {
        setPlayerHealth(findPlayerIx(id),
                        Game.relative(PlayerModel.getHealth(id),
                                      PlayerModel.getMaxHealth(id)),
                        id == Game.ourPlayerId);
    }

    protected function updateGhostHealth () :void
    {
        if (_ghostHealthBar == null || _ghostCaptureBar == null) {
            return;
        }

        var bar :MovieClip;
        var other :MovieClip;
        var health :Number;

        if (Game.state == Codes.STATE_SEEKING || Game.state == Codes.STATE_APPEARING) {
            health = Game.relative(GhostModel.getZest(), GhostModel.getMaxZest());
            bar = _ghostCaptureBar;
            other = _ghostHealthBar;

        } else {
            health = Game.relative(GhostModel.getHealth(), GhostModel.getMaxHealth());
            bar = _ghostHealthBar;
            other = _ghostCaptureBar;
        }
        bar.visible = true;
        other.visible = false;

        // TODO: make use of all 100 frames!
        var frame :int = 76 - 75 * MathUtil.clamp(health, 0, 1);
        bar.gotoAndStop(frame);

        reallyStop(bar);
        reallyStop(other);
    }

    protected function teamUpdated () :void
    {
        if (this.stage == null || _hud.parent == null || _visualHud == null) {
            // not ready yet
            return;
        }
        if (Game.control.room.getAvatarInfo(Game.ourPlayerId) == null) {
            setTimeout(teamUpdated, 100);
            return;
        }

        var players :Array = PlayerModel.getTeam();
        var teamIx :int = 0;
        var hudIx :int = 0;
        while (hudIx < Codes.MAX_TEAM_SIZE) {
            var panel :PlayerPanel = PlayerPanel(_playerPanels[hudIx]);

            if (teamIx >= players.length) {
                panel.healthBar.visible = panel.namePlate.visible = false;
                panel.id = 0;
                hudIx ++;
                continue;
            }
//            if (players[teamIx] == Game.ourPlayerId) {
//                teamIx ++;
//                continue;
//            }
            var info :AVRGameAvatar = Game.control.room.getAvatarInfo(players[teamIx]);
            if (info == null) {
                // most likely explanation: they are not in our room
                teamIx ++;
                continue;
            }

            setPlayerHealth(
                teamIx, Game.relative(PlayerModel.getHealth(players[teamIx]),
                                      PlayerModel.getMaxHealth(players[teamIx])),
                players[teamIx] == Game.ourPlayerId);
            panel.namePlate.visible = true;
            panel.namePlate.text = info.name;
            panel.id = players[teamIx];
            teamIx ++;
            hudIx ++;
        }
    }

    protected function findPlayerIx (id :int) :int
    {
        if (_playerPanels != null) {
            for (var ii :int = 0; ii < Codes.MAX_TEAM_SIZE; ii ++) {
                if (_playerPanels[ii].id == id) {
                    return ii;
                }
            }
        }
        return -1;
    }

    protected function setPlayerHealth (ix :int, health :Number, us :Boolean) :void
    {
        if (ix < 0 || _playerPanels == null) {
            return;
        }
        // TODO: make use of all 100 frames!
        var frame :int = 99 - 98 * MathUtil.clamp(health, 0, 1);

        var bar :MovieClip = _playerPanels[ix].healthBar;
        bar.visible = true;
        bar.gotoAndStop(frame);
//        _log.debug("Moved " + bar.name + " to frame #" + frame);
        reallyStop(bar);
    }

    protected function setPlayerPoints (points :int) :void
    {
        _myPointsBar.gotoAndStop(99 - MathUtil.clamp(points, 0, 99));
        reallyStop(_myPointsBar);
    }

    protected function reallyStop (obj :DisplayObject) :void
    {
        DisplayUtil.applyToHierarchy(obj, function (disp :DisplayObject) :void {
            if (disp is MovieClip) {
                MovieClip(disp).stop();
            }
        });
    }

    protected var _hud :ClipHandler;
    protected var _visualHud :MovieClip;

    protected var _playerPanels :Array;

    protected var _ghostHealthBar :MovieClip;
    protected var _ghostCaptureBar :MovieClip;
    protected var _myPointsBar :MovieClip;
    protected var _myLevel :TextField;

    protected var _lanternLoot :SimpleButton;
    protected var _blasterLoot :SimpleButton;
    protected var _ouijaLoot :SimpleButton;
    protected var _potionsLoot :SimpleButton;
    protected var _weaponButtons :Array;
    protected var _weaponIx :int;

    protected var _inventory :MovieClip;
    protected var _ghostInfo :GhostInfoView;
//    protected var _weaponDisplay :MovieClip;

    protected static const HELP :String = "helpbutton";
    protected static const CLOSE :String = "closeButton";

    protected static const PLAYER_NAME_PLATE :String = "PlayerPanel";
    protected static const PLAYER_HEALTH_BAR :String = "PlayerHealth";

    protected static const MY_POINTS_BAR :String = "YourHealth";
    protected static const MY_LEVEL :String = "levelNumber";

    protected static const GHOST_HEALTH_BAR :String = "GhostHealthBar";
    protected static const GHOST_CAPTURE_BAR :String = "GhostCaptureBar";

    protected static const VISUAL_BOX :String = "HUDmain";
    protected static const JUNK_BOX :String = "HUDtopbox";

    // Note: The elements in this array must match the index in Codes.WPN_*
    protected static const BUTTON_NAMES :Array = [
        "equipped_lantern", "equipped_blaster", "equipped_ouija", "equipped_heal",
        ];

    protected static const INVENTORY :String = "inventory1";

//    protected static const WEAPON_DISPLAY :String = "WeaponDisplay";

    protected static const MARGIN_LEFT :int = 22;
    protected static const BORDER_LEFT :int = 33;

    protected static const _log :Log = Log.getLog(HUD);
}
}

import flash.display.MovieClip;
import flash.text.TextField;

class PlayerPanel
{
    public var id :int;
    public var healthBar :MovieClip;
    public var namePlate :TextField;
}
