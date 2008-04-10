package popcraft {

import com.whirled.contrib.simplegame.*;
import com.whirled.contrib.simplegame.resource.*;

public class LoadingMode extends AppMode
{
    override protected function setup () :void
    {
        PopCraft.resourceManager.pendResourceLoad("image", "grunt_icon",     { embeddedClass: IMAGE_GRUNTICON });
        PopCraft.resourceManager.pendResourceLoad("image", "heavy_icon",     { embeddedClass: IMAGE_HEAVYICON });
        PopCraft.resourceManager.pendResourceLoad("image", "sapper_icon",    { embeddedClass: IMAGE_SAPPERICON });
        PopCraft.resourceManager.pendResourceLoad("image", "colossus_icon",  { embeddedClass: IMAGE_COLOSSUSICON });

        PopCraft.resourceManager.pendResourceLoad("image", "base",      { embeddedClass: IMAGE_BASE });
        PopCraft.resourceManager.pendResourceLoad("image", "battle_bg", { embeddedClass: IMAGE_BATTLE_BG });
        PopCraft.resourceManager.pendResourceLoad("image", "battle_fg", { embeddedClass: IMAGE_BATTLE_FG });

        PopCraft.resourceManager.pendResourceLoad("swf", "grunt", { embeddedClass: SWF_GRUNT });
        PopCraft.resourceManager.pendResourceLoad("swf", "sapper", { embeddedClass: SWF_SAPPER });

        PopCraft.resourceManager.pendResourceLoad("swf", "puzzlePieces", { embeddedClass: SWF_PUZZLEPIECES });

        PopCraft.resourceManager.addEventListener(ResourceLoadEvent.LOADED, handleResourcesLoaded);

        PopCraft.resourceManager.load();
    }

    override protected function destroy () :void
    {
        PopCraft.resourceManager.removeEventListener(ResourceLoadEvent.LOADED, handleResourcesLoaded);
    }

    protected function handleResourcesLoaded (...ignored) :void
    {
        MainLoop.instance.changeMode(new GameMode());
    }

    [Embed(source="../../rsrc/char_grunt.png", mimeType="application/octet-stream")]
    protected static const IMAGE_GRUNTICON :Class;

    [Embed(source="../../rsrc/char_heavy.png", mimeType="application/octet-stream")]
    protected static const IMAGE_HEAVYICON :Class;

    [Embed(source="../../rsrc/char_sapper.png", mimeType="application/octet-stream")]
    protected static const IMAGE_SAPPERICON :Class;

    [Embed(source="../../rsrc/char_colossus.png", mimeType="application/octet-stream")]
    protected static const IMAGE_COLOSSUSICON :Class;

    [Embed(source="../../rsrc/base.png", mimeType="application/octet-stream")]
    protected static const IMAGE_BASE :Class;

    [Embed(source="../../rsrc/city_bg.png", mimeType="application/octet-stream")]
    protected static const IMAGE_BATTLE_BG :Class;

    [Embed(source="../../rsrc/city_forefront.png", mimeType="application/octet-stream")]
    protected static const IMAGE_BATTLE_FG :Class;

    [Embed(source="../../rsrc/streetwalker.swf", mimeType="application/octet-stream")]
    protected static const SWF_GRUNT :Class;

    [Embed(source="../../rsrc/runt.swf", mimeType="application/octet-stream")]
    protected static const SWF_SAPPER :Class;

    [Embed(source="../../rsrc/pieces.swf", mimeType="application/octet-stream")]
    protected static const SWF_PUZZLEPIECES :Class;

}

}
