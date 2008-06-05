package
{

import flash.events.Event;

import com.threerings.util.Assert;
import com.whirled.game.CoinsAwardedEvent;
import com.whirled.game.GameControl;
import com.whirled.game.GameSubControl;
import com.whirled.game.PropertyChangedEvent;
import com.whirled.game.MessageReceivedEvent;

import com.whirled.contrib.Scoreboard;

import flash.geom.Point;

/**
   GameModel is a game-specific interface to the networked data set.
   It contains accessors to get the list of players, scores, etc.
*/

public class Model
{
    //
    //
    // PUBLIC METHODS

    public function Model (gameCtrl :GameControl, display :Display) :void
    {
        // Squirrel the pointers away
        _gameCtrl = gameCtrl;
        _display = display;

        // Register for updates
        _gameCtrl.net.addEventListener(PropertyChangedEvent.PROPERTY_CHANGED, propertyChanged);
        
        // Initialize game data storage
        initializeStorage();

        _trophies = new Trophies(_gameCtrl);
    }

    public function handleUnload (event :Event) :void
    {
        _gameCtrl.net.removeEventListener(PropertyChangedEvent.PROPERTY_CHANGED, propertyChanged);
    }        
    
    public function get scoreboard () :Scoreboard
    {
        return _scoreboard;
    }

    /** Called at the beginning of a round - push my scoreboard on everyone. */
    public function roundStarted () :void
    {
        if (_gameCtrl.game.amInControl()) {
            _scoreboard.clearAll();
        }
    }

    public function endRound () :void
    {
        _trophies.handleRoundEnded(_scoreboard);

        if (!_gameCtrl.game.amInControl()) {
            return;
        }

        var playerIds :Array = [];
        var scores :Array = [];
        for each (var playerId :int in _gameCtrl.game.getOccupantIds()) {
            var score :int = _scoreboard.getScore(playerId);
            if (score > 0) {
                playerIds.push(playerId);
                scores.push(score);
            }
        }

        _gameCtrl.game.endGameWithScores(playerIds, scores, GameSubControl.PROPORTIONAL);
    }

    /** Called when the round ends - cleans up data, and awards flow! */
    public function roundEnded () :void
    {
        if (_gameCtrl.game.amInControl()) {
            for each (var i :String in _gameCtrl.net.getPropertyNames(Model.WORD_NAMESPACE)) {
                _gameCtrl.net.set(i, null);
            }
        }

        removeAllSelectedLetters();

        _display.roundEnded(this, _scoreboard);
    }

    //
    //
    // LETTER ACCESSORS

    /** If this board letter is already selected as part of the word, returns true.  */
    public function isLetterSelectedAtPosition (position :Point) :Boolean
    {
        var pointMatches :Function = function (item :Point, index :int, array :Array) :Boolean {
                return (item.equals(position));
            };

        return _word.some(pointMatches);
    }

    /** Returns coordinates of the most recently added word, or null. */
    public function getLastLetterPosition () :Point
    {
        if (_word.length > 0) {
            return _word[_word.length - 1] as Point;
        }

        return null;
    }

    /** Adds a new letter to the word (by adding a pair of coordinates) */
    public function selectLetterAtPosition (position :Point) :void
    {
        _word.push(position);
        _display.updateLetterSelection(_word);
    }

    /** Removes last selected letter from the word (if applicable) */
    public function removeLastSelectedLetter () :void
    {
        if (_word.length > 0) {
            _word.pop();
            _display.updateLetterSelection(_word);
        }
    }

    /** Removes all selected letters, resetting the word. */
    public function removeAllSelectedLetters () :void
    {
        _word = new Array();
        _display.updateLetterSelection(_word);
    }

    /** Checks if the word exists on the board, by doing an exhaustive
        search of all possible combinations. */
    public function wordExistsOnBoard (word :String) :Boolean
    {
        // TODO
        // return true;

        if (word.length == 0) return false;

        for (var x :int = 0; x < Properties.LETTERS; x++) {
            for (var y :int = 0; y < Properties.LETTERS; y++) {
                if (wordExists (word, 0, x, y, new Array())) {
                    return true;
                }
            }
        }

        return false;
    }

    protected function wordExists (
        word :String, start :Number, x :Number, y :Number, visited :Array) :Boolean
    {
        // recursion finished successfully.
        if (start >= word.length) return true;

        // if the letter doesn't match, fail.
        var l :String = _board[x][y];
        if (start + l.length > word.length || word.indexOf (l, start) != start) {
            return false;
        }

        // if we've seen it before, fail.
        for each (var p :Point in visited) {
            if (p.x == x && p.y == y) return false;
        }

        // finally, check all neighbors
        visited.push(new Point (x, y));
        for (var dx :int = -1; dx <= 1; dx++) {
            for (var dy :int = -1; dy <= 1; dy++) {
                var xx :int = x + dx;
                var yy :int = y + dy;
                if (xx >= 0 && xx < Properties.LETTERS && yy >= 0 && yy < Properties.LETTERS &&
                        wordExists(word, start + l.length, xx, yy, visited)) {
                    return true;
                }
            }
        }
        visited.pop();

        return false;
    }

    //
    //
    // SHARED DATA ACCESSORS

    /** Sends out a message to everyone, informing them about adding
     *  the new word to their lists. */
    public function addScore (word :String, score :Number, isvalid :Boolean) :void
    {
        var obj :Object = new Object();
        obj.playerId = _gameCtrl.game.getMyId(); 
        obj.word = word;
        obj.score = score;
        obj.isvalid = isvalid;

        // before updating the scoreboard, see if we need to award a trophy
        if (isvalid) {
            _trophies.handleAddWord(word, score, _scoreboard);
        }

        addWordToScoreboard(obj.playerId, obj.word, obj.score, obj.isvalid);

        // reset selection
        removeAllSelectedLetters();
    }

    /** Sends out a message to everyone, informing them about a new letter set.
     *  The array contains strings corresponding to the individual letters. */
    public function sendNewLetterSet (a :Array) :void
    {
        _gameCtrl.net.set(LETTER_SET, a);
    }

    /** Called only when joining an existing game, tells the model to update itself
     *  from the dobj, and by requesting whatever transient data is needed from peer in control. */
    public function updateFromExistingGame () :void
    {
        updateLettersOnBoard();
        //_gameCtrl.net.sendMessage (SCOREBOARD_REQUEST_MSG, _scoreboard.internalScoreObject);
    }

    
    //
    //
    // EVENT HANDLERS

    /** From PropertyChangedListener: deal with distributed game data changes */
    public function propertyChanged (event :PropertyChangedEvent) :void
    {
        if (event.name == LETTER_SET) {
            updateLettersOnBoard();
        }
    }

    //
    //
    // PRIVATE METHODS

    /** Re-reads letters from the shared object, and displays them on board. */
    private function updateLettersOnBoard () :void
    {
        var letters :Array = _gameCtrl.net.get(LETTER_SET) as Array;
        if (letters != null) {
            setGameBoard(letters);
        }
    }

    /** Resets the currently guessed word */
    private function resetWord () :void
    {
        _word = new Array();
    }

    /** Initializes letter and word storage */
    private function initializeStorage () :void
    {
        // First, the board
        _board = new Array(Properties.LETTERS);
        for (var x :int = 0; x < _board.length; x++) {
            _board[x] = new Array (Properties.LETTERS);
            for (var y :int = 0; y < _board[x].length; y++) {
                _board[x][y] = "!";
            }
        }

        // Second, the currently assembled word
        resetWord();

        // Third, make a new scoreboard
        _scoreboard = new Scoreboard(_gameCtrl);
    }

    /** Sets up a new game board, based on a flat array of letters. */
    private function setGameBoard (s :Array) :void
    {
        // Copy them over to the data set
        for (var x :int = 0; x < Properties.LETTERS; x++) {
            for (var y :int = 0; y < Properties.LETTERS; y++) {
                updateBoardLetter(new Point(x, y), s [x * Properties.LETTERS + y]);
            }
        }
    }

    /**
       Checks if the word is not in the scoreboard already, and if it isn't, adds it.
       If the word is not valid, prints out a message.
     */
    private function addWordToScoreboard (
        playerId :int, word :String, score :Number, isvalid :Boolean) :void
    {
        // if this message came in after the end of the round, just ignore it
        if (!_gameCtrl.game.isInPlay()) {
            return;
        }

        var playerName :String = _gameCtrl.game.getOccupantName(playerId);
        
        // if the word is invalid, display who tried to claim it
        if (! isvalid) {
            _display.logInvalidWord(playerName, word);
            return;
        }

        // if the word is valid and not claimed, score!
        if (! isWordClaimed (playerId, word)) {
            var bonus :Number = _gameCtrl.net.get(WORD_NAMESPACE+word) == null ?
                        Controller.FIRST_FINDER_BONUS : 0;

            _display.logSuccess(playerName, word, score, bonus);
            addWord(playerId, word, score + bonus);
            return;
        }

        // by this point, the word is valid and already claimed.
        // if this was my word, let me know.
        if (_gameCtrl.game.getMyId() == playerId) {
            _display.logAlreadyClaimed(playerName, word);
            return;
        }

        // the word was valid and already claimed, when another player tried to claim it.
        // just ignore.
    }

    /** Marks the /word/ as claimed, and adds the /score/ to the player's total. */
    public function addWord (playerId :int, word :String, score :Number) :void
    {
        //claimed[word] = playerId;
        var claims :Array = _gameCtrl.net.get(WORD_NAMESPACE+word) as Array || [ ];

        if (claims.indexOf(playerId) == -1) {
            claims.push(playerId);
        }
        _gameCtrl.net.set(WORD_NAMESPACE+word, claims);

        _scoreboard.addToScore(playerId, score);
    }

    /** If this word was already claimed by the given player, returns true; otherwise false. */
    public function isWordClaimed (playerId :int, word :String) :Boolean
    {
        var claim :Array = _gameCtrl.net.get(WORD_NAMESPACE+word) as Array || [ ];

        return claim.indexOf(playerId) != -1;
    }

    /** Pick all the words that have currently been found. */
    public function getWords () :Array
    {
        var words :Array = new Array();
        var props :Array = _gameCtrl.net.getPropertyNames(WORD_NAMESPACE) || [ ];

        for each (var i :String in props) {
            var word :String = i.substring(WORD_NAMESPACE.length);
            words.push({
                word: word,
                score: Controller.getWordScore(word),
                playerIds: _gameCtrl.net.get(i)
            });
        }

        return words;
    }
    /**
     * Retrieves top n words from the scored word list, and returns them as an array
     * of objects with the following fields: { word :String, score :int, playerId :int }.
     */
    //public function getTopWords (count :int) :Array /** of Object */
    /*{
        var words :Array = new Array();
        var props :Array = _gameCtrl.net.getPropertyNames(WORD_NAMESPACE) || [ ];

        for each (var i :String in props) {
            var word :String = i.substring(WORD_NAMESPACE.length);
            words.push({
                word: word,
                score: Controller.getWordScore(word),
                playerIds: _gameCtrl.net.get(i)
            });
        }
            
        words.sortOn("score", Array.DESCENDING | Array.NUMERIC);
        return words.slice(0, count);
    };*/

    /** Updates a single letter at specified /position/ to display a new /text/.  */
    private function updateBoardLetter (position :Point, text :String) :void
    {
        Assert.isNotNull(_board, "Board needs to be initialized first.");
        _board[position.x][position.y] = text;
        _display.setLetter(position, text);
    }

    /** Converts player id to name. */
    public function getName (playerId :int, ... ignored) :String
    {
        return _gameCtrl.game.getOccupantName(playerId);
    }


    // TODO: Reorder all this, remove useless comments

    //
    //
    // PRIVATE CONSTANTS

    /** Message types */
    private static const LETTER_SET :String = "Letter Set Update";
    private static const ADD_SCORE_MSG :String = "Score Update";
    private static const SCOREBOARD_UPDATE_MSG :String = "Scoreboard Update";
    private static const SCOREBOARD_REQUEST_MSG :String = "Scoreboard Request";

    protected static const WORD_NAMESPACE :String = "word:";

    //
    //
    // PRIVATE VARIABLES

    /** Main game control structure */
    private var _gameCtrl :GameControl;

    /** Cache the player's name */
    private var _playerName :String;

    /** Game board data */
    private var _board :Array;

    /** Current word data (as array of board coordinates) */
    private var _word :Array;

    /** Game board view */
    private var _display :Display;

    /** List of players and their scores */
    private var _scoreboard :Scoreboard;

    /** Trophy manager. */
    private var _trophies :Trophies;
}
}
