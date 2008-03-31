//
// $Id$

package ghostbusters {

import flash.geom.Rectangle;

import com.whirled.AVRGameControlEvent;

import com.threerings.util.ArrayUtil;

public class Server
{
    public function Server ()
    {
        Game.control.addEventListener(
            AVRGameControlEvent.PLAYER_LEFT, handlePlayerLeft);
        Game.control.state.addEventListener(
            AVRGameControlEvent.MESSAGE_RECEIVED, handleMessage);

        _ppp = new PerPlayerProperties();
    }

    public function newRoom () :void
    {
        if (!Game.control.hasControl()) {
            Game.log.debug("I don't have control -- returning.");
            return;
        }
        maybeSpawnGhost();
    }

    /** Called at the end of the Seek phase when the ghost's appear animation is done. */
    public function ghostFullyAppeared () :void
    {
        if (!Game.control.hasControl()) {
            return;
        }
        if (checkState(GameModel.STATE_APPEARING)) {
            setState(GameModel.STATE_FIGHTING);
        }            
    }

    /** Called at the end of the Fight phase after the ghost's death or triumph animation. */
    public function ghostFullyGone () :void
    {
        if (!Game.control.hasControl()) {
            return;
        }

        if (checkState(GameModel.STATE_GHOST_TRIUMPH, GameModel.STATE_GHOST_DEFEAT)) {
            if (Game.model.state == GameModel.STATE_GHOST_TRIUMPH) {
                // heal ghost
                setGhostHealth(Game.model.ghostMaxHealth);
                setGhostZest(Game.model.ghostMaxZest);

            } else {
                // delete ghost
                payout();
                healTeam();
                setGhostId(null);
            }

            // whether the ghost died or the players wiped, clear accumulated fight stats
            clearStats();

            // and go back to seek state
            setState(GameModel.STATE_SEEKING);
        }
    }

    public function doDamagePlayer (playerId :int, damage :int) :Boolean
    {
        if (!Game.control.hasControl()) {
            throw new Error("Internal server function.");
        }
        // perform the attack
        var died :Boolean = damagePlayer(playerId, damage);

        // let all clients know of the attack
        Game.control.state.sendMessage(Codes.MSG_PLAYER_ATTACKED, playerId);

        if (died) {
            // the blow killed the player: let all the clients know that too
            Game.control.state.sendMessage(Codes.MSG_PLAYER_DEATH, playerId);
        }
        return died;
    }

    protected function everySecondTick (tick :int) :void
    {
        if ((tick % 10) == 0) {
            cleanup();
        }

        if (Game.model.state == GameModel.STATE_SEEKING) {
            seekTick(tick);

        } else if (Game.model.state == GameModel.STATE_APPEARING) {
            // do nothing

        } else if (Game.model.state == GameModel.STATE_FIGHTING) {
            fightTick(tick);

        } else if (Game.model.state == GameModel.STATE_GHOST_TRIUMPH ||
                   Game.model.state == GameModel.STATE_GHOST_DEFEAT) {
            // do nothing
        }
    }

    // called every 10 seconds to do housekeeping stuff
    protected function cleanup () :void
    {
        // delete any per-player room properties associaed with players who have left
        _ppp.deleteRoomProperties(function (playerId :int, prop :String, value :Object) :Boolean {
            if (!Game.control.isPlayerHere(playerId)) {
                Game.log.debug("Cleaning: " + playerId + "/" + prop);
                return true;
            }
            Game.log.debug("NOT cleaning: " + playerId + "/" + prop);
            return false;
        });
    }

    protected function seekTick (tick :int) :void
    {
        if (!Game.model.ghostId) {
            // maybe a delay here?
            maybeSpawnGhost();
            return;
        }

        // if the ghost has been entirely unveiled, switch to appear phase
        if (Game.model.ghostZest == 0) {
            setState(GameModel.STATE_APPEARING);
            return;
        }

        // TODO: if the controlling instance toggles the lantern, this fails - FIX FIX FIX
        if (Game.panel.ghost == null) {
            return;
        }
        var ghostBounds :Rectangle = Game.panel.ghost.getGhostBounds();
        if (ghostBounds == null) {
            return;
        }

        var x :int = Game.random.nextNumber() *
            (Game.roomBounds.width - ghostBounds.width) - ghostBounds.left;
        var y :int = Game.random.nextNumber() *
            (Game.roomBounds.height - ghostBounds.height) - ghostBounds.top;

        Game.control.state.setRoomProperty(Codes.PROP_GHOST_POS, [ x, y ]);
    }

    protected function fightTick (tick :int) :void
    {
        if (!Game.model.ghostId) {
            // this should never happen, but let's be robust
            return;
        }

        // if the ghost died, leave fight state and show the ghost's death throes
        // TODO: if the animation-based state transition back to SEEK fails, we should
        // TODO: have a backup timeout using the ticker
        if (Game.model.isGhostDead()) {
            setState(GameModel.STATE_GHOST_DEFEAT);
            return;
        }

        // if the players all died, leave fight state and play the ghost's triumph scene
        // TODO: if the animation-based state transition back to SEEK fails, we should
        // TODO: have a backup timeout using the ticker
        if (Game.model.isEverybodyDead()) {
            setState(GameModel.STATE_GHOST_TRIUMPH);
            return;
        }

        // if ghost is alive and at least one player is still up, just do an normal AI tick
        var brainTick :Function = Game.model.getGhostData().brain as Function;
        if (brainTick != null) {
            brainTick(tick);
        }
    }

    // if a player leaves, clear their room data
    protected function handlePlayerLeft (evt :AVRGameControlEvent) :void
    {
        if (!Game.control.hasControl()) {
            return;
        }
        var playerId :int = evt.value as int;
        if (_ppp.getRoomProperty(playerId, Codes.PROP_LANTERN_POS) != null) {
            _ppp.setRoomProperty(playerId, Codes.PROP_LANTERN_POS, null);
        }
    }

    protected function handleMessage (event: AVRGameControlEvent) :void
    {
        if (!Game.control.hasControl()) {
            return;
        }
        var msg :String = event.name;
        var bits :Array;

        if (msg == Codes.MSG_TICK) {
            everySecondTick(event.value as int);

        } else if (msg == Codes.MSG_GHOST_ZAP) {
            if (checkState(GameModel.STATE_SEEKING)) {
                setGhostZest(Game.model.ghostZest * 0.9 - 15);
            }

        } else if (msg == Codes.MSG_MINIGAME_RESULT) {
            if (checkState(GameModel.STATE_FIGHTING)) {
                bits = event.value as Array;
                if (bits != null) {
                    accumulateStats(bits[0] as int, bits[1] as Boolean);
                    if (bits[2] > 0) {
                        damageGhost(bits[2]);
                    }
                    if (bits[3] > 0) {
                        doHealPlayers(bits[3]);
                    }
                }
            }
        }
    }

    protected function doHealPlayers (totHeal :int) :void
    {
        var team :Array = Game.getTeam(true);

        // figure out how hurt each party member is, and the total hurt
        var playerDmg :Array = new Array(team.length);
        var totDmg :int = 0;
        for (var ii :int = 0; ii < team.length; ii ++) {
            playerDmg[ii] = (Game.model.getPlayerMaxHealth(team[ii]) -
                             Game.model.getPlayerHealth(team[ii]));
            totDmg += playerDmg[ii];
        }
        Game.log.debug("HEAL :: Total heal = " + totHeal + "; Total team damage = " + totDmg);
        // hand totHeal out proportionally to each player's relative hurtness
        for (ii = 0; ii < team.length; ii ++) {
            var heal :int = (totHeal * playerDmg[ii]) / totDmg;
            Game.log.debug("HEAL :: Awarding " + heal + " pts to player #" + team[ii]);
            healPlayer(team[ii], heal);
        }
    }

    protected function maybeSpawnGhost () :void
    {
        if (Game.model.ghostId != null) {
            return;
        }

        // initialize the room with a ghost
        var id :String = Content.GHOSTS[Game.random.nextInt(Content.GHOSTS.length)].id;

        var zest :int = 150 + 100 * Game.random.nextNumber();
        setGhostZest(zest);
        setGhostMaxZest(zest);

        var health :int = 100;
        setGhostHealth(100);
        setGhostMaxHealth(100);

        // set the ghostId last of all, since that triggers loading
        setGhostId(id);
    }

    protected function checkState (... expected) :Boolean
    {
        if (ArrayUtil.contains(expected, Game.model.state)) {
            return true;
        }
        Game.log.debug("State mismatch [expected=" + expected + ", actual=" +
                       Game.model.state + "]");
        return false;
    }

    protected function payout () :void
    {
        var stats :Object = Game.control.state.getRoomProperty(Codes.PROP_STATS) as Object;
        if (stats == null) {
            stats = { };
        }

        var team :Array = Game.getTeam();
        var points :Array = new Array(team.length);

        var totPoints :int = 0;
        for (var ii :int = 0; ii < team.length; ii ++) {
            points[ii] = int(stats[team[ii]]);
            totPoints += points[ii];
            Game.log.debug("Player #" + team[ii] + " accrued " + points[ii] + " points...");
        }

        if (totPoints == 0) {
            return;
        }

        // The current payout factor for a player is linearly proportional to how many minigame
        // points that player scored relative to the points scored by the whole team. A solo kill
        // against a ghost the player's own level yields a factor of 0.5. Killing a higher level
        // ghost yields a progressive bonus up to 100% and a lower level ghost shrinks the reward
        // commensurately. Finally, the payout is reduced by the square root of the size of the
        // team.
        //
        // The rationale behind the level and team size tweaks are not that strong players should
        // get more flow, but rather to compensate for the fact that a strong player can kill
        // weak ghosts at a very rapid rate and this is per-kill compensation.
        //
        // The rationale behind the square root is one seen in many MMO's: first, you divide the
        // payout by the size of the team (because 4 people can kill much faster than 2), then
        // you partially undo this penalty with a "team bonus" to encourage socializing and to
        // provide a bit of slack in the group makeup. 
        //
        //   payoutFactor(player) = 0.5 *
        //      levelAdjustment(level(ghost) - level(player)) *
        //      (minigamePoints(player) / minigamePoints(team)) *
        //      (1 / SQRT(size(team)))
        //
        // The precise definition of levelAdjustment() is up in the air, but I figure something
        // along the lines of 1+atan(x/2) (http://www.mathsisfun.com/graph/function-grapher.php)

        for (ii = 0; ii < team.length; ii ++) {
            var factor :Number = 0.5 * (points[ii]  / totPoints) / Math.sqrt(team.length);
            if (factor > 0) {
                Game.control.state.sendMessage(Codes.MSG_PAYOUT_FACTOR, factor, team[ii]);
            }
        }
    }

    // server-specific parts of the model moved here
    protected function damageGhost (damage :int) :Boolean
    {
        var health :int = Game.model.ghostHealth;
        Game.log.debug("Doing " + damage + " damage to a ghost with health " + health);
        if (damage >= health) {
            setGhostHealth(0);
            return true;
        }
        setGhostHealth(health - damage);
        return false;
    }

    protected function damagePlayer (playerId :int, damage :int) :Boolean
    {
        var health :int = Game.model.getPlayerHealth(playerId);
        Game.log.debug("Doing " + damage + " damage to a player with health " + health);
        if (damage >= health) {
            killPlayer(playerId);
            return true;
        }
        setPlayerHealth(playerId, health - damage);
        return false;
    }

    protected function healTeam () :void
    {
        var team :Array = Game.getTeam(true);
        for (var ii :int = 0; ii < team.length; ii ++) {
            healPlayer(team[ii]);
        }
    }

    protected function healPlayer (playerId :int, amount :int = -1) :void
    {
        var maxHealth :int = Game.model.getPlayerMaxHealth(playerId);
        var newHealth :int;
        if (amount < 0) {
            newHealth = maxHealth;
        } else {
            newHealth = Math.min(maxHealth, amount + Game.model.getPlayerHealth(playerId));
        }
        setPlayerHealth(playerId, newHealth);
    }

    protected function killPlayer (playerId :int) :void
    {
        _ppp.setProperty(playerId, Codes.PROP_PLAYER_CUR_HEALTH, -1);
    }

    protected function setPlayerHealth (playerId :int, health :int) :void
    {
        _ppp.setProperty(playerId, Codes.PROP_PLAYER_CUR_HEALTH,
                        Math.max(0, Math.min(health, Game.model.getPlayerMaxHealth(playerId))));
    }

    protected function setGhostId (id :String) :void
    {
        Game.control.state.setRoomProperty(Codes.PROP_GHOST_ID, id);
    }

    protected function setGhostHealth (health :int) :void
    {
        Game.control.state.setRoomProperty(Codes.PROP_GHOST_CUR_HEALTH, Math.max(0, health));
    }

    protected function setGhostMaxHealth (health :int) :void
    {
        Game.control.state.setRoomProperty(Codes.PROP_GHOST_MAX_HEALTH, Math.max(0, health));
    }

    protected function setGhostZest (zest :Number) :void
    {
        Game.control.state.setRoomProperty(Codes.PROP_GHOST_CUR_ZEST, Math.max(0, zest));
    }

    protected function setGhostMaxZest (zest :Number) :void
    {
        Game.control.state.setRoomProperty(Codes.PROP_GHOST_MAX_ZEST, Math.max(0, zest));
    }

    protected function setState (state :String) :void
    {
        Game.control.state.setRoomProperty(Codes.PROP_STATE, state);
    }

    protected function accumulateStats (playerId :int, win :Boolean) :void
    {
        var stats :Object = Game.control.state.getRoomProperty(Codes.PROP_STATS) as Object;
        if (stats == null) {
            stats = { };
        }

        // award 3 points for a win, 1 for a lose
        stats[playerId] = int(stats[playerId]) + (win ? 3 : 1);
        Game.control.state.setRoomProperty(Codes.PROP_STATS, stats);
    }

    protected function clearStats () :void
    {
        Game.control.state.setRoomProperty(Codes.PROP_STATS, null);
    }

    protected var _ppp :PerPlayerProperties;

}
}
