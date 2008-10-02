package popcraft.sp.story {

import com.threerings.util.KeyboardCodes;
import com.whirled.contrib.simplegame.AppMode;
import com.whirled.contrib.simplegame.net.OfflineTickedMessageManager;
import com.whirled.contrib.simplegame.net.TickedMessageManager;

import popcraft.*;
import popcraft.battle.*;
import popcraft.data.*;
import popcraft.sp.*;

public class StoryGameMode extends GameMode
{
    public function StoryGameMode (level :LevelData)
    {
        _level = level;
    }

    override protected function setup () :void
    {
        super.setup();
        showIntro();
    }

    protected function showIntro () :void
    {
        AppContext.mainLoop.pushMode(new LevelIntroMode(_level));
    }

    override public function onKeyDown (keyCode :uint) :void
    {
        if (Constants.DEBUG_ALLOW_CHEATS && keyCode == KeyboardCodes.SLASH) {
            // restart the level
            // playLevel(true) forces the current level to reload
            AppContext.levelMgr.playLevel(null, true);

        } else {
            super.onKeyDown(keyCode);
        }
    }

    override public function playerEarnedResources (resourceType :int, offset :int,
        numClearPieces :int) :int
    {
        var actualResourcesEarned :int =
            super.playerEarnedResources(resourceType, offset, numClearPieces);

        // only resources earned while under "par" are counted toward the totalResourcesEarned count
        // for the purposes of player score
        if (GameContext.isStoryGame &&
            GameContext.diurnalCycle.dayCount <= _level.expertCompletionDays) {
            _totalResourcesEarned += actualResourcesEarned;
        }

        return actualResourcesEarned;
    }

    override public function get canPause () :Boolean
    {
        return true;
    }

    override public function isAvailableUnit (unitType :int) :Boolean
    {
        return _level.isAvailableUnit(unitType);
    }

    override public function get availableSpells () :Array
    {
        return _level.availableSpells;
    }

    override public function get mapSettings () :MapSettingsData
    {
        return _level.mapSettings;
    }

    override protected function createPlayers () :void
    {
        GameContext.localPlayerIndex = 0;
        GameContext.playerInfos = [];

        var level :LevelData = _level;

        var baseLocs :Array = GameContext.gameMode.mapSettings.baseLocs.slice();

        // Create the local player (always playerIndex=0, team=0)
        var localPlayerInfo :LocalPlayerInfo = new LocalPlayerInfo(
            0, 0,
            MapSettingsData.getNextBaseLocForTeam(baseLocs, 0),
            level.playerBaseHealth, level.playerBaseStartHealth, false,
            1, level.playerName, level.playerHeadshot);

        // grant the player some starting resources
        var initialResources :Array = level.initialResources;
        for (var resType :int = 0; resType < initialResources.length; ++resType) {
            localPlayerInfo.setResourceAmount(resType, int(initialResources[resType]));
        }

        // ...and some starting spells
        var initialSpells :Array = level.initialSpells;
        for (var spellType :int = 0; spellType < initialSpells.length; ++spellType) {
            localPlayerInfo.addSpell(spellType, int(initialSpells[spellType]));
        }

        GameContext.playerInfos.push(localPlayerInfo);

        // create computer players
        var numComputers :int = level.computers.length;
        for (var playerIndex :int = 1; playerIndex < numComputers + 1; ++playerIndex) {
            var cpData :ComputerPlayerData = level.computers[playerIndex - 1];
            var team :int = cpData.team;
            var baseLoc :BaseLocationData = MapSettingsData.getNextBaseLocForTeam(baseLocs, team);
            var computerPlayerInfo :ComputerPlayerInfo = new ComputerPlayerInfo(
                playerIndex, team, baseLoc, cpData.baseHealth, cpData.baseStartHealth,
                cpData.invincible, cpData.playerName, cpData.playerHeadshot);
            GameContext.playerInfos.push(computerPlayerInfo);

            // create the computer player object
            GameContext.netObjects.addObject(new ComputerPlayer(cpData, playerIndex));
        }
    }

    override protected function createRandSeed () :uint
    {
        return uint(Math.random() * uint.MAX_VALUE);
    }

    override protected function createMessageManager () :TickedMessageManager
    {
        return new OfflineTickedMessageManager(AppContext.gameCtrl, TICK_INTERVAL_MS);
    }

    override protected function handleGameOver () :void
    {
        // show the appropriate outro screen
        var nextMode :AppMode;
        var levelPackResources :Array = [];
        if (AppContext.levelMgr.isLastLevel &&
            GameContext.winningTeamId == GameContext.localPlayerInfo.teamId) {

            nextMode = new EpilogueMode(EpilogueMode.TRANSITION_LEVELOUTRO, _level);
            levelPackResources = Resources.EPILOGUE_RESOURCES;

        } else {
            nextMode = new LevelOutroMode(_level);
        }

        fadeOut(function () :void {
            Resources.loadLevelPackResourcesAndSwitchModes(levelPackResources, nextMode);
        }, FADE_OUT_TIME);

        GameContext.musicControls.fadeOut(FADE_OUT_TIME - 0.25);
        GameContext.sfxControls.fadeOut(FADE_OUT_TIME - 0.25);
    }

    public function get totalResourcesEarned () :int
    {
        return _totalResourcesEarned;
    }

    protected var _level :LevelData;
    protected var _totalResourcesEarned :int;
}

}
