package ghostbusters.fight.potions {

import com.threerings.flash.DisplayUtil;
import com.threerings.util.ArrayUtil;
import com.whirled.contrib.ColorMatrix;
import com.whirled.contrib.core.*;
import com.whirled.contrib.core.resource.*;
import com.whirled.contrib.core.tasks.*;
import com.whirled.contrib.core.util.*;

import flash.display.MovieClip;
import flash.events.MouseEvent;

import ghostbusters.fight.*;
import ghostbusters.fight.common.*;
import ghostbusters.fight.ouija.BoardTimer;

public class HueAndCryGame extends MicrogameMode
{
    public function HueAndCryGame (difficulty :int, playerData :Object)
    {
        super(difficulty, playerData);
        
        _settings = DIFFICULTY_SETTINGS[Math.min(difficulty, DIFFICULTY_SETTINGS.length - 1)];
        
        _targetColor = Colors.getRandomSecondary();
    }
    
    override public function begin () :void
    {
        MainLoop.instance.pushMode(this);
        
        if (!g_assetsLoaded) {
            MainLoop.instance.pushMode(new LoadingMode());
            g_assetsLoaded = true;
        }
        
        MainLoop.instance.pushMode(new IntroMode("Mix " + Colors.getColorName(_targetColor) + "!"));
    }
    
    override protected function get duration () :Number
    {
        return _settings.gameTime;
    }
    
    override protected function get timeRemaining () :Number
    {
        return (_done ? 0 : GameTimer.timeRemaining);
    }
    
    override public function get isDone () :Boolean
    {
        return (_done && !WinLoseNotification.isPlaying);
    }
    
    override public function get gameResult () :MicrogameResult
    {
        return _gameResult;
    }
    
    protected function gameOver (success :Boolean) :void
    {
        if (!_done) {
            GameTimer.uninstall();
            WinLoseNotification.create(success, this.modeSprite);
            
            _gameResult = new MicrogameResult();
            _gameResult.success = (success ? MicrogameResult.SUCCESS : MicrogameResult.FAILURE);
            _gameResult.healthOutput = (success ? _settings.healthOutput : 0);
            
            _done = true;
        }
    }

    override protected function setup () :void
    {
        // draw the board
        var swfResource :SwfResourceLoader = ResourceManager.instance.getResource("gameSwf") as SwfResourceLoader;
        
        var displayRoot :MovieClip = swfResource.displayRoot as MovieClip;
        this.modeSprite.addChild(displayRoot);
        
        // beaker's initial color?
        var validBeakerColors :Array;
        switch (_targetColor) {
        case Colors.COLOR_ORANGE:
            validBeakerColors = [ Colors.COLOR_RED, Colors.COLOR_YELLOW ];
            break;
            
        case Colors.COLOR_PURPLE:
            validBeakerColors = [ Colors.COLOR_RED, Colors.COLOR_BLUE ];
            break;
            
        case Colors.COLOR_GREEN:
            validBeakerColors = [ Colors.COLOR_YELLOW, Colors.COLOR_BLUE ];
            break;
        }
        
        var initialColor :uint = Colors.COLOR_CLEAR;
        if (validBeakerColors.length > 0 && Rand.nextBoolean(Rand.STREAM_COSMETIC)) {
            initialColor = validBeakerColors[Rand.nextIntRange(0, validBeakerColors.length, Rand.STREAM_COSMETIC)];
        }
        
        // target color
        var targetColorObj :MovieClip = displayRoot.target_card.card.target_color;
        var targetColorMatrix :ColorMatrix = new ColorMatrix();
        targetColorMatrix.colorize(Colors.getScreenColor(_targetColor));
        targetColorObj.filters = [ targetColorMatrix.createFilter() ];
        
        // beaker bottom
        _mixture = DisplayUtil.findInHierarchy(displayRoot, "liquid") as MovieClip;
        
        this.setBeakerColor(initialColor);
        
        // create the droppers
        var droppers :Array = [ displayRoot.dropper_1, displayRoot.dropper_2, displayRoot.dropper_3 ];
        var drops :Array = [ displayRoot.drop_1, displayRoot.drop_2, displayRoot.drop_3 ];
        
        var dropperColors :Array = [ Colors.COLOR_RED, Colors.COLOR_YELLOW, Colors.COLOR_BLUE ];
        ArrayUtil.shuffle(dropperColors);
        
        for (var i :uint = 0; i < 3; ++i) {
            var dropper :Dropper = new Dropper(dropperColors[i], droppers[i]);
            dropper.interactiveObject.addEventListener(MouseEvent.MOUSE_DOWN, this.createDropperClickHandler(dropper));
            this.addObject(dropper);
            
            // tint the drop
            var colorMatrix :ColorMatrix = new ColorMatrix();
            colorMatrix.colorize(Colors.getScreenColor(dropperColors[i]));
            var drop :MovieClip = drops[i];
            drop.filters = [ colorMatrix.createFilter() ];
        }

        // create the visual timer
        var boardTimer :BoardTimer = new BoardTimer(this.duration);
        this.addObject(boardTimer, this.modeSprite);

        // install a failure timer
        GameTimer.install(this.duration, function () :void { gameOver(false) });
    }
    
    protected function createDropperClickHandler (dropper :Dropper) :Function
    {
        var localThis :HueAndCryGame = this;
        return function (e :MouseEvent) :void {
            localThis.addColorToBeaker(dropper.color);
        }
    }
    
    protected function addColorToBeaker (color :uint) :void
    {
        this.setBeakerColor(Colors.getMixedColor(_beakerColor, color));
    }
    
    protected function setBeakerColor (newColor :uint) :void
    {
        _beakerColor = newColor;
        
        if (_beakerColor == Colors.COLOR_CLEAR) {
            _mixture.visible = false;
        } else {
            _mixture.visible = true;
        
            var tintMatrix :ColorMatrix = new ColorMatrix();
            tintMatrix.colorize(Colors.getScreenColor(_beakerColor));
            
            _mixture.filters = [ tintMatrix.createFilter() ];
            
            if (_beakerColor == _targetColor) {
                this.gameOver(true);
            } else if (_beakerColor == Colors.COLOR_BROWN) {
                this.gameOver(false);
            }
        }
    }
    
    protected var _done :Boolean;
    protected var _settings :HueAndCrySettings;
    protected var _gameResult :MicrogameResult;
    protected var _targetColor :uint;
    
    protected var _beakerColor :uint;
    protected var _mixture :MovieClip;
    
    protected var _swf :MovieClip;
    
    protected static var g_assetsLoaded :Boolean;
    
    protected static const DIFFICULTY_SETTINGS :Array = [
    
        new HueAndCrySettings(6, 5),
        
    ];
    
}

}

import com.whirled.contrib.core.*;
import com.whirled.contrib.core.resource.*;
import com.whirled.contrib.core.tasks.*;
import com.whirled.contrib.core.util.*;

import ghostbusters.fight.potions.*;

class LoadingMode extends AppMode
{
    public function LoadingMode ()
    {
    }
    
    override protected function setup () :void
    {
        ResourceManager.instance.pendResourceLoad("swf", "gameSwf", { embeddedClass: Content.SWF_HUEANDCRYBOARD });
        ResourceManager.instance.load();
    }
    
    override public function update (dt:Number) :void
    {
        super.update(dt);
        
        if (!ResourceManager.instance.isLoading) {
            MainLoop.instance.popMode();
        }
    }
}
