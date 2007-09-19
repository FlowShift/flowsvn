package com.threerings.defense.ui {

import mx.containers.ApplicationControlBar;
import mx.containers.HBox;
import mx.containers.VBox;
import mx.controls.Label;

import com.threerings.defense.tuning.Messages;
import com.threerings.util.StringUtil;

public class ScorePanel extends ApplicationControlBar
{
    public function ScorePanel()
    {
        this.visible = false;
        this.includeInLayout = false;
    }

    override protected function createChildren () :void
    {
        super.createChildren ();

        var contents :VBox = new VBox();
        addChild(contents);

        contents.addChild(_name = new Label());

        var row :HBox = new HBox();
        
        row.addChild(Messages.getLabel("health"));
        row.addChild(_health = new Label());
        contents.addChild(row);
        row = new HBox();
        row.addChild(Messages.getLabel("score"));
        row.addChild(_score = new Label());
        contents.addChild(row);
    }

    public function init (player :int, name :String) :void
    {
        _name.text = StringUtil.truncate(name, 10, "...");
        this.health = 0;
        this.score = 0;

        this.visible = true;
        this.includeInLayout = true;
        
        if (player == 0) {
            this.x = 790; this.y = 410;
        } else {
            this.x = 10; this.y = 100;
        }
    }

    public function set health (value :Number) :void
    {
        _health.text = String(value);
    }
    
    public function set score (value :Number) :void
    {
        _score.text = String(value);
    }
    
    protected var _name :Label;
    protected var _health :Label;
    protected var _score :Label;
}
}
