package bloodbloom {

import com.threerings.flash.Vector2;
import com.whirled.contrib.simplegame.AppMode;
import com.whirled.contrib.simplegame.SimObject;
import com.whirled.contrib.simplegame.tasks.*;
import com.whirled.contrib.simplegame.util.NumRange;
import com.whirled.contrib.simplegame.util.Rand;

import flash.display.Sprite;
import flash.geom.Point;

public class GameMode extends AppMode
{
    override protected function setup () :void
    {
        super.setup();

        ClientCtx.gameMode = this;

        // Setup display layers
        _modeSprite.addChild(ClientCtx.instantiateBitmap("bg"));

        _cellLayer = SpriteUtil.createSprite();
        _cursorLayer = SpriteUtil.createSprite();
        _effectLayer = SpriteUtil.createSprite();
        _modeSprite.addChild(_cellLayer);
        _modeSprite.addChild(_cursorLayer);
        _modeSprite.addChild(_effectLayer);

        // Setup game objects
        ClientCtx.beat = new Beat();
        addObject(ClientCtx.beat);

        ClientCtx.bloodMeter = new PredatorBloodMeter();
        ClientCtx.bloodMeter.x = BLOOD_METER_LOC.x;
        ClientCtx.bloodMeter.y = BLOOD_METER_LOC.y;
        addObject(ClientCtx.bloodMeter, _effectLayer);

        var heart :Heart = new Heart();
        heart.x = Constants.GAME_CTR.x;
        heart.y = Constants.GAME_CTR.y;
        addObject(heart, _cellLayer);

        // setup cells
        for (var type :int = 0; type < Constants.CELL__LIMIT; ++type) {
            // create initial cells
            for (var ii :int = 0; ii < Constants.INITIAL_CELL_COUNT[type]; ++ii) {
                spawnCell(type, false);
            }

            // spawn new cells on a timer
            var spawnRate :NumRange = Constants.CELL_SPAWN_RATE[type];
            var spawner :SimObject = new SimObject();
            spawner.addTask(new RepeatingTask(
                new VariableTimedTask(spawnRate.min, spawnRate.max, Rand.STREAM_GAME),
                new FunctionTask(createCellSpawnCallback(type))));
            addObject(spawner);
        }

        addObject(new PreyCursor(false), _cursorLayer);
        addObject(new PredatorCursor(true), _cursorLayer);
    }

    protected function createCellSpawnCallback (type :int) :Function
    {
        return function () :void {
            if (Cell.getCellCount(type) < Constants.MAX_CELL_COUNT[type]) {
                spawnCell(type, true);
            }
        };
    }

    protected function spawnCell (type :int, fadeIn :Boolean) :void
    {
        // pick a random location for the cell
        var angle :Number = Rand.nextNumberRange(0, Math.PI * 2, Rand.STREAM_GAME);
        var dist :Number = Constants.CELL_SPAWN_RADIUS.next();
        var loc :Vector2 = Vector2.fromAngle(angle, dist).add(Constants.GAME_CTR);

        // spawn
        var cell :Cell = new Cell(type, fadeIn);
        cell.x = loc.x;
        cell.y = loc.y;
        addObject(cell, _cellLayer);
    }

    override public function update (dt :Number) :void
    {
        super.update(dt);
        _modeTime += dt;
    }

    public function gameOver (reason :String) :void
    {
        if (!_gameOver) {
            ClientCtx.mainLoop.changeMode(new GameOverMode(reason));
            _gameOver = true;
        }
    }

    public function get modeTime () :Number
    {
        return _modeTime;
    }

    protected var _modeTime :Number = 0;
    protected var _gameOver :Boolean;

    protected var _cellLayer :Sprite;
    protected var _cursorLayer :Sprite;
    protected var _effectLayer :Sprite;

    protected static const BLOOD_METER_LOC :Point = new Point(550, 75);
}

}
