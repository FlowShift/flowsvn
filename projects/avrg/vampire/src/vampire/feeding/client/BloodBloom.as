package vampire.feeding.client {

import com.threerings.util.Log;
import com.whirled.avrg.AVRGameControl;
import com.whirled.contrib.EventHandlerManager;
import com.whirled.contrib.simplegame.*;
import com.whirled.contrib.simplegame.resource.ResourceManager;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.utils.Timer;

import vampire.feeding.*;
import vampire.feeding.net.*;
import vampire.feeding.server.Server;

public class BloodBloom extends FeedingGameClient
{
    public static function DEBUG_REMOVE_ME () :void
    {
        var c :Class;
        c = vampire.feeding.server.Server;
    }

    public static function init (hostSprite :Sprite, gameCtrl :AVRGameControl) :void
    {
        // Init simplegame
        var config :Config = new Config();
        config.hostSprite = hostSprite;
        _sg = new SimpleGame(config);

        ClientCtx.gameCtrl = gameCtrl;
        ClientCtx.mainLoop = _sg.ctx.mainLoop;
        ClientCtx.rsrcs = _sg.ctx.rsrcs;
        ClientCtx.audio = _sg.ctx.audio;
        _sg.run();

        loadResources();
    }

    public function BloodBloom (gameId :int)
    {
        DEBUG_REMOVE_ME();

        ClientCtx.msgMgr = new ClientMsgMgr(gameId, ClientCtx.gameCtrl);
        Util.initMessageManager(ClientCtx.msgMgr);

        _events.registerListener(this, Event.ADDED_TO_STAGE, onAddedToStage);
        _events.registerListener(this, Event.REMOVED_FROM_STAGE, onQuit);

        // If the resources aren't loaded, wait for them to load
        if (!_resourcesLoaded) {
            var timer :Timer = new Timer(50);
            timer.addEventListener(TimerEvent.TIMER, checkResourcesLoaded);
            timer.start();

            function checkResourcesLoaded (...ignored) :void {
                if (_resourcesLoaded) {
                    timer.removeEventListener(TimerEvent.TIMER, checkResourcesLoaded);
                    timer.stop();
                    maybeStartGame();
                }
            }
        }
    }

    protected function onAddedToStage (...ignored) :void
    {
        _addedToStage = true;
        maybeStartGame();
    }

    protected function onQuit (...ignored) :void
    {
        _events.freeAllHandlers();
    }

    protected function maybeStartGame () :void
    {
        if (_addedToStage && _resourcesLoaded) {
            ClientCtx.mainLoop.pushMode(new SpSplashMode());
        }
    }

    protected static function loadResources () :void
    {
        var rm :ResourceManager = ClientCtx.rsrcs;

        rm.queueResourceLoad("swf",   "blood",          { embeddedClass: SWF_BLOOD });
        rm.queueResourceLoad("swf",   "uiBits",         { embeddedClass: SWF_UIBITS });
        rm.queueResourceLoad("image", "bg",             { embeddedClass: IMG_BG });
        rm.queueResourceLoad("image", "red_cell",       { embeddedClass: IMG_RED_CELL });
        rm.queueResourceLoad("image", "white_cell",     { embeddedClass: IMG_WHITE_CELL });
        rm.queueResourceLoad("image", "bonus_cell",     { embeddedClass: IMG_BONUS_CELL });
        rm.queueResourceLoad("image", "predator_cursor", { embeddedClass: IMG_PREDATOR_CURSOR });
        rm.queueResourceLoad("image", "prey_cursor",    { embeddedClass: IMG_PREY_CURSOR });

        rm.queueResourceLoad("sound", "sfx_heartbeat",  { embeddedClass: SOUND_HEARTBEAT });
        rm.queueResourceLoad("sound", "sfx_red_burst",      { embeddedClass: SOUND_RED_BURST });
        rm.queueResourceLoad("sound", "sfx_white_burst", { embeddedClass: SOUND_WHITE_BURST });
        rm.queueResourceLoad("sound", "mus_music",      { embeddedClass: SOUND_MUSIC, type: "music" });

        rm.loadQueuedResources(
            function () :void {
                _resourcesLoaded = true;
            },
            function (err :String) :void {
                log.error("Error loading resources: " + err);
            });
    }

    protected var _addedToStage :Boolean;
    protected var _events :EventHandlerManager = new EventHandlerManager();

    protected static var _sg :SimpleGame;
    protected static var _resourcesLoaded :Boolean;
    protected static var log :Log = Log.getLog(BloodBloom);

    [Embed(source="../../../../rsrc/feeding/blood.swf", mimeType="application/octet-stream")]
    protected static const SWF_BLOOD :Class;
    [Embed(source="../../../../rsrc/feeding/UI_bits.swf", mimeType="application/octet-stream")]
    protected static const SWF_UIBITS :Class;
    [Embed(source="../../../../rsrc/feeding/bg.png", mimeType="application/octet-stream")]
    protected static const IMG_BG :Class;
    [Embed(source="../../../../rsrc/feeding/red_cell.png", mimeType="application/octet-stream")]
    protected static const IMG_RED_CELL :Class;
    [Embed(source="../../../../rsrc/feeding/white_cell.png", mimeType="application/octet-stream")]
    protected static const IMG_WHITE_CELL :Class;
    [Embed(source="../../../../rsrc/feeding/bonus_cell.png", mimeType="application/octet-stream")]
    protected static const IMG_BONUS_CELL :Class;
    [Embed(source="../../../../rsrc/feeding/vampire_cursor.png", mimeType="application/octet-stream")]
    protected static const IMG_PREDATOR_CURSOR :Class;
    [Embed(source="../../../../rsrc/feeding/victim_cursor.png", mimeType="application/octet-stream")]
    protected static const IMG_PREY_CURSOR :Class;

    [Embed(source="../../../../rsrc/feeding/heartbeat.mp3")]
    protected static const SOUND_HEARTBEAT :Class;
    [Embed(source="../../../../rsrc/feeding/red_burst.mp3")]
    protected static const SOUND_RED_BURST :Class;
    [Embed(source="../../../../rsrc/feeding/white_burst.mp3")]
    protected static const SOUND_WHITE_BURST :Class;
    [Embed(source="../../../../rsrc/feeding/music.mp3")]
    protected static const SOUND_MUSIC :Class;
}

}
