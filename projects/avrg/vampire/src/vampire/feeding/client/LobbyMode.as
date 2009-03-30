package vampire.feeding.client {

import com.threerings.flash.TextFieldUtil;
import com.whirled.contrib.avrg.RoomDragger;
import com.whirled.contrib.simplegame.AppMode;
import com.whirled.contrib.simplegame.util.Rand;
import com.whirled.net.ElementChangedEvent;
import com.whirled.net.PropertyChangedEvent;

import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.events.MouseEvent;
import flash.text.TextField;

import vampire.data.VConstants;
import vampire.feeding.Constants;
import vampire.feeding.net.CloseLobbyMsg;
import vampire.feeding.net.Props;
import vampire.feeding.net.RoundOverMsg;

public class LobbyMode extends AppMode
{
    public function LobbyMode (roundResults :RoundOverMsg = null) :void
    {
        _results = roundResults;
    }

    override protected function setup () :void
    {
        super.setup();

        registerListener(ClientCtx.props, PropertyChangedEvent.PROPERTY_CHANGED, onPropChanged);
        registerListener(ClientCtx.props, ElementChangedEvent.ELEMENT_CHANGED, onPropChanged);

        _panelMovie = ClientCtx.instantiateMovieClip("blood", "popup_panel");
        _modeSprite.addChild(_panelMovie);

        var contents :MovieClip = _panelMovie["draggable"];

        // Make the lobby draggable
        addObject(new RoomDragger(ClientCtx.gameCtrl, contents, _panelMovie));
        ClientCtx.centerInRoom(_panelMovie);

        // Instructions
        var instructionsBasic :MovieClip = contents["instructions_basic"];
        var instructionsMultiplayer :MovieClip = contents["instructions_multiplayer"];
        var instructionsStrain :MovieClip = contents["instructions_strains"];
        instructionsBasic.visible = false;
        instructionsMultiplayer.visible = false;
        instructionsStrain.visible = false;

        if (this.isPreGameLobby && ClientCtx.playerData.timesPlayed == 0) {
            instructionsBasic.visible = true;
        } else if ((this.isPreGameLobby || Rand.nextBoolean(Rand.STREAM_COSMETIC)) &&
                   ClientCtx.playerCanCollectPreyStrain) {
            instructionsStrain.visible = true;
        } else {
            instructionsMultiplayer.visible = true;
        }

        // Quit button
        var quitBtn :SimpleButton = _panelMovie["button_done"];
        registerOneShotCallback(quitBtn, MouseEvent.CLICK,
            function (...ignored) :void {
                ClientCtx.quit(true);
            });

        // Start/Play Again/Status
        var startButton :SimpleButton = _panelMovie["button_start"];
        var replayButton :SimpleButton = _panelMovie["button_again"];
        startButton.visible = false;
        replayButton.visible = false;
        _startButton = (isPostRoundLobby ? replayButton : startButton);
        registerListener(_startButton, MouseEvent.CLICK,
            function (...ignored) :void {
                if (_startButton.visible) {
                    ClientCtx.msgMgr.sendMessage(new CloseLobbyMsg());
                }
            });

        _tfStatus = contents["feedback_text"];
        updateButtonsAndStatus();

        // Total score
        var total :MovieClip = contents["total"];
        if (this.isPreGameLobby) {
            total.visible = false;
        } else {
            total.visible = true;
            var tfTotal :TextField = total["player_score"];
            tfTotal.text = String(_results.totalScore);
        }

        // Player list
        _playerList = new SimpleListController(
            [],
            contents,
            "player",
            [ "player_name", "player_score" ],
            _panelMovie["arrow_up"],
            _panelMovie["arrow_down"]);
        addObject(_playerList);
        updatePlayerList();

        updateBloodBondIndicator();

        // next round timer
        var roundTimer :MovieClip = _panelMovie["round_timer"];
        roundTimer.visible = false;
    }

    protected function updateButtonsAndStatus () :void
    {
        if (ClientCtx.preyId == Constants.NULL_PLAYER && !ClientCtx.preyIsAi) {
            _startButton.visible = false;
            _tfStatus.visible = true;
            _tfStatus.text = "Your Feast has wandered off";

        } else if (ClientCtx.isLobbyLeader) {
            _startButton.visible = true;
            _tfStatus.visible = false;

        } else {
            _startButton.visible = false;
            _tfStatus.visible = true;
            var leaderName :String = ClientCtx.getPlayerName(ClientCtx.lobbyLeaderId);
            if (ClientCtx.playerIds.length == 1) {
                _tfStatus.text = "All Feeders have left";
            } else if (this.isPreGameLobby) {
                _tfStatus.text = "Waiting for " + leaderName + " to start feeding";
            } else {
                _tfStatus.text = "Waiting for " + leaderName + " to feed again";
            }

            TextFieldUtil.setMaximumTextWidth(_tfStatus, _tfStatus.width);
        }
    }

    protected function updatePlayerList () :void
    {
        var listData :Array = [];
        var obj :Object;
        var playerId :int;

        var contents :MovieClip = _panelMovie["draggable"];

        // Fill in the Prey data
        var preyInfo :MovieClip = contents["playerprey"];
        var tfName :TextField = preyInfo["player_name"];
        if (ClientCtx.preyIsAi || ClientCtx.isPlayer(ClientCtx.preyId)) {
            tfName.visible = true;
            tfName.text = (ClientCtx.preyIsAi ?
                            ClientCtx.aiPreyName :
                            ClientCtx.getPlayerName(ClientCtx.preyId));
        } else {
            tfName.visible = false;
        }

        var tfScore :TextField = preyInfo["player_score"];
        if (tfName.visible && this.isPostRoundLobby && !ClientCtx.preyIsAi) {
            tfScore.visible = true;
            tfScore.text = String(int(_results.scores.get(ClientCtx.preyId)));
        } else {
            tfScore.visible = false;
        }

        // Fill in the Predators list
        if (this.isPostRoundLobby) {
            _results.scores.forEach(
                function (playerId :int, score :int) :void {
                    if (playerId != ClientCtx.preyId && ClientCtx.isPlayer(playerId)) {
                        obj = {};
                        obj["player_name"] = ClientCtx.getPlayerName(playerId);
                        obj["player_score"] = score;
                        listData.push(obj);
                    }
                });

            // Anyone who joined the game while the round was in progress doesn't have a score
            for each (playerId in ClientCtx.playerIds) {
                if (playerId != ClientCtx.preyId && !_results.scores.containsKey(playerId)) {
                    obj = {};
                    obj["player_name"] = ClientCtx.getPlayerName(playerId);
                    listData.push(obj);
                }
            }

        } else {
            for each (playerId in ClientCtx.playerIds) {
                if (playerId != ClientCtx.preyId) {
                    obj = {};
                    obj["player_name"] = ClientCtx.getPlayerName(playerId);
                    listData.push(obj);
                }
            }
        }

        _playerList.data = listData;
    }

    protected function updateBloodBondIndicator () :void
    {
        var bloodBond :MovieClip = _panelMovie["blood_bond"];
        bloodBond.visible = false;
        if (ClientCtx.playerIds.length == 2 &&
            !ClientCtx.preyIsAi &&
            ClientCtx.bloodBondProgress > 0) {

            bloodBond.visible = true;
            bloodBond.gotoAndStop(1 +
                Math.min(ClientCtx.bloodBondProgress, VConstants.FEEDING_ROUNDS_TO_FORM_BLOODBOND));
        }
    }

    protected function onPropChanged (e :PropertyChangedEvent) :void
    {
        if (e.name == Props.ALL_PLAYERS) {
            updateButtonsAndStatus();
            updatePlayerList();
            updateBloodBondIndicator();
        } else if (e.name == Props.BLOOD_BOND_PROGRESS) {
            updateBloodBondIndicator();
        } else if (e.name == Props.LOBBY_LEADER || e.name == Props.PREY_ID) {
            updateButtonsAndStatus();
        }
    }

    protected function get isPostRoundLobby () :Boolean
    {
        return (_results != null);
    }

    protected function get isPreGameLobby () :Boolean
    {
        return (!isPostRoundLobby);
    }

    protected var _panelMovie :MovieClip;
    protected var _startButton :SimpleButton;
    protected var _tfStatus :TextField;
    protected var _playerList :SimpleListController;

    protected var _results :RoundOverMsg;
}

}
