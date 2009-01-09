package flashmob.client.view {

import com.whirled.contrib.simplegame.AppMode;
import com.whirled.contrib.simplegame.resource.SwfResource;

import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.text.TextField;

import flashmob.client.*;

public class BasicErrorMode extends AppMode
{
    public function BasicErrorMode (err :String, okHandler :Function = null)
    {
        _err = err;
        _okHandler = (okHandler != null ? okHandler : ClientContext.mainLoop.popMode);
    }

    override protected function setup () :void
    {
        var bounds :Rectangle = ClientContext.fullDisplayBounds;
        var g :Graphics = _modeSprite.graphics;
        g.beginFill(0, 0.5);
        g.drawRect(bounds.left, bounds.top, bounds.width, bounds.height);
        g.endFill();

        var window :MovieClip = SwfResource.instantiateMovieClip("Spectacle_UI", "errorWindow");
        window.x = bounds.width * 0.5;
        window.y = bounds.height * 0.5;
        _modeSprite.addChild(window);

        var tf :TextField = window["text"];
        tf.text = _err;

        var okButton :SimpleButton = window["ok"];
        registerOneShotCallback(okButton, MouseEvent.CLICK, _okHandler);
    }

    protected var _err :String;
    protected var _okHandler :Function;
}

}
