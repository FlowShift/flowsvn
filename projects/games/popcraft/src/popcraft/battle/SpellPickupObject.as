package popcraft.battle {

import com.whirled.contrib.simplegame.SimObject;
import com.whirled.contrib.simplegame.components.LocationComponent;

import popcraft.*;
import popcraft.data.UnitSpellData;

public class SpellPickupObject extends SimObject
    implements LocationComponent
{
    public static const GROUP_NAME :String = "SpellPickupObject";
    public static const RADIUS :Number = 20;

    public function SpellPickupObject (spellType :uint)
    {
        _spellType = spellType;
    }

    public function get spellType () :uint
    {
        return _spellType;
    }

    public function get spellData () :UnitSpellData
    {
        return GameContext.gameData.spells[_spellType];
    }

    public function get x () :Number
    {
        return _xLoc;
    }

    public function set x (val :Number) :void
    {
        _xLoc = val;
    }

    public function get y () :Number
    {
        return _yLoc;
    }

    public function set y (val :Number) :void
    {
        _yLoc = val;
    }

    override public function get objectGroups () :Array
    {
        return [ GROUP_NAME ];
    }

    protected var _spellType :uint;
    protected var _xLoc :Number = 0;
    protected var _yLoc :Number = 0;

}

}
