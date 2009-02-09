package vampire.client {
import com.threerings.util.Log;
import com.whirled.avrg.AVRGameAvatar;
import com.whirled.avrg.AVRGameControl;
import com.whirled.contrib.EventHandlers;
import com.whirled.contrib.simplegame.Config;
import com.whirled.contrib.simplegame.SimpleGame;
import com.whirled.contrib.simplegame.resource.ResourceManager;
import com.whirled.net.MessageReceivedEvent;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;

import vampire.data.Constants;
import vampire.net.MessageManager;
import vampire.server.AVRGAgentLogTarget;

[SWF(width="700", height="500")]
public class VampireMain extends Sprite
{
    public function VampireMain()
    {
        
        
        Log.setLevel("com.threerings", Log.OFF);
        Log.setLevel("vampire.client", Log.DEBUG);
        
        trace("VampireMain()");
        /* Register mode classes so that they can be instatiated just by name*/
//        registerClassAlias("vampire.client.modes.BloodBondMode", BloodBondMode);
//        registerClassAlias("vampire.client.modes.FeedMode", FeedMode);
//        registerClassAlias("vampire.client.modes.FightMode", FightMode);
//        registerClassAlias("vampire.client.modes.HierarchyMode", HierarchyMode);
        
//        trace("  registered classes");
        addEventListener(Event.ADDED_TO_STAGE, handleAdded);
        addEventListener(Event.REMOVED_FROM_STAGE, handleUnload);
        
        
        // instantiate MainLoop singleton, and load its resources.
        var gameSprite :Sprite = new Sprite();
        addChild( gameSprite );
        var config :Config = new Config();
        config.hostSprite = gameSprite;
        ClientContext.game = new SimpleGame( config );
        
        loadResources();
            
//        _resourcesLoaded = false;
    }
    
    protected function loadResources () :void
    {
        var rm :ResourceManager = ClientContext.game.ctx.rsrcs;

        rm.queueResourceLoad("swf",   "HUD",         { embeddedClass: SWF_HUD });

        rm.loadQueuedResources(
            function () :void {
                _resourcesLoaded = true;
                maybeStartGame();
            },
            function (err :String) :void {
                log.error("Error loading resources: " + err);
            });
    }
    
    
    protected function maybeStartGame () :void
    {
        if (_addedToStage && _resourcesLoaded) {
            
//            ClientContext.gameCtrl = new AVRGameControl( this );
            if( ClientContext.gameCtrl == null) {
                ClientContext.gameCtrl = new AVRGameControl( this );
            }
            
        
            if( !ClientContext.gameCtrl.isConnected() && !Constants.LOCAL_DEBUG_MODE) {
                trace("Not conected and not test model");
                return;
            }
            
            
            ClientContext.msg = new MessageManager( ClientContext.gameCtrl );
            ClientContext.ourPlayerId = ClientContext.gameCtrl.player.getPlayerId();
            
            ClientContext.controller = new VampireController(this);
            
            ClientContext.model = new GameModel();
            ClientContext.model.setup();
            
            
            //Push the main game mode
            ClientContext.game.ctx.mainLoop.pushMode( new MainGameMode() );
            
            //If this player hasn't played before, automatically show the help.
            if( ClientContext.model.isNewPlayer() ) {
                ClientContext.game.ctx.mainLoop.pushMode( new IntroHelpMode() );
            }
            
            ClientContext.game.run();
            
            
            //Show chat events
            EventHandlers.registerListener( ClientContext.gameCtrl.player, 
                MessageReceivedEvent.MESSAGE_RECEIVED, 
                function( e :MessageReceivedEvent) :void {
                    if( e.name == Constants.NAMED_EVENT_CHAT) {
                        ClientContext.gameCtrl.local.feedback( e.value.toString() );
                    }    
                });
            
           
            
//            addChild( new VProbe(ClientContext.gameCtrl) );
        
        
            EventHandlers.registerListener( ClientContext.gameCtrl.game, MessageReceivedEvent.MESSAGE_RECEIVED, printServerLogToFlashLog);
        }
    }

    protected function handleResourcesLoaded () :void
    {
        _resourcesLoaded = true;
        maybeStartGame();
    }

    protected function handleResourceLoadError (err :String) :void
    {
        log.warning("Resource load error: " + err);
    }

    protected function handleAdded (event :Event) :void
    {
        log.info("Added to stage: Initializing...");
        _addedToStage = true;
        maybeStartGame();
    }

    protected function handleUnload (event :Event) :void
    {
        log.info("Removed from stage - Unloading...");

        EventHandlers.freeAllHandlers();
        ClientContext.model.shutdown();
        ClientContext.game.shutdown();
        
        removeEventListener( MouseEvent.MOUSE_MOVE, mouseMove);
    }

    protected function leftRoom (e :Event) :void
    {
        log.debug("leftRoom");
//        ClientContext.quit();
    }
    
    protected function setupAvatarInfoCapture() :void
    {
        graphics.clear();
        graphics.beginFill(0, 0);
        graphics.drawRect(0, 0, 700, 500);
        graphics.endFill();
        
        EventHandlers.registerListener(this, MouseEvent.MOUSE_MOVE, mouseMove);
        
    }
    
    protected function setupTempEventNotifier() :void
    {
//        EventHandlers.registerListener( ClientContext.gameCtrl.room, AVRGameRoomEvent.PLAYER_ENTERED, function( e :AVRGameRoomEvent) :void 
//                                { 
//                                    trace("!Room dispatching: " + AVRGameRoomEvent.PLAYER_ENTERED);
//                                    trace("   Player stats: " + SharedPlayerStateClient.toStringForPlayer( int(e.value)));  
//                                } );
//        EventHandlers.registerListener( ClientContext.gameCtrl.game, MessageReceivedEvent.MESSAGE_RECEIVED , function(...ignored) :void { trace("!Room dispatching: " + MessageReceivedEvent.MESSAGE_RECEIVED );} );
//        EventHandlers.registerListener( ClientContext.gameCtrl.player, AVRGamePlayerEvent.ENTERED_ROOM , function( e :AVRGamePlayerEvent) :void 
//                                { 
//                                    trace("!Player dispatching: " + AVRGamePlayerEvent.ENTERED_ROOM );
//                                    trace("   Player stats: " + SharedPlayerStateClient.toStringForPlayer( e.playerId ));
//                                });
    }
    
    protected function mouseMove( e :MouseEvent ) :void
    {
        for each (var playerId :int in ClientContext.gameCtrl.room.getPlayerIds()) {
            var avatar :AVRGameAvatar = ClientContext.gameCtrl.room.getAvatarInfo( playerId );
            if( avatar.bounds.contains( e.localX, e.localY ) ) {
                trace("mouse over avatar=" + playerId );
                return; 
            }
        }
    }
    
    protected function printServerLogToFlashLog( e :MessageReceivedEvent ) :void
    {
        if( e.name == AVRGAgentLogTarget.SERVER_LOG) {
            trace(e.value);
        }
    }
    

    protected var _addedToStage :Boolean = false;
    protected var _resourcesLoaded :Boolean = false;

    protected static var log :Log = Log.getLog(VampireMain);
    
    [Embed(source="../../../rsrc/HUD.swf", mimeType="application/octet-stream")]
    protected static const SWF_HUD :Class;
    
}

}