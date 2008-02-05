package popcraft.battle {
    
import com.whirled.contrib.core.*;

import popcraft.*;
import popcraft.battle.ai.*;

/**
 * Grunts are the meat-and-potatoes offensive unit of the game.
 * - Don't chase enemies unless attacked.
 * - non-ranged.
 * - moderate damage to enemy base.
 */
public class GruntCreatureUnit extends CreatureUnit
{
    public function GruntCreatureUnit(owningPlayerId:uint)
    {
        super(Constants.UNIT_TYPE_GRUNT, owningPlayerId);
        _gruntAI = new GruntAI(this);
    }

    override protected function get aiRoot () :AIState
    {
        return _gruntAI;
    }

    public function set escort (heavy :HeavyCreatureUnit) :void
    {
        _escortId = heavy.id;
    }

    public function get escort () :HeavyCreatureUnit
    {
        return GameMode.getNetObject(_escortId) as HeavyCreatureUnit;
    }

    public function get hasEscort () :Boolean
    {
        return (null != this.escort);
    }
    
    override protected function receiveMessage (msg :ObjectMessage) :void
    {
        super.receiveMessage(msg);
        
        if(msg.name == GameMessage.MSG_UNITATTACKED) {
            this.db.sendMessageTo(msg, _escortId);
        }
    }

    protected var _gruntAI :GruntAI;
    protected var _escortId :uint;
}

}

import com.whirled.contrib.core.*;
import com.whirled.contrib.core.util.*;
import flash.geom.Point;

import popcraft.*;
import popcraft.battle.*;
import popcraft.battle.ai.*;

/**
 * Goals:
 * (Priority 1) Attack enemy base
 * (Priority 2) Attack enemy aggressors (responds to attacks, but doesn't initiate fights with other units)
 */
class GruntAI extends AIStateTree
{
    public function GruntAI (unit :GruntCreatureUnit)
    {
        _unit = unit;

        this.beginAttackBase();
    }

    protected function beginAttackBase () :void
    {
        this.clearSubtasks();
        this.addSubtask(new AttackUnitState(_unit.findEnemyBaseToAttack()));
    }

    protected function beginAttackCreature (creatureId :uint) :void
    {
        this.clearSubtasks();

        var taskQueue :AITaskQueue = new AITaskQueue(false);
        taskQueue.addTask(new AttackUnitState(creatureId));
        taskQueue.addTask(new AttackUnitState(_unit.findEnemyBaseToAttack()));

        this.addSubtask(taskQueue);
    }

    override public function receiveMessage (msg :ObjectMessage) :Boolean
    {
        if (this.hasSubtaskNamed(AttackBaseTask.NAME) && msg.name == GameMessage.MSG_UNITATTACKED) {
            this.beginAttackCreature(msg.data);
            return false;
        }

        return super.receiveMessage(msg);
    }

    override public function get name () :String
    {
        return "GruntAI";
    }

    protected var _unit :GruntCreatureUnit;
    protected var _state :uint;
}
