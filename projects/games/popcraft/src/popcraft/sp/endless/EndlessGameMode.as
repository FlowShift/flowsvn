package popcraft.sp.endless {

import com.threerings.flash.Vector2;
import com.threerings.util.ArrayUtil;
import com.threerings.util.KeyboardCodes;
import com.whirled.contrib.simplegame.*;
import com.whirled.contrib.simplegame.net.*;
import com.whirled.contrib.simplegame.objects.SimpleTimer;
import com.whirled.contrib.simplegame.util.Rand;
import com.whirled.game.StateChangedEvent;

import popcraft.*;
import popcraft.battle.*;
import popcraft.data.*;
import popcraft.mp.*;
import popcraft.sp.*;

public class EndlessGameMode extends GameMode
{
    public static const HUMAN_TEAM_ID :int = 0;
    public static const FIRST_COMPUTER_TEAM_ID :int = 1;

    public function EndlessGameMode (level :EndlessLevelData, save :SavedEndlessGame,
        isNewGame :Boolean)
    {
        EndlessGameContext.level = level;
        _savedGame = save;
        _needsReset = isNewGame;
    }

    override protected function setup () :void
    {
        if (_needsReset) {
            EndlessGameContext.reset();
        }

        EndlessGameContext.gameMode = this;

        if (_savedGame != null) {
            // restore saved data if it exists
            EndlessGameContext.mapIndex = _savedGame.mapIndex;
            EndlessGameContext.score = _savedGame.score;
            EndlessGameContext.scoreMultiplier = _savedGame.multiplier;

        } else {
            // otherwise, move to the next map
            EndlessGameContext.mapIndex++;
        }

        _curMapData = EndlessGameContext.level.getMapData(EndlessGameContext.mapIndex);

        super.setup();

        var scoreView :ScoreView = new ScoreView();
        scoreView.x = (Constants.SCREEN_SIZE.x - scoreView.width) * 0.5;
        scoreView.y = 5;
        this.addObject(scoreView, GameContext.overlayLayer);

        // create the multipliers that were left over from the last map
        for (var ii :int = 0; ii < EndlessGameContext.numMultiplierObjects; ++ii) {
            this.createMultiplierDrop(false);
        }

        if (!AppContext.gameCtrl.isConnected()) {
            // if we're in standalone mode, start the game immediately
            this.startGame();
        } else if (GameContext.isSinglePlayerGame) {
            // if this is a singleplayer game, start the game immediately,
            // and tell the server we're playing the game so that coins can be awarded
            this.startGame();
            if (EndlessGameContext.isNewGame) {
                AppContext.gameCtrl.game.playerReady();
            }

        } else if (EndlessGameContext.isNewGame) {
            // if this is a new multiplayer game, start the game when the GAME_STARTED event
            // is received
            this.registerEventListener(AppContext.gameCtrl.game, StateChangedEvent.GAME_STARTED,
                function (...ignored) :void {
                    startGame();
                });

            // we're ready!
            AppContext.gameCtrl.game.playerReady();

        } else {
            // If we've moved to the next map in an existing multiplayer game, start the game
            // when all the players have arrived. Use the PlayerReadyMonitor for this purpose -
            // this is functionally the same thing as waiting for the GAME_STARTED event, as above,
            // but doesn't require us to end the current game
            EndlessGameContext.playerReadyMonitor.waitForAllPlayersReadyForCurRound(startGame);

            // we're ready
            EndlessGameContext.playerReadyMonitor.setLocalPlayerReadyForCurRound();
        }
    }

    override protected function updateNetworkedObjects () :void
    {
        super.updateNetworkedObjects();

        // sync the local player's workshop damage shield count to their score multiplier
        var localPlayerWorkshop :WorkshopUnit = GameContext.localPlayerInfo.workshop;
        var multiplier :int =
            (localPlayerWorkshop != null ? localPlayerWorkshop.damageShields.length + 1 : 1);
        EndlessGameContext.scoreMultiplier = multiplier;

        this.checkForComputerDeath();
    }

    override protected function checkForGameOver () :void
    {
        if (!Boolean(_teamLiveStatuses[HUMAN_TEAM_ID])) {
            _gameOver = true;
        }
    }

    protected function checkForComputerDeath () :void
    {
        if (!_gameOver && !_swappingInNextOpponents) {
            var computersAreDead :Boolean = true;
            for (var teamId :int = FIRST_COMPUTER_TEAM_ID; teamId < _teamLiveStatuses.length;
                ++teamId) {
                if (Boolean(_teamLiveStatuses[teamId])) {
                    computersAreDead = false;
                    break;
                }
            }

            if (computersAreDead) {
                this.killAllCreatures();
                // kill all creatures, wait a short while, then swap in the next opponents
                GameContext.netObjects.addObject(new SimpleTimer(4, swapInNextOpponents));
                _swappingInNextOpponents = true;
            }
        }
    }

    protected function killAllCreatures () :void
    {
        for each (var creature :CreatureUnit in GameContext.netObjects.getObjectsInGroup(CreatureUnit.GROUP_NAME)) {
            creature.die();
        }
    }

    protected function createMultiplierDrop (playSound :Boolean) :void
    {
        var scatterLen :Number = Rand.nextNumberRange(0, _curMapData.multiplierScatterRadius,
            Rand.STREAM_GAME);
        var rotation :Number = Rand.nextNumberRange(0, Math.PI * 2, Rand.STREAM_GAME);
        var loc :Vector2 = Vector2.fromAngle(rotation, scatterLen).addLocal(
            _curMapData.multiplierDropLoc);

        SpellDropFactory.createSpellDrop(Constants.SPELL_TYPE_MULTIPLIER, loc, playSound);
    }

    protected function multiplierIsOnPlayfield () :Boolean
    {
        var spellDrops :Array = GameContext.netObjects.getObjectsInGroup(SpellDropObject.GROUP_NAME);
        for each (var spellDrop :SpellDropObject in spellDrops) {
            if (spellDrop.spellType == Constants.SPELL_TYPE_MULTIPLIER) {
                return true;
            }
        }

        return false;
    }

    protected function swapInNextOpponents () :void
    {
        this.createMultiplierDrop(true);

        if (_computerGroupIndex < _curMapData.computerGroups.length - 1) {
            // there are more opponents left on this map. swap the next ones in.

            var playerInfo :PlayerInfo;
            for (;;) {
                var playerIndex :int =  GameContext.playerInfos.length - 1;
                playerInfo = GameContext.playerInfos[playerIndex];
                if (playerInfo.teamId == HUMAN_TEAM_ID) {
                    break;
                }

                GameContext.playerInfos.pop();
                playerInfo.destroy();
            }

            ++_computerGroupIndex;
            // createComputerPlayers() populates GameContext.playerInfos
            var newPlayerInfos :Array = this.createComputerPlayers();
            for each (playerInfo in newPlayerInfos) {
                playerInfo.init();
            }

            // switch immediately to daytime
            if (!GameContext.diurnalCycle.isDay) {
                GameContext.diurnalCycle.resetPhase(Constants.PHASE_DAY);
            }

            GameContext.dashboard.updatePlayerStatusViews();

        } else {
            this.switchMaps();
        }

        _swappingInNextOpponents = false;
    }

    protected function switchMaps () :void
    {
        // save data about our human players so that they can be resurrected
        // when the next round starts
        EndlessGameContext.savedHumanPlayers = [];
        for each (var playerInfo :PlayerInfo in GameContext.playerInfos) {
            if (playerInfo.teamId == HUMAN_TEAM_ID) {
                EndlessGameContext.savedHumanPlayers.push(playerInfo.saveData());
            }
        }

        // save the number of multipliers left on the field so the player has a chance
        // to grab them on the next map
        var numMultipliers :int;
        var netObjs :ObjectDB = GameContext.netObjects;
        for each (var spellDrop :SpellDropObject in netObjs.getObjectsInGroup(SpellDropObject.GROUP_NAME)) {
            if (spellDrop.spellType == Constants.SPELL_TYPE_MULTIPLIER) {
                numMultipliers += 1;
            }
        }

        for each (var carriedSpell :CarriedSpellObject in netObjs.getObjectsInGroup(CarriedSpellObject.GROUP_NAME)) {
            if (carriedSpell.spellType == Constants.SPELL_TYPE_MULTIPLIER) {
                numMultipliers += 1;
            }
        }

        EndlessGameContext.numMultiplierObjects = numMultipliers;

        // save the game (must be done after the human players are saved, above)
        AppContext.endlessLevelMgr.saveCurrentGame();

        // move to the next map (see handleGameOver())
        _gameOver = true;
        _switchingMaps = true;
    }

    override protected function handleGameOver () :void
    {
        if (_switchingMaps) {
            // if we're switching maps, don't show the game-over screen, just switch to a new
            // endless game mode
            this.fadeOutToMode(new EndlessGameMode(EndlessGameContext.level, null, false));

        } else {
            this.fadeOutToMode(new EndlessLevelSpOutroMode(), FADE_OUT_TIME);
            GameContext.musicControls.fadeOut(FADE_OUT_TIME - 0.25);
            GameContext.sfxControls.fadeOut(FADE_OUT_TIME - 0.25);
        }
    }

    override protected function applyCheatCode (keyCode :uint) :void
    {
        switch (keyCode) {
        case KeyboardCodes.M:
            this.spellDeliveredToPlayer(GameContext.localPlayerIndex,
                Constants.SPELL_TYPE_MULTIPLIER);
            break;

        case KeyboardCodes.SLASH:
            if (GameContext.isSinglePlayerGame) {
                AppContext.endlessLevelMgr.playSpLevel(null, true);
            }
            break;

        case KeyboardCodes.O:
            this.swapInNextOpponents();
            break;

        default:
            super.applyCheatCode(keyCode);
            break;
        }
    }

    override public function playerEarnedResources (resourceType :int, offset :int,
        numClearPieces :int) :int
    {
        var actualResourcesEarned :int =
            super.playerEarnedResources(resourceType, offset, numClearPieces);

        EndlessGameContext.incrementScore(
            actualResourcesEarned * EndlessGameContext.level.pointsPerResource);

        return actualResourcesEarned;
    }

    override public function creatureKilled (creature :CreatureUnit, killingPlayerIndex :int) :void
    {
        super.creatureKilled(creature, killingPlayerIndex);

        if (killingPlayerIndex == GameContext.localPlayerIndex) {
            EndlessGameContext.incrementScore(
                EndlessGameContext.level.pointsPerCreatureKill[creature.unitType]);
        }
    }

    override public function spellDeliveredToPlayer (playerIndex :int, spellType :int) :void
    {
        super.spellDeliveredToPlayer(playerIndex, spellType);

        // multiplier spells increase the player's score multiplier, and also add little damage
        // shields to his workshop
        if (spellType == Constants.SPELL_TYPE_MULTIPLIER) {
            var workshop :WorkshopUnit = PlayerInfo(GameContext.playerInfos[playerIndex]).workshop;
            if (workshop != null &&
                workshop.damageShields.length < EndlessGameContext.level.maxMultiplier) {

                workshop.addDamageShield(EndlessGameContext.level.multiplierDamageSoak);
            }

            if (playerIndex == GameContext.localPlayerIndex) {
                EndlessGameContext.incrementMultiplier();
            }
        }
    }

    override public function get canPause () :Boolean
    {
        return GameContext.isSinglePlayerGame;
    }

    override public function isAvailableUnit (unitType :int) :Boolean
    {
        return ArrayUtil.contains(_curMapData.availableUnits, unitType);
    }

    override public function get availableSpells () :Array
    {
        return _curMapData.availableSpells;
    }

    override public function get mapSettings () :MapSettingsData
    {
        return _curMapData.mapSettings;
    }

    override protected function createPlayers () :void
    {
        GameContext.localPlayerIndex = SeatingManager.localPlayerSeat;
        GameContext.playerInfos = [];

        var workshopData :UnitData = GameContext.gameData.units[Constants.UNIT_TYPE_WORKSHOP];
        var workshopHealth :Number = workshopData.maxHealth;

        // create PlayerInfos for the human players
        var numPlayers :int = SeatingManager.numExpectedPlayers;
        for (var playerIndex :int = 0; playerIndex < numPlayers; ++playerIndex) {

            var playerDisplayData :PlayerDisplayData = GameContext.gameData.getPlayerDisplayData(
                    EndlessGameContext.level.humanPlayerNames[playerIndex]);

            var baseLoc :BaseLocationData =
                _curMapData.humanBaseLocs.get(playerDisplayData.dataName);

            if (playerIndex == GameContext.localPlayerIndex) {
                GameContext.playerInfos.push(new LocalPlayerInfo(
                    playerIndex,
                    HUMAN_TEAM_ID,
                    baseLoc,
                    workshopHealth,
                    workshopHealth,
                    false,
                    1,
                    playerDisplayData.color,
                    playerDisplayData.displayName,
                    playerDisplayData.headshot));

            } else {
                GameContext.playerInfos.push(new PlayerInfo(
                    playerIndex,
                    HUMAN_TEAM_ID,
                    baseLoc,
                    workshopHealth,
                    workshopHealth,
                    false,
                    1,
                    playerDisplayData.color,
                    playerDisplayData.displayName,
                    playerDisplayData.headshot));
            }
        }

        this.createComputerPlayers();

        // init all players players
        for each (var playerInfo :PlayerInfo in GameContext.playerInfos) {
            playerInfo.init();
        }

        // restore data that was saved from the previous map (must be done after playerInfos
        // are init()'d)
        for (playerIndex = 0; playerIndex < EndlessGameContext.savedHumanPlayers.length;
            ++playerIndex) {

            var savedPlayer :SavedPlayerInfo = EndlessGameContext.savedHumanPlayers[playerIndex];
            var player :PlayerInfo = GameContext.playerInfos[playerIndex];
            player.restoreSavedPlayerInfo(savedPlayer);
        }

        // restore data from the saved game, if it exists
        if (_savedGame != null) {
            GameContext.localPlayerInfo.restoreSavedGameData(
                _savedGame, EndlessGameContext.level.multiplierDamageSoak);
        }
    }

    protected function createComputerPlayers () :Array
    {
        var mapCycleNumber :int = EndlessGameContext.mapCycleNumber;

        // the first computer index is 1 more than the number of human players in the game
        var playerIndex :int = SeatingManager.numExpectedPlayers;

        var computerGroup :Array = _curMapData.computerGroups[_computerGroupIndex];
        var newInfos :Array  = [];
        for each (var cpData :EndlessComputerPlayerData in computerGroup) {
            var playerInfo :PlayerInfo = new EndlessComputerPlayerInfo(playerIndex, cpData,
                mapCycleNumber);

            GameContext.playerInfos.push(playerInfo);
            newInfos.push(playerInfo);

            ++playerIndex;
        }

        return newInfos;
    }

    override protected function createRandSeed () :uint
    {
        if (GameContext.isSinglePlayerGame) {
            return uint(Math.random() * uint.MAX_VALUE);
        } else {
            return MultiplayerConfig.randSeed;
        }
    }

    override protected function createMessageManager () :TickedMessageManager
    {
        if (GameContext.isSinglePlayerGame) {
            return new OfflineTickedMessageManager(AppContext.gameCtrl, TICK_INTERVAL_MS);
        } else {
            return new OnlineTickedMessageManager(AppContext.gameCtrl,
                SeatingManager.isLocalPlayerInControl, TICK_INTERVAL_MS);
        }
    }

    protected var _curMapData :EndlessMapData;
    protected var _computerGroupIndex :int;
    protected var _needsReset :Boolean;
    protected var _switchingMaps :Boolean;
    protected var _swappingInNextOpponents :Boolean;
    protected var _savedGame :SavedEndlessGame;

    protected var _playersCheckedIn :Array = [];
}

}

import com.whirled.contrib.simplegame.*;

import popcraft.*;
import popcraft.battle.*;

class WaitForMultiplierRetrievalTask
    implements ObjectTask
{
    public function WaitForMultiplierRetrievalTask (maxTime :Number)
    {
        _maxTime = maxTime;
    }

    public function update (dt :Number, obj :SimObject) :Boolean
    {
        _elapsedTime += dt;
        if (_elapsedTime >= _maxTime) {
            return true;
        } else {
            return !this.multipliersExist;
        }
    }

    protected function get multipliersExist () :Boolean
    {
        var netObjs :ObjectDB = GameContext.netObjects;
        for each (var spellDrop :SpellDropObject in netObjs.getObjectsInGroup(SpellDropObject.GROUP_NAME)) {
            if (spellDrop.spellType == Constants.SPELL_TYPE_MULTIPLIER) {
                return true;
            }
        }

        for each (var carriedSpell :CarriedSpellObject in netObjs.getObjectsInGroup(CarriedSpellObject.GROUP_NAME)) {
            if (carriedSpell.spellType == Constants.SPELL_TYPE_MULTIPLIER) {
                return true;
            }
        }

        return false;
    }

    public function clone () :ObjectTask
    {
        return new WaitForMultiplierRetrievalTask(_maxTime);
    }

    public function receiveMessage (msg :ObjectMessage) :Boolean
    {
        return false;
    }

    protected var _maxTime :Number;
    protected var _elapsedTime :Number = 0;
}
