package popcraft {

import com.whirled.game.OccupantChangedEvent;

public class SeatingManager
{
    public static function init () :void
    {
        if (AppContext.gameCtrl.isConnected()) {
            _numExpectedPlayers = AppContext.gameCtrl.game.seating.getPlayerIds().length;
            _localPlayerSeatIndex = AppContext.gameCtrl.game.seating.getMyPosition();
            updatePlayers();

            AppContext.gameCtrl.game.addEventListener(OccupantChangedEvent.OCCUPANT_ENTERED, updatePlayers);
            AppContext.gameCtrl.game.addEventListener(OccupantChangedEvent.OCCUPANT_LEFT, updatePlayers);
        } else {
            _numExpectedPlayers = 1;
            _numPlayers = 1;
            _localPlayerSeatIndex = 0;
            _lowestOccupiedSeatIndex = 0;
        }
    }

    public static function get numExpectedPlayers () :int
    {
        return _numExpectedPlayers;
    }

    public static function get numPlayers () :int
    {
        return _numPlayers;
    }

    public static function get allPlayersPresent () :Boolean
    {
        return _numExpectedPlayers == _numPlayers;
    }

    public static function get localPlayerId () :int
    {
        return _localPlayerSeatIndex;
    }

    public static function get isPlayerInControl () :Boolean
    {
        return _localPlayerSeatIndex == _lowestOccupiedSeatIndex;
    }

    protected static function updatePlayers (...ignored) :void
    {
        var playerIds :Array = AppContext.gameCtrl.game.seating.getPlayerIds();
        _numPlayers = 0;
        _lowestOccupiedSeatIndex = -1;
        for (var seatIndex :int = 0; seatIndex < playerIds.length; ++seatIndex) {
            var playerId :int = playerIds[seatIndex];
            if (playerId != 0) {
                ++_numPlayers;
                if (_lowestOccupiedSeatIndex < 0) {
                    _lowestOccupiedSeatIndex = seatIndex;
                }
            }
        }
    }

    protected static var _numExpectedPlayers :int;  // the number of players who initially joined the game
    protected static var _numPlayers :int;          // the number of players in the game right now
    protected static var _lowestOccupiedSeatIndex :int;
    protected static var _localPlayerSeatIndex :int;
}

}
