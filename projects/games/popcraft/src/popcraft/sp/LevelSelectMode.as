package popcraft.sp {

import com.threerings.flash.SimpleTextButton;
import com.whirled.contrib.simplegame.*;

import flash.display.SimpleButton;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import popcraft.*;
import popcraft.ui.UIBits;

public class LevelSelectMode extends SplashScreenModeBase
{
    override public function update (dt :Number) :void
    {
        if (!_createdLayout && !UserCookieManager.isLoadingCookie && AppContext.levelMgr.levelRecordsLoaded) {
            this.createLayout();
        }
    }

    override protected function setup () :void
    {
        super.setup();

        if (AppContext.levelMgr.levelRecordsLoaded) {
            this.createLayout();
        }
    }

    protected function createLayout () :void
    {
        _createdLayout = true;

        var tf :TextField = new TextField();
        tf.selectable = false;
        tf.autoSize = TextFieldAutoSize.LEFT;
        tf.textColor = 0xFFFFFF;
        tf.text = "PopCraft level select. (Score: " + AppContext.levelMgr.totalScore + ")";
        tf.scaleX = 1;
        tf.scaleY = 1;
        tf.x = (Constants.SCREEN_SIZE.x * 0.5) - (tf.width * 0.5);
        tf.y = 10;

        this.modeSprite.addChild(tf);

        var levelNames :Array = AppContext.levelProgression.levelNames;
        var levelRecords :Array = AppContext.levelMgr.levelRecords;

        var button :SimpleButton;
        var yLoc :Number = tf.height + 15;
        // create a button for each level
        for (var i :int = 0; i < levelRecords.length; ++i) {
            var levelName :String = (i < levelNames.length ? levelNames[i] : "(Level " + String(i + 1) + ")");
            var levelRecord :LevelRecord = levelRecords[i];

            if (!levelRecord.unlocked) {
                break;
            }

            if (levelRecord.score > 0) {
                levelName += " (" + levelRecord.score;
                if (levelRecord.expert) {
                    levelName += " *";
                }
                levelName += ")";
            }

            button = this.createLevelSelectButton(i, levelName);
            button.x = (Constants.SCREEN_SIZE.x * 0.5) - (button.width * 0.5);
            button.y = yLoc;
            this.modeSprite.addChild(button);

            yLoc += button.height + 3;
        }

        // animation test button
        button = UIBits.createButton("Unit Anim Test");
        button.addEventListener(MouseEvent.CLICK,
            function (...ignored) :void {
                AppContext.mainLoop.pushMode(new UnitAnimTestMode());
            });
        button.x = 10;
        button.y = 450;

        this.modeSprite.addChild(button);

        // test level button
        button = UIBits.createButton("Jon's stress test");
        button.addEventListener(MouseEvent.CLICK, function (...ignored) :void { levelSelected(-1); });
        button.x = 100;
        button.y = 450;

        this.modeSprite.addChild(button);

        // unlock all levels button
        button = UIBits.createButton("Unlock levels");
        button.addEventListener(MouseEvent.CLICK, function (...ignored) :void { unlockLevels(); });
        button.x = 10;
        button.y = 10;

        this.modeSprite.addChild(button);
    }

    protected function unlockLevels () :void
    {
        var levelRecords :Array = AppContext.levelMgr.levelRecords;
        for each (var lr :LevelRecord in levelRecords) {
            lr.unlocked = true;
        }

        // reload the mode
        MainLoop.instance.changeMode(new LevelSelectMode());
    }

    protected function createLevelSelectButton (levelNum :int, levelName :String) :SimpleButton
    {
        var button :SimpleButton = UIBits.createButton(levelName);
        button.addEventListener(MouseEvent.CLICK,
            function (...ignored) :void {
                levelSelected(levelNum);
            });

        return button;
    }

    protected function levelSelected (levelNum :int) :void
    {
        AppContext.levelMgr.curLevelIndex = levelNum;
        AppContext.levelMgr.playLevel();
    }

    protected var _createdLayout :Boolean;

}

}
