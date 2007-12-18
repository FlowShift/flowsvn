package popcraft.battle {

import core.util.*;

/** Encapsulates immutable data about a particular type of Creature. */
public class UnitData
{
    public var name :String;
    public var resourceCosts :Array;
    public var imageClass :Class;

    // movement variables
    public var wanderEvery :Number;
    public var wanderRange :IntRange;
    public var movePixelsPerSecond :Number;

    public var maxHealth :int;
    public var armor :UnitArmor;
    public var attack :UnitAttack;

    public function UnitData (
        name :String,
        resourceCosts :Array,
        imageClass :Class,
        wanderEvery :Number,
        wanderRange :IntRange,
        movePixelsPerSecond :Number,
        maxHealth :int,
        armor :UnitArmor,
        attack :UnitAttack )
    {
        this.name = name;
        this.resourceCosts = resourceCosts;
        this.imageClass = imageClass;

        this.wanderEvery = wanderEvery;
        this.wanderRange = wanderRange;
        this.movePixelsPerSecond = movePixelsPerSecond;

        this.maxHealth = maxHealth;
        this.armor = armor;
        this.attack = attack;
    }

    public function getResourceCost (resourceType :uint) :int
    {
        return this.resourceCosts[resourceType];
    }
}

}
