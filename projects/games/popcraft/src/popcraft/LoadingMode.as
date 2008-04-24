package popcraft {

import com.whirled.contrib.simplegame.*;
import com.whirled.contrib.simplegame.resource.*;

public class LoadingMode extends AppMode
{
    override protected function setup () :void
    {
        AppContext.resources.pendResourceLoad("image", "colossus_icon",  { embeddedClass: IMAGE_COLOSSUSICON });

        AppContext.resources.pendResourceLoad("image", "base",      { embeddedClass: IMAGE_BASE });
        AppContext.resources.pendResourceLoad("image", "targetBaseBadge", { embeddedClass: IMAGE_TARGETBASEBADGE });
        AppContext.resources.pendResourceLoad("image", "friendlyBaseBadge", { embeddedClass: IMAGE_FRIENDLYBASEBADGE });
        AppContext.resources.pendResourceLoad("image", "sun", { embeddedClass: IMAGE_SUN });
        AppContext.resources.pendResourceLoad("image", "moon", { embeddedClass: IMAGE_MOON });
        AppContext.resources.pendResourceLoad("image", "battle_bg", { embeddedClass: IMAGE_BATTLE_BG });
        AppContext.resources.pendResourceLoad("image", "battle_fg", { embeddedClass: IMAGE_BATTLE_FG });
        AppContext.resources.pendResourceLoad("image", "bloodlust_icon", { embeddedClass: IMAGE_BLOODLUSTICON });
        AppContext.resources.pendResourceLoad("image", "rigormortis_icon", { embeddedClass: IMAGE_RIGORMORTISICON });

        AppContext.resources.pendResourceLoad("swf", "grunt", { embeddedClass: SWF_GRUNT });
        AppContext.resources.pendResourceLoad("swf", "sapper", { embeddedClass: SWF_SAPPER });
        AppContext.resources.pendResourceLoad("swf", "heavy", { embeddedClass: SWF_HEAVY });

        AppContext.resources.pendResourceLoad("swf", "puzzlePieces", { embeddedClass: SWF_PUZZLEPIECES });

        AppContext.resources.pendResourceLoad("gameData", "defaultGameData", { embeddedClass: DEFAULT_GAME_DATA });

        AppContext.resources.addEventListener(ResourceLoadEvent.LOADED, handleResourcesLoaded);
        AppContext.resources.addEventListener(ResourceLoadEvent.ERROR, handleResourceLoadErr);

        AppContext.resources.load();
    }

    override protected function destroy () :void
    {
        AppContext.resources.removeEventListener(ResourceLoadEvent.LOADED, handleResourcesLoaded);
    }

    protected function handleResourcesLoaded (...ignored) :void
    {
        MainLoop.instance.popMode();
    }

    protected function handleResourceLoadErr (e :ResourceLoadEvent) :void
    {
        AppContext.mainLoop.unwindToMode(new ResourceLoadErrorMode(e.data as String));
    }

    [Embed(source="../../levels/defaultGameData.xml", mimeType="application/octet-stream")]
    protected static const DEFAULT_GAME_DATA :Class;

    [Embed(source="../../rsrc/char_colossus.png", mimeType="application/octet-stream")]
    protected static const IMAGE_COLOSSUSICON :Class;

    [Embed(source="../../rsrc/base.png", mimeType="application/octet-stream")]
    protected static const IMAGE_BASE :Class;

    [Embed(source="../../rsrc/skull_and_crossbones.png", mimeType="application/octet-stream")]
    protected static const IMAGE_TARGETBASEBADGE :Class;

    [Embed(source="../../rsrc/smiley.png", mimeType="application/octet-stream")]
    protected static const IMAGE_FRIENDLYBASEBADGE :Class;

    [Embed(source="../../rsrc/sun.png", mimeType="application/octet-stream")]
    protected static const IMAGE_SUN :Class;

    [Embed(source="../../rsrc/moon.png", mimeType="application/octet-stream")]
    protected static const IMAGE_MOON :Class;

    [Embed(source="../../rsrc/city_bg.png", mimeType="application/octet-stream")]
    protected static const IMAGE_BATTLE_BG :Class;

    [Embed(source="../../rsrc/city_forefront.png", mimeType="application/octet-stream")]
    protected static const IMAGE_BATTLE_FG :Class;

    [Embed(source="../../rsrc/bloodlust_icon.png", mimeType="application/octet-stream")]
    protected static const IMAGE_BLOODLUSTICON :Class;

    [Embed(source="../../rsrc/rigormortis_icon.png", mimeType="application/octet-stream")]
    protected static const IMAGE_RIGORMORTISICON :Class;

    [Embed(source="../../rsrc/streetwalker.swf", mimeType="application/octet-stream")]
    protected static const SWF_GRUNT :Class;

    [Embed(source="../../rsrc/runt.swf", mimeType="application/octet-stream")]
    protected static const SWF_SAPPER :Class;

    [Embed(source="../../rsrc/handyman.swf", mimeType="application/octet-stream")]
    protected static const SWF_HEAVY :Class;

    [Embed(source="../../rsrc/pieces.swf", mimeType="application/octet-stream")]
    protected static const SWF_PUZZLEPIECES :Class;

}

}

import com.threerings.flash.SimpleTextButton;
import com.whirled.contrib.simplegame.AppMode;

import flash.display.Graphics;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import popcraft.*;

class ResourceLoadErrorMode extends AppMode
{
    public function ResourceLoadErrorMode (err :String)
    {
        _err = err;
    }

    override protected function setup () :void
    {
        var g :Graphics = this.modeSprite.graphics;
        g.beginFill(0xFF7272);
        g.drawRect(0, 0, Constants.SCREEN_DIMS.x, Constants.SCREEN_DIMS.y);
        g.endFill();

        var tf :TextField = new TextField();
        tf.multiline = true;
        tf.wordWrap = true;
        tf.autoSize = TextFieldAutoSize.LEFT;
        tf.scaleX = 1.5;
        tf.scaleY = 1.5;
        tf.width = 400;
        tf.x = 50;
        tf.y = 50;
        tf.text = _err;

        this.modeSprite.addChild(tf);
    }

    protected var _err :String;
}
