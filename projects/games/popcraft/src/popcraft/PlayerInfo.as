package popcraft {

import com.threerings.util.Log;
import com.whirled.contrib.simplegame.SimObjectRef;

import flash.events.EventDispatcher;

import popcraft.battle.PlayerBaseUnit;

/**
 * Encapsulates public information about a player in the game.
 */
public class PlayerInfo extends EventDispatcher
{
    public function PlayerInfo (playerId :int, teamId :int, handicap :Number = 1, playerName :String = null)
    {
        _playerId = playerId;
        _teamId = teamId;
        _handicap = handicap;

        var whirledIds :Array;
        var playerNames :Array;

        if (AppContext.gameCtrl.isConnected()) {
            whirledIds = AppContext.gameCtrl.game.seating.getPlayerIds();
            playerNames = AppContext.gameCtrl.game.seating.getPlayerNames();
        } else {
            whirledIds = playerNames = [];
        }

        _whirledId = (playerId < whirledIds.length ? whirledIds[_playerId] : 0);

        if (null != playerName) {
            _playerName = playerName;
        } else if (_playerId < playerNames.length && null != playerNames[_playerId])  {
            _playerName = playerNames[_playerId];
        } else {
            _playerName = "Unknown player " + playerId;
        }
    }

    public function get handicap () :Number
    {
        return _handicap;
    }

    public function get playerColor () :uint
    {
        return GameContext.gameData.playerColors[_playerId];
    }

    public function get playerId () :int
    {
        return _playerId;
    }

    public function get teamId () :int
    {
        return _teamId;
    }

    public function get whirledId () :int
    {
        return _whirledId;
    }

    public function get playerName () :String
    {
        return _playerName;
    }

    public function get leftGame () :Boolean
    {
        return _leftGame;
    }

    public function set leftGame (val :Boolean) :void
    {
        _leftGame = val;
    }

    public function get baseRef () :SimObjectRef
    {
        return _baseRef;
    }

    public function get base () :PlayerBaseUnit
    {
        return _baseRef.object as PlayerBaseUnit;
    }

    public function set base (val :PlayerBaseUnit) :void
    {
        _baseRef = val.ref;
    }

    public function get isAlive () :Boolean
    {
        // If this is called before the game has been completely set up,
        // _baseRef will be null and (null != this.base) will NPE. We can
        // assume, in this situation, that the player is alive.
        return (null == _baseRef || null != this.base);
    }

    public function get isInvincible () :Boolean
    {
        return (null != _baseRef && this.base.isInvincible);
    }

    public function get health () :Number
    {
        var base :PlayerBaseUnit = this.base;
        return (null != base ? base.health : 0);
    }

    public function get maxHealth () :Number
    {
        var base :PlayerBaseUnit = this.base;
        return (null != base ? base.maxHealth : 0);
    }

    public function get healthPercent () :Number
    {
        var base :PlayerBaseUnit = this.base;
        return (null != base ? base.health / base.maxHealth : 0);
    }

    public function get targetedEnemyId () :int
    {
        return _targetedEnemyId;
    }

    public function set targetedEnemyId (val :int) :void
    {
        _targetedEnemyId = val;
    }

    public function canPurchaseCreature (unitType :int) :Boolean
    {
        return true;
    }

    public function deductCreatureCost (unitType :int) :void
    {
        // no-op
    }

    public function canCastSpell (spellType :int) :Boolean
    {
        return true;
    }

    public function addSpell (spellType :int, count :int = 1) :void
    {
        // no-op
    }

    public function spellCast (spellType :int) :void
    {
        // no-op
    }

    protected var _playerId :int;  // an unsigned integer corresponding to the player's seating position
    protected var _teamId :int;
    protected var _whirledId :int;  // the oid assigned to this player on Whirled
    protected var _playerName :String;
    protected var _leftGame :Boolean;
    protected var _targetedEnemyId :int;
    protected var _baseRef :SimObjectRef;
    protected var _handicap :Number;

    protected static var log :Log = Log.getLog(PlayerInfo);

}

}
