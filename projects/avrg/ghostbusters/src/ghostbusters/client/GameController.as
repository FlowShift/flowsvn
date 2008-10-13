//
// $Id$

package ghostbusters.client {

import flash.display.DisplayObject;

import com.threerings.util.Controller;
import com.threerings.util.Log;

import com.whirled.avrg.AVRGameAvatar;
import com.whirled.avrg.AVRGameControlEvent;

import ghostbusters.client.fight.FightPanel;
import ghostbusters.client.fight.MicrogameResult;
import ghostbusters.data.Codes;
import ghostbusters.client.util.PlayerModel;

public class GameController extends Controller
{
    public static const BEGIN_PLAYING :String = "BeginPlaying";
    public static const CHOOSE_AVATAR :String = "ChooseAvatar";
    public static const CHOOSE_WEAPON :String = "ChooseWeapon";
    public static const CLOSE_SPLASH :String = "CloseSplash";
    public static const END_GAME :String = "EndGame";
    public static const GHOST_ATTACKED :String = "GhostAttacked";
    public static const GIMME_DEBUG_PANEL :String = "GimmeDebugPanel";
    public static const HELP :String = "Help";
    public static const PLAYER_ATTACKED :String = "PlayerAttacked";
    public static const REVIVE :String = "Revive";
    public static const TOGGLE_LANTERN :String = "ToggleLantern";
    public static const ZAP_GHOST :String = "ZapGhost";

    public var panel :GamePanel;

    public function GameController ()
    {
        panel = new GamePanel()
        setControlledPanel(panel);
    }

    public function handleEndGame () :void
    {
// TODO: what is the best way to reset the state of a departing AVRG player?
//        setAvatarState(GamePanel.ST_PLAYER_DEFAULT);
        Game.control.player.deactivateGame();
    }

    public function handleHelp () :void
    {
        panel.showSplash(true);
    }

    public function handleGimmeDebugPanel () :void
    {
        // leave it entirely to the agent to decide if clicking here does anything
        Game.control.agent.sendMessage(Codes.CMSG_DEBUG_REQUEST, Codes.DBG_GIMME_PANEL);
    }

    public function handleToggleLantern () :void
    {
        if (PlayerModel.isDead(Game.ourPlayerId)) {
            // the button is always disabled if you're dead -- revive first!
            log.debug("You can't toggle the lantern, you're dead!");
            return;
        }

        var state :String = Game.state;
        if (state == Codes.STATE_SEEKING) {
            panel.seeking = !panel.seeking;

        } else if (state == Codes.STATE_APPEARING) {
            // no effect: you have to watch this bit

        } else if (state == Codes.STATE_FIGHTING) {
            var subPanel :FightPanel = FightPanel(Game.panel.subPanel);
            if (subPanel != null) {
                subPanel.toggleGame();
            }

        } else if (state == Codes.STATE_GHOST_TRIUMPH ||
                   state == Codes.STATE_GHOST_DEFEAT) {
            // no effect: you have to watch this bit

       } else {
            log.debug("Unexpected state in toggleLantern", "state", state);
        }
    }

    public function handleBeginPlaying () :void
    {
        Game.control.agent.sendMessage(Codes.CMSG_BEGIN_PLAYING);        
    }

    public function handleChooseAvatar (avatar :String) :void
    {
        Game.control.agent.sendMessage(Codes.CMSG_CHOOSE_AVATAR, avatar);
    }

    public function handleChooseWeapon (weapon :int) :void
    {
        // always update the HUD's lantern button
        // TODO: this probably no longer makes much UI sense
        panel.hud.chooseWeapon(weapon);

        if (!(panel.subPanel is FightPanel)) {
            // should not happen, but let's be robust
            log.debug("Eek, subpanel is not FightPanel");
            return;
        }
        FightPanel(panel.subPanel).weaponUpdated();
    }

    public function handleGhostAttacked (weapon :int, result :MicrogameResult) :void
    {
        Game.control.agent.sendMessage(
            Codes.CMSG_MINIGAME_RESULT, [
                weapon,
                result.success == MicrogameResult.SUCCESS,
                result.damageOutput,
                result.healthOutput
            ]);

        if (result.success == MicrogameResult.SUCCESS) {
            Game.control.player.playAvatarAction("Retaliate");
        }
    }

    public function handleZapGhost () :void
    {
        Game.control.agent.sendMessage(Codes.CMSG_GHOST_ZAP, Game.ourPlayerId);
    }

    public function handleRevive () :void
    {
        if (PlayerModel.isDead(Game.ourPlayerId) && Game.state != Codes.STATE_FIGHTING) {
            Game.control.agent.sendMessage(Codes.CMSG_PLAYER_REVIVE);
        }
    }

    protected static const log :Log = Log.getLog(GameController);
}
}
