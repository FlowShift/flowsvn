package vampire.feeding.client {

import com.whirled.avrg.AVRGameAvatar;
import com.whirled.avrg.AVRGameControl;
import com.whirled.contrib.simplegame.MainLoop;
import com.whirled.contrib.simplegame.audio.*;
import com.whirled.contrib.simplegame.resource.*;

import flash.display.Bitmap;
import flash.display.MovieClip;
import flash.utils.getTimer;

import vampire.feeding.*;
import vampire.feeding.net.*;

public class ClientCtx
{
    // Initialized just once
    public static var gameCtrl :AVRGameControl;
    public static var mainLoop :MainLoop;
    public static var rsrcs :ResourceManager;
    public static var audio :AudioManager;

    // Initialized every time a new feeding takes place
    public static var roundMgr :GameRoundMgr;
    public static var msgMgr :ClientMsgMgr;
    public static var gameCompleteCallback :Function;
    public static var playerData :FeedingPlayerData;
    public static var gameStarted :Boolean;
    public static var noMoreFeeding :Boolean;
    public static var playerIds :Array;
    public static var preyId :int;
    public static var isAiPrey :Boolean;

    public static function init () :void
    {
        roundMgr = null;
        msgMgr = null;
        gameCompleteCallback = null;
        playerData = null;
        gameStarted = false;
        noMoreFeeding = false;
        playerIds = null;
        preyId = 0;
        isAiPrey = false;
    }

    public static function get isPrey () :Boolean
    {
        return (localPlayerId == preyId);
    }

    public static function get isPredator () :Boolean
    {
        return (!isPrey);
    }

    public static function get isSinglePlayer () :Boolean
    {
        return (!isConnected || playerIds.length <= 1);
    }

    public static function quit (playerInitiated :Boolean) :void
    {
        if (playerInitiated) {
            msgMgr.sendMessage(ClientQuitMsg.create());
        }

        gameCompleteCallback();

        // TODO: if the player didn't initiate the quit, show a screen explaining what happened
    }

    public static function get localPlayerId () :int
    {
        return (!isConnected ? 1 : gameCtrl.player.getPlayerId());
    }

    public static function get timeNow () :Number
    {
        return flash.utils.getTimer() * 0.001; // returns seconds
    }

    public static function get isConnected () :Boolean
    {
        return gameCtrl.isConnected();
    }

    public static function getPlayerName (playerId :int) :String
    {
        if (gameCtrl.isConnected()) {
            var avatar :AVRGameAvatar = gameCtrl.room.getAvatarInfo(playerId);
            if (null != avatar) {
                return avatar.name;
            }
        }

        return "[Unrecognized player " + playerId + "]";
    }

    public static function instantiateBitmap (name :String) :Bitmap
    {
        return ImageResource.instantiateBitmap(rsrcs, name);
    }

    public static function instantiateMovieClip (rsrcName :String, className :String,
        disableMouseInteraction :Boolean = false, fromCache :Boolean = false) :MovieClip
    {
        return SwfResource.instantiateMovieClip(
            rsrcs,
            rsrcName,
            className,
            disableMouseInteraction,
            fromCache);
    }
}

}
