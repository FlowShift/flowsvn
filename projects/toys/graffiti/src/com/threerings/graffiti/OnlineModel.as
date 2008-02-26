// $Id$

package com.threerings.graffiti {

import flash.geom.Point;

import com.threerings.util.Log;

import com.whirled.EntityControl;
import com.whirled.ControlEvent;

public class OnlineModel extends Model
{
    public function OnlineModel (canvas :Canvas, control :EntityControl) 
    {
        super(canvas);

        _control = control;

        var memories :Object = _control.getMemories();
        for (var key :String in memories) {
            putStroke(key, memories[key]);
        }

        _control.addEventListener(ControlEvent.MESSAGE_RECEIVED, handleMessage);
    }

    override public function beginStroke (id :String, from :Point, to :Point, colour :int) :void
    {
        super.beginStroke(id, from, to, colour);
        _control.sendMessage(id, [ from.x, from.y, to.x, to.y, colour ]);
    }

    override public function extendStroke (id :String, to :Point) :void
    {
        super.extendStroke(id, to);
        _control.sendMessage(id, [ to.x, to.y ]);
    }

    protected function handleMessage (evt :ControlEvent) :void
    {
        var arr :Array = (evt.value as Array);
        if (!arr) {
            log.debug("Eek, non-array value in evt: " + evt);
            return;
        }
        if (arr.length == 5) {
            beginStroke(evt.name, new Point(arr[0], arr[1]), new Point(arr[2], arr[3]), arr[4]);

        } else {
            extendStroke(evt.name, new Point(arr[0], arr[1]));
        }
    }

    override protected function putStroke (id :String, stroke :Array) :void
    {
        super.putStroke(id, stroke);
        if (_control.hasControl()) {
            _control.updateMemory(id, stroke);
        }
    }

    private static const log :Log = Log.getLog(OnlineModel);

    protected var _control :EntityControl;
}
}
