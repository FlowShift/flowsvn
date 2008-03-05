//
// $Id$

package bingo {

import com.threerings.util.Log;
import com.whirled.AVRGameAvatar;
import com.whirled.AVRGameControl;
import com.whirled.AVRGameControlEvent;

import flash.display.Sprite;
import flash.events.Event;

[SWF(width="700", height="500")]
public class BingoMain extends Sprite
{
    public static const VERSION :Number = 1.92;
    
    public static var log :Log = Log.getLog(BingoMain);

    public static var control :AVRGameControl;
    public static var model :Model;
    public static var controller :Controller;
    
    public static var ourPlayerId :int;

    public function BingoMain ()
    {
        log.info("Bingo version " + VERSION);

        addEventListener(Event.ADDED_TO_STAGE, handleAdded);
        addEventListener(Event.REMOVED_FROM_STAGE, handleUnload);
        
        control = new AVRGameControl(this);

        control.addEventListener(AVRGameControlEvent.ENTERED_ROOM, enteredRoom);
        control.addEventListener(AVRGameControlEvent.LEFT_ROOM, leftRoom);

        control.addEventListener(AVRGameControlEvent.PLAYER_ENTERED, playerEntered);
        control.addEventListener(AVRGameControlEvent.PLAYER_LEFT, playerLeft);

        control.addEventListener(AVRGameControlEvent.GOT_CONTROL, gotControl);
    }
    
    public static function getPlayerName (playerId :int) :String
    {
        if (control.isConnected()) {
            var avatar :AVRGameAvatar = control.getAvatarInfo(playerId);
            if (null != avatar) {
                return avatar.name;
            }
        }
        
        return "player " + playerId.toString();
    }

    protected function handleAdded (event :Event) :void
    {
        log.info("Added to stage: Initializing...");
        
        log.info(control.isConnected() ? "playing online game" : "playing offline game");
        
        model = (control.isConnected() && !Constants.FORCE_SINGLEPLAYER ? new OnlineModel() : new OfflineModel());
        controller = new Controller(this, model);
        
        ourPlayerId = (control.isConnected() ? control.getPlayerId() : 666);
        
        new BingoItemManager(); // init singleton
        model.setup();
        controller.setup();
        
        this.enteredRoom();
    }

    protected function handleUnload (event :Event) :void
    {
        log.info("Removed from stage - Unloading...");
        
        controller.destroy();
        model.destroy();
    }

    protected function enteredRoom (... ignored) :void
    {
    }
    
    protected function leftRoom (e :Event) :void
    {
        log.debug("leftRoom");
        if (control.isConnected()) {
            log.debug("deactivating game");
            control.deactivateGame();
        }
    }

    protected function gotControl (evt :AVRGameControlEvent) :void
    {
        log.debug("gotControl(): " + evt);
    }

    protected function playerEntered (evt :AVRGameControlEvent) :void
    {
    }

    protected function playerLeft (evt :AVRGameControlEvent) :void
    {
    }
}
}
