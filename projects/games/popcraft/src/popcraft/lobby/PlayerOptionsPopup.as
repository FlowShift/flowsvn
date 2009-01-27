package popcraft.lobby {

import com.threerings.util.ArrayUtil;
import com.whirled.contrib.simplegame.AppMode;
import com.whirled.contrib.simplegame.objects.SceneObject;

import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.MouseEvent;

import popcraft.*;
import popcraft.ui.UIBits;

public class PlayerOptionsPopup extends SceneObject
{
    public static function show (parentSprite :Sprite) :void
    {
        var topMode :AppMode = ClientCtx.mainLoop.topMode;
        var popup :PlayerOptionsPopup = topMode.getObjectNamed(NAME) as PlayerOptionsPopup;
        if (popup == null) {
            popup = new PlayerOptionsPopup();
            topMode.addObject(popup, parentSprite);
        }

        popup.initPlayerOptions();
        popup.visible = true;
    }

    public function PlayerOptionsPopup ()
    {
        _sprite = new Sprite();
        var g :Graphics = _sprite.graphics;
        g.beginFill(0, 0.6);
        g.drawRect(0, 0, Constants.SCREEN_SIZE.x, Constants.SCREEN_SIZE.y);
        g.endFill();

        _movie = ClientCtx.instantiateMovieClip("multiplayer_lobby", "player_options_panel");
        _movie.x = _sprite.width * 0.5;
        _movie.y = _sprite.height * 0.5;
        _sprite.addChild(_movie);

        var ii :int;
        var positioner :MovieClip;

        // fill in the player portraits
        for (ii = 0; ii < Constants.PLAYER_PORTRAIT_NAMES.length; ++ii) {
            positioner = _movie["portrait" + ii];
            positioner.visible = false;

            var portraitName :String = Constants.PLAYER_PORTRAIT_NAMES[ii];
            var portrait :DisplayObject =  (portraitName != null ?
                ClientCtx.instantiateBitmap(portraitName) :
                ClientCtx.seatingMgr.getPlayerHeadshot(ClientCtx.seatingMgr.localPlayerSeat, true));
            portrait.width = positioner.width;
            portrait.height = positioner.height;

            var portraitButton :Sprite = new Sprite();
            portraitButton.addChild(portrait);
            portraitButton.x = positioner.x;
            portraitButton.y = positioner.y;
            _movie.addChild(portraitButton);

            _portraitButtons.push(portraitButton);
            createPortraitClickListener(portraitButton, portraitName);
        }

        _portraitSelectionIndicator = new Shape();
        g = _portraitSelectionIndicator.graphics;
        g.lineStyle(PORTRAIT_SELECTION_INDICATOR_SIZE, 0);
        g.drawRect(0, 0, positioner.width + (PORTRAIT_SELECTION_INDICATOR_SIZE * 2),
            positioner.height + (PORTRAIT_SELECTION_INDICATOR_SIZE * 2));

        // fill in player colors
        for (ii = 0; ii < Constants.PLAYER_COLORS.length; ++ii) {
            positioner = _movie["color" + ii];
            positioner.visible = false;

            var color :uint = Constants.PLAYER_COLORS[ii];
            var swatch :Shape = new Shape();
            g = swatch.graphics;
            g.beginFill(color);
            g.drawRect(0, 0, positioner.width, positioner.height);
            g.endFill();

            var colorButton :Sprite = new Sprite();
            colorButton.addChild(swatch);
            colorButton.x = positioner.x - (colorButton.width * 0.5);
            colorButton.y = positioner.y - (colorButton.height * 0.5);
            _movie.addChild(colorButton);

            _colorButtons.push(colorButton);
            createColorClickListener(colorButton, color);
        }

        _colorSelectionIndicator = new Shape();
        g = _colorSelectionIndicator.graphics;
        g.lineStyle(COLOR_SELECTION_INDICATOR_SIZE, 0);
        g.drawRect(0, 0, positioner.width + (COLOR_SELECTION_INDICATOR_SIZE * 2),
            positioner.height + (COLOR_SELECTION_INDICATOR_SIZE * 2));

        // Handicap checkbox
        var handicapCheckbox :MovieClip = _movie["handicap"];
        registerListener(handicapCheckbox, MouseEvent.CLICK,
            function (...ignored) :void {
                updateHandicap(!_handicapOn);
            });
        _handicapIcon = ClientCtx.instantiateMovieClip("multiplayer_lobby", "handicapped");
        _handicapIcon.x = handicapCheckbox.x;
        _handicapIcon.y = handicapCheckbox.y;
        _handicapIcon.mouseEnabled = false;
        _movie.addChild(_handicapIcon);

        // The OK button just hides the popup.
        //var okButton :SimpleButton = _movie["OK_button"];
        var okButton :SimpleButton = UIBits.createButton("OK", 1.2);
        okButton.x = 169;
        okButton.y = 122;
        _movie.addChild(okButton);
        var thisPopup :PlayerOptionsPopup = this;
        registerListener(okButton, MouseEvent.CLICK,
            function (...ignored) :void {
                savePlayerOptions();
                thisPopup.visible = false;
            });
    }

    protected function createPortraitClickListener (portraitButton :Sprite, portraitName :String)
        :void
    {
        registerListener(portraitButton, MouseEvent.CLICK,
            function (...ignored) :void {
                updatePortraitSelection(portraitName);
            });
    }

    protected function createColorClickListener (colorButton :Sprite, color :uint) :void
    {
        registerListener(colorButton, MouseEvent.CLICK,
            function (...ignored) :void {
                updateColorSelection(color);
            });
    }

    protected function initPlayerOptions () :void
    {
    }

    protected function savePlayerOptions () :void
    {

    }

    protected function updatePortraitSelection (portraitName :String) :void
    {
        var idx :int = ArrayUtil.indexOf(Constants.PLAYER_PORTRAIT_NAMES, portraitName);
        if (idx < 0) {
            return;
        }

        var button :Sprite = _portraitButtons[idx];
        _portraitSelectionIndicator.x = (button.width - _portraitSelectionIndicator.width) * 0.5;
        _portraitSelectionIndicator.y = (button.height - _portraitSelectionIndicator.height) * 0.5;
        button.addChild(_portraitSelectionIndicator);
        _selectedPortrait = portraitName;
    }

    protected function updateColorSelection (color :uint) :void
    {
        var idx :int = ArrayUtil.indexOf(Constants.PLAYER_COLORS, color);
        if (idx < 0) {
            return;
        }

        var button :Sprite = _colorButtons[idx];
        _colorSelectionIndicator.x = (button.width - _colorSelectionIndicator.width) * 0.5;
        _colorSelectionIndicator.y = (button.height - _colorSelectionIndicator.height) * 0.5;
        button.addChild(_colorSelectionIndicator);
        _selectedColor = color;
    }

    protected function updateHandicap (on :Boolean) :void
    {
        _handicapOn = on;
        _handicapIcon.visible = on;
    }

    override public function get displayObject () :DisplayObject
    {
        return _sprite;
    }

    override public function get objectName () :String
    {
        return NAME;
    }

    protected var _sprite :Sprite;
    protected var _movie :MovieClip;
    protected var _handicapOn :Boolean;
    protected var _handicapIcon :MovieClip;

    protected var _portraitButtons :Array = [];
    protected var _portraitSelectionIndicator :Shape;
    protected var _selectedPortrait :String;
    protected var _colorButtons :Array = [];
    protected var _colorSelectionIndicator :Shape;
    protected var _selectedColor :uint;

    protected static const PORTRAIT_SELECTION_INDICATOR_SIZE :Number = 6;
    protected static const COLOR_SELECTION_INDICATOR_SIZE :Number = 4;
    protected static const NAME :String = "PlayerOptionsPopup";
}

}