// $Id$

package com.threerings.graffiti.tools {

import flash.events.EventDispatcher;
import flash.events.MouseEvent;

[Event(name="buttonSelected", type="RadioEvent")];

public class RadioButtonSet extends EventDispatcher
{
    public function addButton (button :ToggleButton, select :Boolean = false) :void
    {
        var index :int = _buttons.length;
        _buttons.push(button);
        button.button.addEventListener(MouseEvent.MOUSE_DOWN, function (event :MouseEvent) :void {
            buttonClicked(index);
        });
        if (select) {
            buttonClicked(index);
        }
    }

    public function deactivateCurrentSelection () :void
    {
        if (_selected == -1) {
            return;
        }

        _buttons[_selected].selected = false;
        _selected = -1;
    }

    protected function buttonClicked (index :int) :void
    {
        if (_selected != -1) {
            _buttons[_selected].selected = false;
        }
        _buttons[_selected = index].selected = true;

        dispatchEvent(new RadioEvent(RadioEvent.BUTTON_SELECTED, _buttons[_selected].value));
    }

    protected var _buttons :Array = [];
    protected var _selected :int = -1;
}
}
