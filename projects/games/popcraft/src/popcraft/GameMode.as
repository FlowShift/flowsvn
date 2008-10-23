package popcraft {

import com.threerings.util.ArrayUtil;
import com.threerings.util.ClassUtil;
import com.threerings.util.KeyboardCodes;
import com.threerings.util.Log;
import com.whirled.contrib.simplegame.*;
import com.whirled.contrib.simplegame.audio.*;
import com.whirled.contrib.simplegame.net.*;
import com.whirled.contrib.simplegame.resource.*;
import com.whirled.contrib.simplegame.util.*;
import com.whirled.game.OccupantChangedEvent;
import com.whirled.game.StateChangedEvent;

import flash.display.DisplayObjectContainer;
import flash.geom.Point;

import popcraft.battle.*;
import popcraft.battle.geom.ForceParticleContainer;
import popcraft.battle.view.*;
import popcraft.data.*;
import popcraft.mp.*;
import popcraft.net.*;
import popcraft.puzzle.*;
import popcraft.sp.*;
import popcraft.sp.story.*;
import popcraft.ui.*;
import popcraft.util.*;

public class GameMode extends TransitionMode
{
    public static const FADE_OUT_TIME :Number = 3;

    public function GameMode ()
    {
        if (ClassUtil.getClass(this) == GameMode) {
            throw new Error("GameMode is abstract");
        }
    }

    override protected function setup () :void
    {
        Profiler.reset();

        GameContext.gameMode = this;
        GameContext.playerStats = new PlayerStats();

        // init RNGs
        var randSeed :uint = createRandSeed();
        Rand.seedStream(AppContext.randStreamPuzzle, randSeed);
        Rand.seedStream(Rand.STREAM_GAME, randSeed);
        log.info("Starting game with seed: " + randSeed);

        // allow subclasses to do some post-RNG-seeding early setup
        this.rngSeeded();

        // cache some frequently-used values in GameContext
        GameContext.mapScaleXInv = 1 / GameContext.gameMode.mapSettings.mapScaleX;
        GameContext.mapScaleYInv = 1 / GameContext.gameMode.mapSettings.mapScaleY;
        GameContext.scaleSprites = GameContext.gameMode.mapSettings.scaleSprites;

        // create some layers
        GameContext.battleLayer = SpriteUtil.createSprite(true, false);
        GameContext.dashboardLayer = SpriteUtil.createSprite(true, false);
        GameContext.overlayLayer = SpriteUtil.createSprite();
        _modeLayer.addChild(GameContext.battleLayer);
        _modeLayer.addChild(GameContext.dashboardLayer);
        _modeLayer.addChild(GameContext.overlayLayer);

        this.setupAudio();
        this.setupNetwork();
        this.setupBattle();
        this.setupPlayers();
        this.setupDashboard();

        // create the spell drop timer after setting up players; available
        // spells may not be known until this point
        GameContext.netObjects.addObject(new SpellDropTimer());

        _trophyWatcher = new TrophyWatcher();

        if (Constants.DEBUG_DRAW_STATS) {
            _debugDataView = new DebugDataView();
            this.addObject(_debugDataView, GameContext.overlayLayer);
            _debugDataView.visible = true;
        }
    }

    override protected function destroy () :void
    {
        this.shutdownNetwork();
        this.shutdownAudio();

        Profiler.displayStats();
    }

    override protected function enter () :void
    {
        // game audio isn't started until _updateCount hits 1,
        // to allow intro screens to be shown
        if (_updateCount > 0) {
            GameContext.sfxControls.pause(false);
            GameContext.musicControls.pause(false);
            GameContext.musicControls.volumeTo(1, 0.3);
        }
    }

    override protected function exit () :void
    {
        // if the game is over, we're already fading out our music
        if (_gameOver) {
            return;
        }

        if (GameContext.sfxControls != null) {
            GameContext.sfxControls.pause(true);
        }

        if (GameContext.musicControls != null) {
            GameContext.musicControls.volumeTo(0.2, 0.3);
        }
    }

    protected function setupAudio () :void
    {
        GameContext.playAudio = this.playAudio;

        GameContext.sfxControls = new AudioControls(
            AudioManager.instance.getControlsForSoundType(SoundResource.TYPE_SFX));
        GameContext.musicControls = new AudioControls(
            AudioManager.instance.getControlsForSoundType(SoundResource.TYPE_MUSIC));

        GameContext.sfxControls.retain();
        GameContext.musicControls.retain();

        GameContext.sfxControls.pause(true);
        GameContext.musicControls.pause(true);
    }

    protected function shutdownAudio () :void
    {
        GameContext.sfxControls.stop(true);
        GameContext.musicControls.stop(true);

        GameContext.sfxControls.release();
        GameContext.musicControls.release();
    }

    protected function handleOccupantLeft (e :OccupantChangedEvent) :void
    {
        if (e.player) {
            // did a player leave?
            var playerInfo :PlayerInfo = ArrayUtil.findIf(GameContext.playerInfos,
                function (data :PlayerInfo) :Boolean {
                    return data.whirledId == e.occupantId;
                });

            if (null != playerInfo) {
                playerInfo.leftGame = true;
            }
        }
    }

    protected function handleGameEndedPrematurely (...ignored) :void
    {
        // If the game ends prematurely for some reason, handle it gracefully
        AppContext.mainLoop.unwindToMode(new MultiplayerFailureMode());
    }

    protected function setupNetwork () :void
    {
        // create a special ObjectDB for all objects that are synchronized over the network.
        GameContext.netObjects = new NetObjectDB();

        // set up the message manager
        _messageMgr = this.createMessageManager();
        _messageMgr.addMessageType(CreateUnitMessage);
        _messageMgr.addMessageType(SelectTargetEnemyMessage);
        _messageMgr.addMessageType(CastCreatureSpellMessage);
        _messageMgr.addMessageType(ResurrectPlayerMessage);
    }

    protected function shutdownNetwork () :void
    {
        _messageMgr.stop();
    }

    protected function setupDashboard () :void
    {
        var dashboard :DashboardView = new DashboardView();
        dashboard.x = DASHBOARD_LOC.x;
        dashboard.y = DASHBOARD_LOC.y;
        this.addObject(dashboard, GameContext.dashboardLayer);

        GameContext.dashboard = dashboard;

        var puzzleBoard :PuzzleBoard = new PuzzleBoard(PUZZLE_COLS, PUZZLE_ROWS, PUZZLE_TILE_SIZE);

        puzzleBoard.displayObject.x = PUZZLE_BOARD_LOC.x;
        puzzleBoard.displayObject.y = PUZZLE_BOARD_LOC.y;

        DisplayObjectContainer(dashboard.displayObject).addChildAt(puzzleBoard.displayObject, 0);
        this.addObject(puzzleBoard);

        GameContext.puzzleBoard = puzzleBoard;
    }

    protected function setupPlayers () :void
    {
        GameContext.playerInfos = [];

        // we want to know when a player leaves
        this.registerListener(AppContext.gameCtrl.game, OccupantChangedEvent.OCCUPANT_LEFT,
            handleOccupantLeft);

        // subclasses create the players in this function
        this.createPlayers();

        this.updateTargetEnemyBadgeLocation(GameContext.localPlayerInfo.targetedEnemy.playerIndex);
    }

    protected function setupBattle () :void
    {
        GameContext.unitFactory = new UnitFactory();

        GameContext.forceParticleContainer = new ForceParticleContainer(
            GameContext.gameMode.battlefieldWidth,
            GameContext.gameMode.battlefieldHeight);

        // Board
        var battleBoardView :BattleBoardView = new BattleBoardView(BATTLE_WIDTH, BATTLE_HEIGHT);
        this.addObject(battleBoardView, GameContext.battleLayer);

        GameContext.battleBoardView = battleBoardView;

        // Day/night cycle
        GameContext.diurnalCycle = new DiurnalCycle();
        GameContext.netObjects.addObject(GameContext.diurnalCycle);

        if (!DiurnalCycle.isDisabled) {
            var diurnalMeter :DiurnalCycleView = new DiurnalCycleView();
            diurnalMeter.x = DIURNAL_METER_LOC.x;
            diurnalMeter.y = DIURNAL_METER_LOC.y;
            this.addObject(diurnalMeter, GameContext.battleBoardView.diurnalMeterParent);
        }
    }

    /**
     * Subclasses must call this function when they're ready to start the game. This should
     * usually be when the GAME_STARTED event is received, or all players have checked in,
     * or something similar.
     */
    protected function startGame () :void
    {
        this.registerListener(AppContext.gameCtrl.game, StateChangedEvent.GAME_ENDED,
            handleGameEndedPrematurely);

        _messageMgr.run();
    }

    override public function onKeyDown (keyCode :uint) :void
    {
        if (_gameOver) {
            return;
        }

        switch (keyCode) {
        case KeyboardCodes.A:
            this.localPlayerPurchasedCreature(Constants.UNIT_TYPE_COLOSSUS);
            break;

        case KeyboardCodes.S:
            this.localPlayerPurchasedCreature(Constants.UNIT_TYPE_COURIER);
            break;

        case KeyboardCodes.D:
            this.localPlayerPurchasedCreature(Constants.UNIT_TYPE_SAPPER);
            break;

        case KeyboardCodes.F:
            this.localPlayerPurchasedCreature(Constants.UNIT_TYPE_HEAVY);
            break;

        case KeyboardCodes.G:
            this.localPlayerPurchasedCreature(Constants.UNIT_TYPE_GRUNT);
            break;

        case KeyboardCodes.ESCAPE:
            if (this.canPause) {
                this.pause();
            }
            break;

        case KeyboardCodes.NUMBER_5:
            if (null != _debugDataView) {
                _debugDataView.visible = !(_debugDataView.visible);
            }
            break;

        default:
            if (Constants.DEBUG_ALLOW_CHEATS) {
                this.applyCheatCode(keyCode);
            }
            break;
        }
    }

    public function pause () :void
    {
        if (!_gameOver && this.canPause) {
            AppContext.mainLoop.pushMode(new PauseMode());
        }
    }

    protected function applyCheatCode (keyCode :uint) :void
    {
        switch (keyCode) {
        case KeyboardCodes.NUMBER_4:
            for (var i :int = 0; i < Constants.RESOURCE__LIMIT; ++i) {
                GameContext.localPlayerInfo.offsetResourceAmount(i, 500);
            }
            break;

        case KeyboardCodes.B:
            this.spellDeliveredToPlayer(GameContext.localPlayerIndex,
                Constants.SPELL_TYPE_BLOODLUST);
            break;

        case KeyboardCodes.R:
            this.spellDeliveredToPlayer(GameContext.localPlayerIndex,
                Constants.SPELL_TYPE_RIGORMORTIS);
            break;

        case KeyboardCodes.P:
            this.spellDeliveredToPlayer(GameContext.localPlayerIndex,
                Constants.SPELL_TYPE_PUZZLERESET);
            break;

        case KeyboardCodes.N:
            GameContext.diurnalCycle.resetPhase(Constants.PHASE_NIGHT);
            break;

        case KeyboardCodes.Y:
            GameContext.diurnalCycle.incrementDayCount();
            GameContext.diurnalCycle.resetPhase(
                GameContext.gameData.enableEclipse ? Constants.PHASE_ECLIPSE :
                Constants.PHASE_DAY);
            break;

        case KeyboardCodes.K:
            // destroy the targeted enemy's base
            var enemyPlayerInfo :PlayerInfo = GameContext.localPlayerInfo.targetedEnemy;
            if (null != enemyPlayerInfo.workshop) {
                enemyPlayerInfo.workshop.health = 0;
            }
            break;

        case KeyboardCodes.E:
            // destroy the local player's base
            var localWorkshop :WorkshopUnit = GameContext.localPlayerInfo.workshop;
            if (null != GameContext.localPlayerInfo.workshop) {
                GameContext.localPlayerInfo.workshop.health = 0;
            }
            break;

        case KeyboardCodes.W:
            // destroy all enemy bases
            for each (var playerInfo :PlayerInfo in GameContext.playerInfos) {
                if (playerInfo.teamId != GameContext.localPlayerInfo.teamId) {
                    if (null != playerInfo.workshop) {
                        playerInfo.workshop.health = 0;
                    }
                }
            }
            break;
        }
    }

    // from AppMode
    override public function update (dt :Number) :void
    {
        if (!_gameIsRunning) {
            // don't start doing anything until the messageMgr is ready
            if (_messageMgr.isReady) {
                _gameIsRunning = true;
            } else if (!SeatingManager.allPlayersPresent) {
                // If a player leaves before the game starts, the messageMgr will never
                // be ready.
                AppContext.mainLoop.unwindToMode(new MultiplayerFailureMode());
                return;
            } else {
                return;
            }
        }

        // start the game audio when _updateCount hits 1, allowing a full update to pass without
        // audio so that intro screens can be shown
        if (_updateCount == 1) {
            GameContext.musicControls.pause(false);
            GameContext.sfxControls.pause(false);
        }

        // update the network
        _messageMgr.update(dt);

        var displayChildrenNeedSort :Boolean
        while (_messageMgr.unprocessedTickCount > 0 && !_gameOver) {
            // update all networked objects - that is, all objects involved in the actual
            // game simulation
            this.updateNetworkedObjects();

            // if the network simulation is updated, we'll need to depth-sort
            // the battlefield display objects
            displayChildrenNeedSort = true;
        }

        if (!_handlingGameOver && _gameOver) {
            _handlingGameOver = true;
            this.handleGameOver();
        }

        // update all non-net objects
        super.update(dt);

        if (displayChildrenNeedSort) {
            GameContext.battleBoardView.sortUnitDisplayChildren();
        }

        // update the game music, unless we're in "eclipse mode", where we loop
        // the night music forever
        var dayPhase :int = GameContext.diurnalCycle.phaseOfDay;
        if (!_startedMusic || (dayPhase != _lastDayPhase && !GameContext.gameData.enableEclipse)) {
            if (null != _musicChannel) {
                _musicChannel.audioControls.fadeOut(0.5).stopAfter(0.5);
            }

            _musicChannel = GameContext.playGameMusic(
                DiurnalCycle.isDay(dayPhase) ? "mus_day" : "mus_night");

            _lastDayPhase = dayPhase;
            _startedMusic = true;
        }

        ++_updateCount;
    }

    protected function updateNetworkedObjects () :void
    {
        // process all messages from this tick
        var messageArray: Array = _messageMgr.getNextTick();
        for each (var msg :Message in messageArray) {
            this.handleMessage(msg);
        }

        // AI messages are identical to other messages, but are kept in a separate Array so
        // that we don't generate unnecessary network traffic when playing a multiplayer game with
        // computer AIs
        for each (msg in _aiPlayerMessages) {
            this.handleMessage(msg);
        }

        _aiPlayerMessages = [];

        // run the simulation the appropriate amount
        // (Our network update time is unrelated to the application's update time.
        // Network timeslices are always the same distance apart)
        GameContext.netObjects.update(TICK_INTERVAL_S);

        this.updateTeamLiveStatuses();
        this.checkForGameOver();

        ++_gameTickCount;
        _gameTime += TICK_INTERVAL_S;
    }

    protected function updateTeamLiveStatuses () :void
    {
        var playerInfo :PlayerInfo;

        if (_teamLiveStatuses == null) {
            _teamLiveStatuses = [];
            for each (playerInfo in GameContext.playerInfos) {
                var teamId :int = playerInfo.teamId;
                while (_teamLiveStatuses.length < teamId + 1) {
                    _teamLiveStatuses.push(false);
                }
                if (playerInfo.isAlive) {
                    _teamLiveStatuses[teamId] = true;
                }
            }
        }

        for (var ii :int = 0; ii < _teamLiveStatuses.length; ++ii) {
            _teamLiveStatuses[ii] = false;
        }

        for each (playerInfo in GameContext.playerInfos) {
            // for the purposes of game-over detection, discount invincible players from the
            // live player count. this is kind of ugly - the last level is the only level
            // in which there's an invincible player (Professor Weardd).
            if (!playerInfo.leftGame && playerInfo.isAlive && !playerInfo.isInvincible) {
                _teamLiveStatuses[playerInfo.teamId] = true;
            }
        }
    }

    protected function checkForGameOver () :void
    {
        // The game is over if there's only one team standing
        var liveTeamId :int = -1;
        _gameOver = true;
        for (var teamId :int = 0; teamId < _teamLiveStatuses.length; ++teamId) {
            if (Boolean(_teamLiveStatuses[teamId])) {
                if (liveTeamId == -1) {
                    liveTeamId = teamId;
                } else {
                    // there's more than one live team
                    _gameOver = false;
                    break;
                }
            }
        }

        if (_gameOver) {
            GameContext.playerStats.totalGameTime = _gameTime;
            GameContext.winningTeamId = liveTeamId;
        }
    }

    protected function handleGameOver () :void
    {
        throw new Error("abstract");
    }

    protected function handleMessage (msg :Message) :void
    {
        var playerIndex :int;
        var playerInfo :PlayerInfo;

        if (msg is CreateUnitMessage) {
            var createUnitMsg :CreateUnitMessage = (msg as CreateUnitMessage);
            playerIndex = createUnitMsg.playerIndex;
            if (PlayerInfo(GameContext.playerInfos[playerIndex]).isAlive) {
                GameContext.unitFactory.createCreature(createUnitMsg.unitType, playerIndex);
                var baseView :WorkshopView = WorkshopView.getForPlayer(playerIndex);
                if (null != baseView) {
                    baseView.unitCreated();
                }
            }

        } else if (msg is SelectTargetEnemyMessage) {
            var selectTargetEnemyMsg :SelectTargetEnemyMessage = msg as SelectTargetEnemyMessage;
            playerIndex = selectTargetEnemyMsg.playerIndex;
            if (PlayerInfo(GameContext.playerInfos[playerIndex]).isAlive) {
                this.setTargetEnemy(playerIndex, selectTargetEnemyMsg.targetPlayerIndex);
            }

        } else if (msg is CastCreatureSpellMessage) {
            var castSpellMsg :CastCreatureSpellMessage = msg as CastCreatureSpellMessage;
            playerIndex = castSpellMsg.playerIndex;
            if (PlayerInfo(GameContext.playerInfos[playerIndex]).isAlive) {
                var spellSet :CreatureSpellSet = GameContext.getActiveSpellSet(playerIndex);
                var spell :CreatureSpellData = GameContext.gameData.spells[castSpellMsg.spellType];
                spellSet.addSpell(spell.clone() as CreatureSpellData);
                GameContext.playGameSound("sfx_" + spell.name);
            }

        } else if (msg is ResurrectPlayerMessage) {
            var resurrectMsg :ResurrectPlayerMessage = msg as ResurrectPlayerMessage;
            this.resurrectPlayer(resurrectMsg.playerIndex);
        }
    }

    protected function resurrectPlayer (deadPlayerIndex :int) :int
    {
        var playerInfo :PlayerInfo = GameContext.playerInfos[deadPlayerIndex];
        if (!playerInfo.isAlive) {
            var teammate :PlayerInfo = GameContext.findPlayerTeammate(deadPlayerIndex);
            if (teammate != null && teammate.isAlive) {
                var newHealth :Number = teammate.health * 0.5;
                teammate.workshop.health = newHealth;
                playerInfo.resurrect(newHealth);
                return teammate.playerIndex;
            }
        }

        return -1;
    }

    protected function setTargetEnemy (playerIndex :int, targetEnemyId :int) :void
    {
        var playerInfo :PlayerInfo = GameContext.playerInfos[playerIndex];
        var enemyInfo :PlayerInfo = GameContext.playerInfos[targetEnemyId];

        playerInfo.targetedEnemy = enemyInfo;

        if (playerIndex == GameContext.localPlayerIndex) {
            this.updateTargetEnemyBadgeLocation(targetEnemyId);
        }
    }

    protected function updateTargetEnemyBadgeLocation (targetEnemyId :int) :void
    {
        // move the "target enemy" badge to the correct base
        var baseViews :Array = WorkshopView.getAll();
        for each (var baseView :WorkshopView in baseViews) {
            baseView.targetEnemyBadgeVisible =
                (baseView.workshop.owningPlayerIndex == targetEnemyId);
        }
    }

    public function workshopClicked (workshopView :WorkshopView) :void
    {
        // when the player clicks on an enemy base, that enemy becomes the player's target
        var localPlayerInfo :PlayerInfo = GameContext.localPlayerInfo;
        var targetInfo :PlayerInfo = workshopView.workshop.owningPlayerInfo;
        var targetId :int = targetInfo.playerIndex;

        if (localPlayerInfo.teamId != targetInfo.teamId &&
            localPlayerInfo.targetedEnemy.playerIndex != targetId) {
            // update the "target enemy badge" location immediately, even though
            // the change won't be reflected in the game logic until the message round-trips
            this.updateTargetEnemyBadgeLocation(targetId);

            // send a message to everyone
            this.sendTargetEnemyMsg(GameContext.localPlayerIndex, targetId, false);
        }
    }

    public function creatureKilled (creature :CreatureUnit, killingPlayerIndex :int) :void
    {
        if (killingPlayerIndex == GameContext.localPlayerIndex) {
            GameContext.playerStats.creaturesKilled[creature.unitType] += 1;

            if (!AppContext.hasTrophy(Trophies.WHATAMESS) &&
                (AppContext.globalPlayerStats.totalCreaturesKilled + GameContext.playerStats.totalCreaturesKilled) >= Trophies.WHATAMESS_NUMCREATURES) {
                // awarded for killing 2500 creatures total
                AppContext.awardTrophy(Trophies.WHATAMESS);
            }
        }
    }

    public function workshopKilled (workshop :WorkshopUnit, killingPlayerIndex :int) :void
    {
        // no-op
    }

    public function spellDeliveredToPlayer (playerIndex :int, spellType :int) :void
    {
        // called when a courier delivers a spell back to its workshop
        if (spellType < Constants.CASTABLE_SPELL_TYPE__LIMIT) {
            PlayerInfo(GameContext.playerInfos[playerIndex]).addSpell(spellType);
        }
    }

    public function localPlayerPurchasedCreature (unitType :int) :void
    {
        if (!this.isAvailableUnit(unitType) ||
            !GameContext.localPlayerInfo.canAffordCreature(unitType)) {
            return;
        }

        this.sendBuildCreatureMsg(GameContext.localPlayerIndex, unitType, false, false);

        // when the sun is eclipsed, it's buy-one-get-one-free time!
        if (GameContext.diurnalCycle.isEclipse) {
            this.sendBuildCreatureMsg(GameContext.localPlayerIndex, unitType, true, false);
        }
    }

    public function sendBuildCreatureMsg (playerIndex :int, unitType :int, noCost :Boolean,
        isAiMsg :Boolean) :void
    {
        var playerInfo :PlayerInfo = GameContext.playerInfos[playerIndex];

        if (!playerInfo.isAlive || GameContext.diurnalCycle.isDay ||
            (!noCost && !playerInfo.canAffordCreature(unitType))) {
            return;
        }

        if (!noCost) {
            playerInfo.deductCreatureCost(unitType);
        }

        this.sendMessage(CreateUnitMessage.create(playerIndex, unitType), isAiMsg);

        if (playerIndex == GameContext.localPlayerIndex) {
            GameContext.playerStats.creaturesCreated[unitType] += 1;
        }
    }

    public function sendCastSpellMsg (playerIndex :int, spellType :int, isAiMsg :Boolean) :void
    {
        var playerInfo :PlayerInfo = GameContext.playerInfos[playerIndex];
        var isCreatureSpell :Boolean = (spellType < Constants.CREATURE_SPELL_TYPE__LIMIT);

        if (!playerInfo.isAlive || (isCreatureSpell && GameContext.diurnalCycle.isDay) ||
            !playerInfo.canCastSpell(spellType)) {
            return;
        }

        playerInfo.spellCast(spellType);

        if (isCreatureSpell) {
            this.sendMessage(CastCreatureSpellMessage.create(playerIndex, spellType), isAiMsg);

        } else if (spellType == Constants.SPELL_TYPE_PUZZLERESET) {
            // there's only one non-creature spell
            GameContext.dashboard.puzzleShuffle();
        }

        GameContext.playerStats.spellsCast[spellType] += 1;
    }

    public function sendTargetEnemyMsg (playerIndex :int, enemyId :int, isAiMsg :Boolean) :void
    {
        this.sendMessage(SelectTargetEnemyMessage.create(playerIndex, enemyId), isAiMsg);
    }

    public function sendResurrectPlayerMsg () :void
    {
        this.sendMessage(ResurrectPlayerMessage.create(GameContext.localPlayerIndex), false);
    }

    protected function sendMessage (msg :Message, isAiMsg :Boolean) :void
    {
        if (isAiMsg) {
            _aiPlayerMessages.push(msg);
        } else {
            _messageMgr.sendMessage(msg);
        }
    }

    public function playerEarnedResources (resourceType :int, offset :int, numClearPieces :int) :int
    {
        return GameContext.localPlayerInfo.earnedResources(resourceType, offset, numClearPieces);
    }

    public function get playAudio () :Boolean
    {
        return true;
    }

    public function get canPause () :Boolean
    {
        return false;
    }

    public function isAvailableUnit (unitType :int) :Boolean
    {
        return true;
    }

    public function get isGameOver () :Boolean
    {
        return _gameOver;
    }

    public function get availableSpells () :Array
    {
        return Constants.CASTABLE_SPELLS;
    }

    public function get battlefieldWidth () :Number
    {
        return (BATTLE_WIDTH * mapSettings.mapScaleX);
    }

    public function get battlefieldHeight () :Number
    {
        return (BATTLE_HEIGHT * mapSettings.mapScaleY);
    }

    public function get mapSettings () :MapSettingsData
    {
        throw new Error("abstract");
    }

    protected function createRandSeed () :uint
    {
        throw new Error("abstract");
    }

    protected function rngSeeded () :void
    {
        // no-op - subclasses can override to do any early setup that requires the RNG to
        // be set up
    }

    protected function createPlayers () :void
    {
        throw new Error("abstract");
    }

    protected function createMessageManager () :TickedMessageManager
    {
        throw new Error("abstract");
    }

    protected var _gameIsRunning :Boolean;

    protected var _messageMgr :TickedMessageManager;
    protected var _aiPlayerMessages :Array = [];
    protected var _debugDataView :DebugDataView;
    protected var _musicChannel :AudioChannel;
    protected var _lastDayPhase :int = -1;
    protected var _startedMusic :Boolean;
    protected var _gameOver :Boolean;
    protected var _handlingGameOver :Boolean;

    protected var _gameTickCount :int;
    protected var _gameTime :Number;
    protected var _updateCount :int;

    protected var _teamLiveStatuses :Array;

    protected var _trophyWatcher :TrophyWatcher;

    protected static const TICK_INTERVAL_MS :int = 100; // 1/10 of a second
    protected static const TICK_INTERVAL_S :Number = (Number(TICK_INTERVAL_MS) / Number(1000));

    protected static const CHECKSUM_BUFFER_LENGTH :int = 10;

    protected static const DASHBOARD_LOC :Point = new Point(350, 430);
    protected static const PUZZLE_BOARD_LOC :Point = new Point(-131, -63);
    protected static const DIURNAL_METER_LOC :Point = new Point(0, 0);

    protected static const BATTLE_WIDTH :int = 700;
    protected static const BATTLE_HEIGHT :int = 372;

    protected static const PUZZLE_HEIGHT :int = 110;
    protected static const PUZZLE_COLS :int = 12;
    protected static const PUZZLE_ROWS :int = 5;
    protected static const PUZZLE_TILE_SIZE :int = int(PUZZLE_HEIGHT / PUZZLE_ROWS) + 1;

    protected static const log :Log = Log.getLog(GameMode);
}

}
