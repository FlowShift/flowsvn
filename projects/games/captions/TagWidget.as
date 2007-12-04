//
// $Id$

package {

import flash.display.Sprite;

import flash.events.MouseEvent;
import flash.events.TextEvent;

import flash.text.TextFormat;

import fl.containers.ScrollPane;

import fl.controls.Button;
import fl.controls.CheckBox;
import fl.controls.Label;
import fl.controls.ScrollPolicy;
import fl.controls.TextInput;

import fl.events.ComponentEvent;

import com.threerings.util.StringUtil;

import com.threerings.ezgame.PropertyChangedEvent;

import com.whirled.WhirledGameControl;

/**
 * Allows users to view/add/remove the tags used for LOLcaptions.
 */
public class TagWidget extends Sprite
{
    public function TagWidget (
        ctrl :WhirledGameControl, searchPhotoService :SearchFlickrPhotoService) :void
    {
        _ctrl = ctrl;
        _searchPhotoService = searchPhotoService;
        _ctrl.addEventListener(PropertyChangedEvent.TYPE, handlePropertyChanged);

        _tagFormat = new TextFormat();
        _tagFormat.color = 0xFFFFFF;

        var label :Label = new Label();
        label.setStyle("textFormat", _tagFormat);
        label.text = "Tags:";
        label.setSize(100, 22);
        addChild(label);

        _tagInput = new TextInput();
        _tagInput.restrict = "^ ";
        //_tagInput.addEventListener(TextEvent.TEXT_INPUT, handleTagInput);
        _tagInput.addEventListener(ComponentEvent.ENTER, handleTagInput);
        _tagInput.y = 25;
        addChild(_tagInput);

        _tagPane = new ScrollPane();
        _tagPane.horizontalScrollPolicy = ScrollPolicy.OFF;
        _tagSprite = new Sprite();
        _tagPane.source = _tagSprite;
        _tagPane.y = 50;
        addChild(_tagPane);

        // add all the tags
        for each (var tag :String in _ctrl.getPropertyNames("tag:")) {
            addTag(tag.substring(4));
        }

        updateSearchTags();
    }

    public function setSize (w :Number, h :Number) :void
    {
        _tagInput.setSize(w, 22);
        _tagPane.setSize(w, h - 50);
    }

    protected function addTag (tag :String) :void
    {
        var tagBox :CheckBox = new CheckBox();
        tagBox.setStyle("textFormat", _tagFormat);
        tagBox.setStyle("upIcon", X_UP_SKIN);
        tagBox.setStyle("overIcon", X_OVER_SKIN);
        tagBox.setStyle("downIcon", X_DOWN_SKIN);
        tagBox.addEventListener(MouseEvent.CLICK, handleTagRemove);
        tagBox.label = tag;
        tagBox.y = 25 * _tagSprite.numChildren;
        _tagSprite.addChild(tagBox);

        _tagPane.update();
    }

    protected function removeTag (tag :String) :void
    {
        var removed :Boolean = false;
        for (var ii :int = 0; ii < _tagSprite.numChildren; ii++) {
            var cb :CheckBox = _tagSprite.getChildAt(ii) as CheckBox;
            if (!removed) {
                if (cb.label == tag) {
                    // this is the one to remove
                    _tagSprite.removeChildAt(ii);
                    ii--;
                    removed = true;
                }
            } else {
                cb.y -= 25;
            }
        }

        if (removed) {
            _tagPane.update();
        }
    }

    protected function handleTagInput (event :ComponentEvent) :void
    {
        var tag :String = StringUtil.trim(_tagInput.text);
        if (!StringUtil.isBlank(tag)) {
            // go ahead and just add it
            _ctrl.set("tag:" + tag.toLowerCase(), 1);
        }
        _tagInput.text = "";
    }

    protected function handleTagRemove (event :MouseEvent) :void
    {
        var cb :CheckBox = event.target as CheckBox;
        var tag :String = cb.label;
        _ctrl.set("tag:" + tag, null);
        // remove it locally immediately
        removeTag(tag);
    }

    protected function handlePropertyChanged (event :PropertyChangedEvent) :void
    {
        var name :String = event.name;
        if (StringUtil.startsWith(name, "tag:")) {
            if (event.newValue != event.oldValue) {
                var tag :String = name.substring(4);
                var add :Boolean = (event.newValue != null);
                if (add) {
                    addTag(tag);
                } else {
                    removeTag(tag);
                }
                updateSearchTags();
            }
        }
    }

    protected function updateSearchTags () :void
    {
        var tags :Array = [];
        for each (var tag :String in _ctrl.getPropertyNames("tag:")) {
            tags.push(tag.substring(4));
        }

//        trace("Updated tag search to: '" + tags + "'.");
        _searchPhotoService.setKeywords(tags, true);
    }

    [Embed(source="rsrc/x_up.png")]
    protected static const X_UP_SKIN :Class;

    [Embed(source="rsrc/x_over.png")]
    protected static const X_OVER_SKIN :Class;

    [Embed(source="rsrc/x_down.png")]
    protected static const X_DOWN_SKIN :Class;

    protected var _ctrl :WhirledGameControl;

    protected var _tagFormat :TextFormat;

    protected var _searchPhotoService :SearchFlickrPhotoService;

    protected var _tagInput :TextInput;

    protected var _tagPane :ScrollPane;

    protected var _tagSprite :Sprite;
}
}
