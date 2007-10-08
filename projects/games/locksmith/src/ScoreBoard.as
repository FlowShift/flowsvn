// $Id$

package {

import flash.display.Sprite;

import flash.display.MovieClip;

import flash.geom.Point;

public class ScoreBoard extends Sprite 
{
    public static const MOON_PLAYER :int = 1;
    public static const SUN_PLAYER :int = 2;

    public function ScoreBoard (moonPlayer :String, sunPlayer :String, gameEndedCallback :Function) 
    {
        addChild(_marbleLayer = new Sprite());
        var trough :Sprite = new TROUGH_OVERLAY() as Sprite;
        trough.y = 210;
        addChild(trough);
        _gameEndedCallback = gameEndedCallback;
    }

    public function get moonScore () :int
    {
        return _moonScore;
    }

    public function get sunScore () :int
    {
        return _sunScore;
    }

    public function scorePoint (player :int) :void
    {
        if (player == MOON_PLAYER) {
            scorePointAnimation(player, ++_moonScore);
            if (_moonScore == Locksmith.WIN_SCORE) {
                gameOver();
            }
        } else if (player == SUN_PLAYER) {
            scorePointAnimation(player, ++_sunScore);
            if (_sunScore == Locksmith.WIN_SCORE) {
                gameOver();
            }
        } else {
            Log.getLog(this).debug("Asked to score point for unknown player [" + player + "]");
        }
    }

    protected function gameOver () :void
    {
        if (_gameEndedCallback == null) {
            return;
        }

        _gameEndedCallback();
        _gameEndedCallback = null;
    }

    protected function scorePointAnimation (player :int, point :int) :void
    {
        if (player == MOON_PLAYER) {
            var marble :MarbleMovie = new MarbleMovie(Marble.MOON);
            marble.x = MOON_RAMP_BEGIN.x + 22;
            marble.y = MOON_RAMP_BEGIN.y - 10;
            marble.rotation = 90;
            marble.gotoAndPlay((Math.random() * marble.totalFrames) + 1);
            _marbleLayer.addChild(marble);
            new RampAnimation(marble, MOON_RAMP_BEGIN.clone(), MOON_RAMP_END.clone(), point);
        } else {
            marble = new MarbleMovie(Marble.SUN);
            marble.x = SUN_RAMP_BEGIN.x - 22;
            marble.y = SUN_RAMP_BEGIN.y - 10;
            marble.rotation = -90;
            marble.gotoAndPlay((Math.random() * marble.totalFrames) + 1);
            _marbleLayer.addChild(marble);
            new RampAnimation(marble, SUN_RAMP_BEGIN.clone(), SUN_RAMP_END.clone(), point);
        }
    }

    [Embed(source="../rsrc/locksmith_art.swf#trough_overlay")]
    protected static const TROUGH_OVERLAY :Class;

    protected static const SUN_RAMP_BEGIN :Point = new Point(256, 38);
    protected static const SUN_RAMP_END :Point = new Point(313, 199);
    protected static const MOON_RAMP_BEGIN :Point = new Point(-257, 38);
    protected static const MOON_RAMP_END :Point = new Point(-312, 199);

    protected var _moonScore :int = 0;
    protected var _sunScore :int = 0;
    protected var _gameEndedCallback :Function;
    protected var _marbleLayer :Sprite = new Sprite();
}
}

import flash.display.DisplayObjectContainer;
import flash.display.Sprite;

import flash.events.Event;

import flash.geom.Matrix;
import flash.geom.Point;

import MarbleMovie;

class RampAnimation
{
    public function RampAnimation (marble :MarbleMovie, rampTop :Point, rampBottom :Point, 
        myScore :int)
    {
        _marble = marble;
        _startX = _marble.x;
        _startY = _marble.y;
        _rampTop = rampTop;
        _rampBottom = rampBottom;
        _phase = PHASE_MOVE_TO_RAMP;
        _myScore = myScore;

        // replace the marble on the marble's parent with a layer that only shows the ramp top hole
        // via masking so that the marble seems to roll into place at the hole.
        var mask :Sprite = new Sprite();
        mask.graphics.beginFill(0);
        mask.graphics.drawCircle(rampTop.x, rampTop.y, MARBLE_RADIUS);
        mask.graphics.endFill();
        var marbleLayer :Sprite = new Sprite();
        marbleLayer.mask = mask;
        marbleLayer.addChild(mask);
        var parent :DisplayObjectContainer = _marble.parent;
        parent.removeChild(_marble);
        marbleLayer.addChild(_marble);
        parent.addChildAt(marbleLayer, 0);
        _darkness = new Sprite();
        _darkness.graphics.beginFill(0);
        _darkness.graphics.drawCircle(rampTop.x, rampTop.y, MARBLE_RADIUS);
        _darkness.graphics.endFill();
        marbleLayer.addChild(_darkness);

        _marble.addEventListener(Event.ENTER_FRAME, enterFrame);
    }

    protected function enterFrame (evt :Event) :void
    {
        switch(_phase) {
        case PHASE_MOVE_TO_RAMP: moveTowardsRamp(); break;
        case PHASE_MOVE_DOWN_RAMP: moveDownRamp(); break;
        default:
            Log.getLog(this).debug("Unknown phase [" + _phase + "]");
            _marble.removeEventListener(Event.ENTER_FRAME, enterFrame);
        }
    }

    protected function moveTowardsRamp () :void
    {
        if (_fadeInTime++ < FADE_IN_TIME) {
            _marble.x = (_fadeInTime / FADE_IN_TIME) * (_rampTop.x - _startX) + _startX;
            _marble.y = (_fadeInTime / FADE_IN_TIME) * (_rampTop.y - _startY) + _startY;
            _darkness.graphics.clear();
            _darkness.graphics.beginFill(0, 1 - _fadeInTime / FADE_IN_TIME);
            _darkness.graphics.drawCircle(_rampTop.x, _rampTop.y, MARBLE_RADIUS);
            _darkness.graphics.endFill();
        } else {
            _marble.x = _rampTop.x;
            _marble.y = _rampTop.y;
            _phase = PHASE_MOVE_DOWN_RAMP;
            var parent :DisplayObjectContainer = _marble.parent.parent;
            parent.removeChild(_marble.parent);
            _marble.parent.removeChild(_marble);
            parent.addChildAt(_marble, 0);
        }
    }

    protected function moveDownRamp () :void
    {
        var percent :Number;
        if (++_rollDownTime < ROLL_DOWN_TIME * (1 - (_myScore - 1) / 10)) {
            percent = _rollDownTime / ROLL_DOWN_TIME;
            percent = Math.pow(percent, 2);
        } else {
            _marble.removeEventListener(Event.ENTER_FRAME, enterFrame);
            _marble.stop();
            percent = 1 - (_myScore - 1) / 10;
            percent = Math.pow(percent, 2);
        }
        _marble.scaleX = _marble.scaleY = percent * (FINAL_SCALE - 1) + 1;
        _marble.x = Math.pow(percent, 1.80) * (_rampBottom.x - _rampTop.x) + _rampTop.x;
        _marble.y = (1 - Math.pow(1 - percent, 1.50)) * (_rampBottom.y - _rampTop.y) + _rampTop.y;
    }

    protected static const PHASE_MOVE_TO_RAMP :int = 1;
    protected static const PHASE_MOVE_DOWN_RAMP :int = 2;

    protected static const FADE_IN_TIME :int = 15; // in frames;
    protected static const ROLL_DOWN_TIME :int = 15; // in frames;

    protected static const FINAL_SCALE :Number = 1.3;

    protected static const MARBLE_RADIUS :Number = 20;

    protected var _marble :MarbleMovie;
    protected var _rampTop :Point;
    protected var _rampBottom :Point;
    protected var _phase :int;
    protected var _darkness :Sprite;
    protected var _fadeInTime :int = 0;
    protected var _startX :int;
    protected var _startY :int;
    protected var _rollDownTime :int = 0;
    protected var _myScore :int;
}
