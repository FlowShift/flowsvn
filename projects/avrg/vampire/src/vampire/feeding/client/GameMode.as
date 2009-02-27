package vampire.feeding.client {

import com.threerings.flash.Vector2;
import com.threerings.util.ArrayUtil;
import com.threerings.util.HashMap;
import com.threerings.util.Log;
import com.whirled.contrib.ColorMatrix;
import com.whirled.contrib.simplegame.*;
import com.whirled.contrib.simplegame.audio.AudioChannel;
import com.whirled.contrib.simplegame.net.*;
import com.whirled.contrib.simplegame.objects.SimpleSceneObject;
import com.whirled.contrib.simplegame.tasks.*;
import com.whirled.contrib.simplegame.util.*;

import flash.display.MovieClip;
import flash.display.Sprite;
import flash.geom.Point;
import flash.text.TextField;

import vampire.feeding.*;
import vampire.feeding.net.*;

public class GameMode extends AppMode
{
    public function GameMode ()
    {
        GameCtx.init();
        GameCtx.gameMode = this;
    }

    public function sendMultiplier (multiplier :int, x :int, y :int) :void
    {
        ClientCtx.msgMgr.sendMessage(
            CreateMultiplierMsg.create(ClientCtx.localPlayerId, x, y, multiplier));

        if (ClientCtx.isSinglePlayer) {
            // In single-player games, there's nobody else to volley our multipliers back
            // to us, so we fake it by sending occasionally sending fake multipliers to ourselves
            if (Rand.nextNumber(Rand.STREAM_GAME) < Constants.SP_MULTIPLIER_RETURN_CHANCE) {
                var sendMultiplierObj :SimObject = new SimObject();
                var loc :Vector2 = new Vector2(x, y);
                loc.x += Rand.nextNumberRange(5, 25, Rand.STREAM_COSMETIC);
                loc.y += Rand.nextNumberRange(5, 25, Rand.STREAM_COSMETIC);
                sendMultiplierObj.addTask(new SerialTask(
                    new TimedTask(Constants.SP_MULTIPLIER_RETURN_TIME.next()),
                    new FunctionTask(function () :void {
                        onCreateMultiplier(CreateMultiplierMsg.create(
                            Constants.NULL_PLAYER, loc.x, loc.y, multiplier + 1));
                    }),
                    new SelfDestructTask()));
                addObject(sendMultiplierObj);
            }
        }
    }

    override protected function setup () :void
    {
        super.setup();

        registerListener(ClientCtx.msgMgr, ClientMsgEvent.MSG_RECEIVED, onMsgReceived);

        // Setup display layers
        GameCtx.bgLayer = SpriteUtil.createSprite();
        GameCtx.cellBirthLayer = SpriteUtil.createSprite();
        GameCtx.heartLayer = SpriteUtil.createSprite();
        GameCtx.burstLayer = SpriteUtil.createSprite();
        GameCtx.cellLayer = SpriteUtil.createSprite();
        GameCtx.cursorLayer = SpriteUtil.createSprite();
        GameCtx.uiLayer = SpriteUtil.createSprite(true, true);
        _modeSprite.addChild(GameCtx.bgLayer);
        _modeSprite.addChild(GameCtx.cellBirthLayer);
        _modeSprite.addChild(GameCtx.heartLayer);
        _modeSprite.addChild(GameCtx.burstLayer);
        _modeSprite.addChild(GameCtx.cellLayer);
        _modeSprite.addChild(GameCtx.cursorLayer);
        _modeSprite.addChild(GameCtx.uiLayer);

        if (Constants.DEBUG_SHOW_STATS) {
            var statView :StatView = new StatView();
            statView.x = 0;
            statView.y = 460;
            addObject(statView, GameCtx.uiLayer);
        }

        // Setup game objects
        GameCtx.bgLayer.addChild(ClientCtx.instantiateBitmap("bg"));

        var heartMovie :MovieClip = ClientCtx.instantiateMovieClip("blood", "circulatory");
        heartMovie.x = Constants.GAME_CTR.x;
        heartMovie.y = Constants.GAME_CTR.y;
        GameCtx.heartLayer.addChild(heartMovie);

        _arteries = ArrayUtil.create(2, null);
        _arteries[Constants.ARTERY_TOP] = heartMovie["artery_top"];
        _arteries[Constants.ARTERY_BOTTOM] = heartMovie["artery_bottom"];

        _sparkles = heartMovie["sparkles"];

        GameCtx.heart = new Heart(heartMovie["heart"]);
        GameCtx.gameMode.addObject(GameCtx.heart);
        registerListener(GameCtx.heart, GameEvent.HEARTBEAT, onHeartbeat);

        // spawn white cells on a timer separate from the heartbeat
        var whiteCellSpawner :SimObject = new SimObject();
        whiteCellSpawner.addTask(new RepeatingTask(
            new VariableTimedTask(
                Constants.WHITE_CELL_CREATION_TIME.min,
                Constants.WHITE_CELL_CREATION_TIME.max,
                Rand.STREAM_GAME),
            new FunctionTask(function () :void {
                spawnCells(Constants.CELL_WHITE, Constants.WHITE_CELL_CREATION_COUNT.next());
            })));
        addObject(whiteCellSpawner);

        var timerView :TimerView = new TimerView();
        timerView.x = TIMER_LOC.x;
        timerView.y = TIMER_LOC.y;
        addObject(timerView, GameCtx.uiLayer);

        GameCtx.scoreView = new ScoreHelpQuitView();
        GameCtx.scoreView.x = SCORE_LOC.x;
        GameCtx.scoreView.y = SCORE_LOC.y;
        addObject(GameCtx.scoreView, GameCtx.uiLayer);

        GameCtx.cursor = GameObjects.createPlayerCursor();
        registerListener(GameCtx.cursor, GameEvent.WHITE_CELL_DELIVERED, onWhiteCellDelivered);

        // this will handle spawning the special Blood Hunt cells
        addObject(new SpecialCellSpawner());

        // create some non-interactive debris that floats around the heart
        for (var ii :int = 0; ii < Constants.DEBRIS_COUNT; ++ii) {
            addObject(new Debris(), GameCtx.bgLayer);
        }

        if (ClientCtx.noMoreFeeding) {
            onNoMoreFeeding(false);
        }
    }

    override protected function enter () :void
    {
        super.enter();
        if (_musicChannel == null) {
            _musicChannel = ClientCtx.audio.playSoundNamed("mus_main_theme", null, -1);
        }
    }

    override protected function destroy () :void
    {
        if (_musicChannel != null) {
            _musicChannel.audioControls.fadeOutAndStop(0.5);
            _musicChannel = null;
        }
    }

    protected function onMsgReceived (e :ClientMsgEvent) :void
    {
        log.info("onMsgReceived", "name", e.msg.name);

        if (e.msg is CreateMultiplierMsg) {
            onCreateMultiplier(e.msg as CreateMultiplierMsg);

        } else if (e.msg is GetRoundScores) {
            // Send our final score to the server. We'll wait for the GameResultsMsg
            // to display the round over screen.
            ClientCtx.msgMgr.sendMessage(RoundScoreMsg.create(GameCtx.scoreView.bloodCount));

        } else if (e.msg is RoundOverMsg) {
            onRoundOver(e.msg as RoundOverMsg);

        } else if (e.msg is NoMoreFeedingMsg) {
            onNoMoreFeeding(true);
        }
    }

    protected function onRoundOver (results :RoundOverMsg) :void
    {
        ClientCtx.mainLoop.changeMode(new RoundOverMode(results));
    }

    protected function onCreateMultiplier (msg :CreateMultiplierMsg) :void
    {
        if (msg.playerId != ClientCtx.localPlayerId) {
            // make sure the cell is spawning far enough way from the heart
            var loc :Vector2 = new Vector2(msg.x, msg.y);
            var requiredDist :NumRange = Constants.CELL_BIRTH_DISTANCE[Constants.CELL_MULTIPLIER];
            var dist :Number = loc.subtract(Constants.GAME_CTR).length;
            if (dist < requiredDist.min || dist > requiredDist.max) {
                loc = loc.subtract(Constants.GAME_CTR);
                loc.length = requiredDist.next();
                loc.addLocal(Constants.GAME_CTR);
            }

            // animate the bonus into the game, and call addMultiplierToBoard
            // when the anim completes
            var anim :NewBonusAnimation = new NewBonusAnimation(
                NewBonusAnimation.TYPE_RECEIVE,
                msg.multiplier,
                loc,
                function () :void { addMultiplierToBoard(msg.multiplier, loc, msg.playerId); });

            addObject(anim, GameCtx.uiLayer);
        }
    }

    protected function addMultiplierToBoard (multiplier :int, loc :Vector2, playerId :int) :void
    {
        var cell :Cell = GameObjects.createCell(Constants.CELL_MULTIPLIER, false, multiplier);
        cell.x = loc.x;
        cell.y = loc.y;

        if (!ClientCtx.isSinglePlayer) {
            // show a little animation showing who gave us the multiplier
            var playerName :String = ClientCtx.getPlayerName(playerId);
            var tfName :TextField = TextBits.createText(playerName, 1.4, 0, 0xffffff,
                                                        "center", TextBits.FONT_GARAMOND);
            tfName.cacheAsBitmap = true;
            var sprite :Sprite = SpriteUtil.createSprite();
            sprite.addChild(tfName);
            var animName :SimpleSceneObject = new SimpleSceneObject(sprite);
            var animX :Number = loc.x - (animName.width * 0.5);
            var animY :Number = loc.y - animName.height;
            animName.x = animX;
            animName.y = animY;
            animName.addTask(new SerialTask(
                new TimedTask(1),
                new AlphaTask(0, 0.5)));
            animName.addTask(new SerialTask(
                new TimedTask(0.5),
                LocationTask.CreateEaseIn(animX, animY - 50, 1),
                new SelfDestructTask()));
            addObject(animName, GameCtx.uiLayer);
        }
    }

    override public function update (dt :Number) :void
    {
        GameCtx.timeLeft = Math.max(GameCtx.timeLeft - dt, 0);

        // For testing purposes, end the game manually if we're in standalone mode
        if (GameCtx.timeLeft == 0 && !ClientCtx.isConnected) {
            var scores :HashMap = new HashMap();
            scores.put(ClientCtx.localPlayerId, GameCtx.scoreView.bloodCount);
            onRoundOver(RoundOverMsg.create(scores, 1, 0.25));
            return;
        }

        // Move the player cursor towards the mouse
        var moveTarget :Vector2 = new Vector2(GameCtx.cellLayer.mouseX, GameCtx.cellLayer.mouseY);
        if (!moveTarget.equals(_lastMoveTarget)) {
            GameCtx.cursor.moveTarget = moveTarget;
            _lastMoveTarget = moveTarget;
        }

        super.update(dt);
    }

    protected function onHeartbeat (...ignored) :void
    {
        // spawn new red cells
        spawnCells(Constants.CELL_RED, Constants.BEAT_CELL_BIRTH_COUNT.next());
    }

    protected function spawnCells (cellType :int, count :int) :void
    {
        count = Math.min(count, Constants.MAX_CELL_COUNT[cellType] - Cell.getCellCount(cellType));
        for (var ii :int = 0; ii < count; ++ii) {
            GameObjects.createCell(cellType, true);
        }
    }

    protected function onWhiteCellDelivered (e :GameEvent) :void
    {
        GameCtx.heart.deliverWhiteCell();

        // show the delivery animation
        var arteryType :int = e.data as int;
        var artery :MovieClip = _arteries[arteryType];
        artery.gotoAndPlay(2);

        _sparkles.gotoAndPlay(2);
    }

    protected function onNoMoreFeeding (animate :Boolean) :void
    {
        var color :ColorMatrix = new ColorMatrix();
        var greyscale :ColorMatrix = new ColorMatrix().makeGrayscale();

        if (animate) {
            var animObj :SimObject = new SimObject();
            animObj.addTask(new SerialTask(
                new ParallelTask(
                    new ColorMatrixBlendTask(GameCtx.bgLayer, color, greyscale, 4),
                    new ColorMatrixBlendTask(GameCtx.heartLayer, color, greyscale, 4)),
                new SelfDestructTask()));
            addObject(animObj);

        } else {
            GameCtx.bgLayer.filters = [ greyscale.createFilter() ];
            GameCtx.heartLayer.filters = [ greyscale.createFilter() ];
        }
    }

    protected var _playerType :int;
    protected var _gameOver :Boolean;
    protected var _arteries :Array;
    protected var _sparkles :MovieClip;
    protected var _lastMoveTarget :Vector2 = new Vector2();
    protected var _musicChannel :AudioChannel;

    protected static var log :Log = Log.getLog(GameMode);

    protected static const SCORE_LOC :Point = Constants.GAME_CTR.toPoint();
    protected static const TIMER_LOC :Point = Constants.GAME_CTR.toPoint();
    protected static const SCORE_VIEWS_LOC :Point = new Point(550, 120);
}

}

import com.whirled.contrib.simplegame.SimObject;

import vampire.feeding.*;
import vampire.feeding.client.*;

class SpecialCellSpawner extends SimObject
{
    override protected function update (dt :Number) :void
    {
        if (!Constants.DEBUG_FORCE_SPECIAL_BLOOD_STRAIN && !this.canCollectPreyStrain) {
            destroySelf();
            return;
        }

        _elapsedTime += dt;

        if (Cell.getCellCount(Constants.CELL_SPECIAL) == 0) {
            if (_nextSpawnTime < 0) {
                _nextSpawnTime = _elapsedTime + Constants.SPECIAL_CELL_CREATION_TIME.next();
            } else if (_elapsedTime >= _nextSpawnTime) {
                GameObjects.createCell(Constants.CELL_SPECIAL, true, ClientCtx.preyBloodType);
                _nextSpawnTime = -1;
            }
        }
    }

    protected function get canCollectPreyStrain () :Boolean
    {
        // Is there a special blood strain to collect from the prey? Can we collect it?
        return (!ClientCtx.isPrey &&
                !ClientCtx.isAiPrey &&
                ClientCtx.preyBloodType >= 0 &&
                ClientCtx.playerData.canCollectStrainFromPlayer(ClientCtx.preyBloodType,
                                                                ClientCtx.preyId));
    }

    protected var _elapsedTime :Number = 0;
    protected var _nextSpawnTime :Number = -1;
}
