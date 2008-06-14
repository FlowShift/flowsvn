package popcraft.sp {

import com.whirled.contrib.simplegame.*;
import com.whirled.contrib.simplegame.tasks.*;
import com.whirled.contrib.simplegame.util.Rand;

import popcraft.*;
import popcraft.battle.*;
import popcraft.data.*;

public class ComputerPlayer extends SimObject
{
    public function ComputerPlayer (data :ComputerPlayerData, playerId :uint)
    {
        _data = data;
        _playerInfo = GameContext.playerInfos[playerId] as ComputerPlayerInfo;

        // add starting spells to our playerInfo
        _playerInfo.setSpellCounts(data.startingCreatureSpells);

        // Computer players always target the local player
        _playerInfo.targetedEnemyId = GameContext.localPlayerId;
    }

    protected function getDayData (dayIndex :int) :DaySequenceData
    {
        if (dayIndex < _data.initialDays.length) {
            return _data.initialDays[dayIndex];
        } else if (_data.repeatingDays.length > 0) {
            var index :int = (dayIndex - _data.initialDays.length) % _data.repeatingDays.length;
            return _data.repeatingDays[index];
        } else {
            return null;
        }
    }

    protected function queueNextWave () :void
    {
        if (null == _curDay) {
            return;
        }

        if (_waveIndex < _curDay.unitWaves.length || _curDay.repeatWaves) {
            _nextWave = _curDay.unitWaves[_waveIndex % _curDay.unitWaves.length];
        } else {
            return;
        }

        ++_waveIndex;

        this.addNamedTask(SEND_WAVE_TASK, After(_nextWave.delayBefore, new FunctionTask(sendNextWave)));
    }

    protected function sendNextWave () :void
    {
        if (_playerInfo.isAlive && GameContext.diurnalCycle.isNight) {

            // before each wave goes out, there's a chance that the computer
            // player will cast a spell (if it has one available)
            if (Rand.nextNumberRange(0, 1, Rand.STREAM_GAME) < _nextWave.spellCastChance) {
                var availableSpells :Array = [];
                for (var spellType :uint = 0; spellType < Constants.SPELL_NAMES.length; ++spellType) {
                    if (_playerInfo.canCastSpell(spellType)) {
                        availableSpells.push(spellType);
                    }
                }

                if (availableSpells.length > 0) {
                    spellType = availableSpells[Rand.nextIntRange(0, availableSpells.length, Rand.STREAM_GAME)];
                    GameContext.gameMode.castSpell(_playerInfo.playerId, spellType);
                }
            }

            // should we switch our targeted enemy?
            if (null != _nextWave.targetPlayerName) {
                var targetPlayer :PlayerInfo = GameContext.getPlayerByName(_nextWave.targetPlayerName);
                if (null != targetPlayer) {
                    GameContext.gameMode.selectTargetEnemy(_playerInfo.playerId, targetPlayer.playerId);
                }
            }

            // create the units
            var units :Array = _nextWave.units;
            for (var i :int = 0; i < units.length; i += 3) {
                var unitType :uint = units[i];
                var count :int = units[i + 1];
                var max :int = units[i + 2];

                // is there a cap on how many creatures we should create in this wave?
                if (max >= 0) {
                    count = Math.min(count, max - CreatureUnit.getNumPlayerCreatures(_playerInfo.playerId, unitType));
                }

                for (var j :int = 0; j < count; ++j) {
                    this.buildUnit(unitType);
                }
            }

            this.queueNextWave();
        }
    }

    protected function buildUnit (unitType :uint) :void
    {
        GameContext.gameMode.buildUnit(_playerInfo.playerId, unitType);
    }

    override protected function update (dt :Number) :void
    {
        if (!_playerInfo.isAlive) {
            this.destroySelf();
            return;
        }

        // which day is it?
        var diurnalCycle :DiurnalCycle = GameContext.diurnalCycle;
        var dayIndex :int = (diurnalCycle.dayCount - 1);
        if (dayIndex != _lastDayIndex) {
            _curDay = this.getDayData(dayIndex);
            _waveIndex = 0;
            _nextWave = null;
            this.removeNamedTasks(SEND_WAVE_TASK);
            this.removeNamedTasks(SPELL_DROP_SPOTTED_TASK);

            _lastDayIndex = dayIndex;
        }

        if (null == _curDay) {
            return;
        }

        if (GameContext.diurnalCycle.isNight) {
            // send out creatures and look for spell drops at night

            if (_nextWave == null) {
                this.queueNextWave();
            }

            if (_curDay.lookForSpellDrops && !this.spellDropSpotted && this.spellDropOnBoard) {
                this.addNamedTask(
                    SPELL_DROP_SPOTTED_TASK,
                    After(_curDay.noticeSpellDropAfter.next(),
                        new FunctionTask(sendCouriersForSpellDrop)));
            }
        }
    }

    protected function sendCouriersForSpellDrop () :void
    {
        if (_playerInfo.isAlive && GameContext.diurnalCycle.isNight) {
            var numCouriers :int = _curDay.spellDropCourierGroupSize.next() - this.numCouriersOnBoard;
            for (var i :int = 0; i < numCouriers; ++i) {
                this.buildUnit(Constants.UNIT_TYPE_COURIER);
            }
        }
    }

    protected function get spellDropSpotted () :Boolean
    {
        return this.hasTasksNamed(SPELL_DROP_SPOTTED_TASK);
    }

    protected function get spellDropOnBoard () :Boolean
    {
        return GameContext.netObjects.getObjectRefsInGroup(SpellDropObject.GROUP_NAME).length > 0;
    }

    protected function get numCouriersOnBoard () :int
    {
        return CourierCreatureUnit.getNumPlayerCouriersOnBoard(_playerInfo.playerId);
    }

    protected var _data :ComputerPlayerData;
    protected var _playerInfo :ComputerPlayerInfo;
    protected var _curDay :DaySequenceData;
    protected var _nextWave :UnitWaveData;
    protected var _waveIndex :int;
    protected var _lastDayIndex :int = -1;

    protected static const SEND_WAVE_TASK :String = "SendWave";
    protected static const SPELL_DROP_SPOTTED_TASK :String = "SpellDropSpotted";
}

}
