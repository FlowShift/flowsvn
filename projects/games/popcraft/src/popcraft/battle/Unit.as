package popcraft.battle {
    
import com.threerings.flash.Vector2;
import com.threerings.util.Assert;
import com.whirled.contrib.core.*;
import com.whirled.contrib.core.components.*;
import com.whirled.contrib.core.objects.*;
import com.whirled.contrib.core.resource.*;
import com.whirled.contrib.core.tasks.*;
import com.whirled.contrib.core.util.*;

import flash.display.Bitmap;

import popcraft.*;
import popcraft.battle.geom.*;
import popcraft.util.*;

/**
 * If ActionScript allowed the creation of abstract classes or private constructors, I would do that here.
 * Alas, it doesn't. But Unit is not intended to be instantiated directly.
 */
public class Unit extends AppObject
    implements LocationComponent
{
    public static const GROUP_NAME :String = "Unit";

    public function Unit (unitType :uint, owningPlayerId :uint)
    {
        _unitType = unitType;
        _owningPlayerId = owningPlayerId;

        _unitData = (Constants.UNIT_DATA[unitType] as UnitData);
        _health = _unitData.maxHealth;
    }

    override public function get objectGroups () :Array
    {
        // every Unit is in the Unit.GROUP_NAME group
        if (null == g_groups) {
            g_groups = new Array();
            g_groups.push(GROUP_NAME);
        }

        return g_groups;
    }

    protected function createOwningPlayerGlowForBitmap (bitmap :Bitmap) :Bitmap
    {
        return ImageUtil.createGlowBitmap(bitmap, Constants.PLAYER_COLORS[_owningPlayerId] as uint);
    }
    
    public function isUnitInRange (unit :Unit, range :Number) :Boolean
    {
        if (range < 0) {
            return false;
        }
        
        return Collision.circlesIntersect(
            new Vector2(this.x, this.y),
            range,
            new Vector2(unit.x, unit.y),
            unit.unitData.collisionRadius);
    }

    public function get isAttacking () :Boolean
    {
        return this.hasTasksNamed("attackCooldown");
    }

    public function canAttackWithWeapon (targetUnit :Unit, weapon :UnitWeapon) :Boolean
    {
        // we can attack the unit if we're not already attacking, and if the unit
        // is within range of the attack
        return (this.isUnitInRange(targetUnit, weapon.maxAttackDistance));
    }

    public function findNearestAttackLocation (targetUnit :Unit, weapon :UnitWeapon) :Vector2
    {
        // given this unit's current location, find the nearest location
        // that an attack on the given target can be launched from
        var myLoc :Vector2 = this.unitLoc;

        if (this.isUnitInRange(targetUnit, weapon.maxAttackDistance)) {
            return myLoc; // we don't need to move
        } else {
            // create a vector that points from the target to us
            var moveLoc :Vector2 = myLoc.subtract(targetUnit.unitLoc);

            // scale it by the appropriate amount
            moveLoc.length = (targetUnit.unitData.collisionRadius + weapon.maxAttackDistance - 1);

            // add it to the base's location
            moveLoc.addLocal(targetUnit.unitLoc);

            return moveLoc;
        }
    }

    public function sendTargetedAttack (targetUnit :Unit, weapon :UnitWeapon) :void
    {
        if (this.isAttacking || !this.canAttackWithWeapon(targetUnit, weapon)) {
            /*trace(
                "discarding attack from "
                + this.id + " to " + targetUnit.id +
                " (target out of range, or we're already attacking)");*/
                
            return;
        }

        switch(weapon.weaponType) {
            
        case UnitWeapon.TYPE_MELEE:
            this.db.sendMessageTo(new ObjectMessage(GameMessage.MSG_UNITATTACKED, new UnitAttack(targetUnit.id, this.id, weapon)), targetUnit.id);
            break;
            
        case UnitWeapon.TYPE_MISSILE:
            MissileFactory.createMissile(targetUnit, this, weapon);
            break;
            
        default:
            Assert.fail("Unrecognized weaponType: " + weapon.weaponType);
            break;
        }

        // install a cooldown timer
        if (weapon.cooldown > 0) {
            this.addNamedTask("attackCooldown", new TimedTask(weapon.cooldown));
        }
    }
    
    override protected function receiveMessage (msg :ObjectMessage) :void
    {
        if (msg.name == GameMessage.MSG_UNITATTACKED) {
            var attack :UnitAttack = (msg.data as UnitAttack);
            if (attack.targetUnitId == this.id) {
                
                _health -= int(_unitData.armor.getWeaponDamage(attack.weapon));
                _health = Math.max(_health, 0);
                
                this.dispatchEvent(new UnitAttackedEvent(attack));
                
                if (_health == 0) {
                    this.destroySelf();
                }
            }
        }
    }

    public function get owningPlayerId () :uint
    {
        return _owningPlayerId;
    }

    public function get unitType () :uint
    {
        return _unitType;
    }

    public function get health () :uint
    {
        return _health;
    }

    public function get unitData () :UnitData
    {
        return _unitData;
    }

    public function get x () :Number
    {
        return _loc.x;
    }

    public function set x (val :Number) :void
    {
        _loc.x = val;
    }

    public function get y () :Number
    {
        return _loc.y;
    }

    public function set y (val :Number) :void
    {
        _loc.y = val;
    }

    public function get unitLoc () :Vector2
    {
        return _loc.clone();
    }

    protected var _owningPlayerId :uint;
    protected var _unitType :uint;
    protected var _unitData :UnitData;
    protected var _health :int;
    
    protected var _loc :Vector2 = new Vector2();

    protected static var g_groups :Array;
}

}
