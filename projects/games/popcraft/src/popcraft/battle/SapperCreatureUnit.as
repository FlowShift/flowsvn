package popcraft.battle {
    
import com.whirled.contrib.core.*;

import popcraft.*;
import popcraft.battle.ai.*;

/**
 * Sappers are suicide-bombers. They deal heavy
 * damage to enemies and bases.
 */
public class SapperCreatureUnit extends CreatureUnit
{
    public function SapperCreatureUnit (owningPlayerId :uint)
    {
        super(Constants.UNIT_TYPE_SAPPER, owningPlayerId);
        
        _sapperAI = new SapperAI(this, this.findEnemyBaseToAttack());
    }

    override protected function get aiRoot () :AITask
    {
        return _sapperAI;
    }
    
    protected var _sapperAI :SapperAI;
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
 */
class SapperAI extends AITaskTree
{
    public function SapperAI (unit :SapperCreatureUnit, targetBaseRef :SimObjectRef)
    {
        _unit = unit;
        _targetBaseRef = targetBaseRef;

        this.beginAttackBase();
    }

    protected function beginAttackBase () :void
    {
        this.clearSubtasks();
        this.addSubtask(new AttackUnitTask(_targetBaseRef, true, -1));
    }
    
    override protected function childTaskCompleted (task :AITask) :void
    {
    }

    override public function get name () :String
    {
        return "SapperAI";
    }

    protected var _unit :SapperCreatureUnit;
    protected var _targetBaseRef :SimObjectRef;
}
