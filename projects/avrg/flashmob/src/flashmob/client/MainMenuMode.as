package flashmob.client {

import com.threerings.util.Log;
import com.whirled.contrib.simplegame.resource.SwfResource;

import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.events.MouseEvent;
import flash.geom.Rectangle;

import flashmob.client.view.BasicYesNoMode;
import flashmob.client.view.Dragger;

public class MainMenuMode extends GameDataMode
{
    override protected function setup () :void
    {
        super.setup();

        // create the main UI and make it draggable
        _ui = SwfResource.instantiateMovieClip("Spectacle_UI", "mainUI");
        _modeSprite.addChild(_ui);
        addObject(new Dragger(_ui));

        var bounds :Rectangle = ClientContext.roomDisplayBounds;
        _ui.x = bounds.left - 60 + (bounds.width * 0.5);
        _ui.y = bounds.top + (bounds.width * 0.5);

        //_ui.scaleX = _ui.scaleY = 0.7;

        // wire up buttons
        var creatorModeButton :SimpleButton = _ui["makeyourown"];
        registerOneShotCallback(creatorModeButton, MouseEvent.CLICK,
            function (...ignored) :void {
                log.info("Make Your Own!");
            });

        var quitButton :SimpleButton = _ui["close"];
        registerListener(quitButton, MouseEvent.CLICK,
            function (...ignored) :void {
                ClientContext.confirmQuit();
            });
    }

    protected function get log () :Log
    {
        return FlashMobClient.log;
    }

    protected var _ui :MovieClip;
}

}