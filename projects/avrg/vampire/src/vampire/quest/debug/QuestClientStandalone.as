package vampire.quest.debug {

import com.whirled.contrib.ManagedTimer;
import com.whirled.contrib.TimerManager;
import com.threerings.flashbang.*;
import com.whirled.net.PropertySubControl;

import flash.display.Sprite;

import vampire.avatar.VampireBody;
import vampire.client.VampireMain;
import vampire.debug.LocalPropertySubControl;
import vampire.feeding.FeedingClient;
import vampire.furni.QuestTotem;
import vampire.quest.*;
import vampire.quest.client.*;

[SWF(width="1000", height="700", frameRate="30")]
public class QuestClientStandalone extends Sprite
{
    QuestTestServer;
    QuestTestClient;
    QuestTotem;
    VampireBody;
    VampireMain;

    public function QuestClientStandalone ()
    {
        var appMode :AppMode = new AppMode();
        var panelLayer :Sprite = new Sprite();
        var minigameLayer :Sprite = new Sprite();
        var notificationLayer :Sprite = new Sprite();
        appMode.modeSprite.addChild(panelLayer);
        appMode.modeSprite.addChild(minigameLayer);
        appMode.modeSprite.addChild(notificationLayer);

        // Init simplegame
        _sg = new FlashbangApp(new Config());
        _sg.ctx.mainLoop.pushMode(appMode);
        _sg.run(this);

        // Init local props
        var localProps :LocalPropertySubControl = new LocalPropertySubControl();
        var gameCtrl :DisconnectedControl = new DisconnectedControl(this);

        FeedingClient.init(this, gameCtrl);
        QuestClient.init(gameCtrl, _sg, appMode, panelLayer, minigameLayer, notificationLayer,
            localProps);

        var waitLoop :ManagedTimer = _timerMgr.runForever(50,
            function (...ignored) :void {
                if (QuestClient.isReady) {
                    waitLoop.cancel();
                    start();
                }
            });
    }

    protected function start () :void
    {
        QuestClient.showDebugPanel(true);
        ClientCtx.dockSprite.showQuestPanel();
    }

    protected var _sg :FlashbangApp;
    protected var _localProps :PropertySubControl;
    protected var _timerMgr :TimerManager = new TimerManager();
}

}

import com.whirled.avrg.AVRGameControl;
import flash.display.DisplayObject;

class DisconnectedControl extends AVRGameControl
{
    public function DisconnectedControl (disp :DisplayObject)
    {
        super(disp);
    }

    override public function isConnected () :Boolean
    {
        return false;
    }
}
