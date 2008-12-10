package redrover.game {

import com.threerings.flash.Vector2;
import com.threerings.util.ArrayUtil;
import com.whirled.contrib.simplegame.SimObject;
import com.whirled.contrib.simplegame.tasks.*;

import redrover.*;
import redrover.data.LevelData;

public class Player extends SimObject
{
    public static const STATE_NORMAL :int = 0;
    public static const STATE_SWITCHINGBOARDS :int = 1;
    public static const STATE_EATEN :int = 2;

    public function Player (playerIndex :int, playerName :String, teamId :int, gridX :int,
        gridY :int, color :uint)
    {
        _playerIndex = playerIndex;
        _playerName = playerName;
        _teamId = teamId;
        _curBoardId = teamId;
        _color = color;
        _state = STATE_NORMAL;

        _cellSize = GameContext.levelData.cellSize;

        var cell :BoardCell = GameContext.gameMode.getBoard(teamId).getCell(gridX, gridY);
        _loc.x = cell.ctrPixelX;
        _loc.y = cell.ctrPixelY;
    }

    public function eatPlayer (player :Player) :void
    {
        dispatchEvent(GameEvent.createAtePlayer(this, player));
        player.beginGetEaten(this);

        // we get the other player's gems
        addGems(player._gems);
        player.clearGems();
    }

    protected function beginGetEaten (byPlayer :Player) :void
    {
        // if we were trying to switch boards, stop
        removeNamedTasks(SWITCH_BOARDS_TASK_NAME);

        _teamId = byPlayer.teamId; // switch teams

        // we get spat out behind the other player, if possible
        var spitLocations :Array;
        var gridX :int = byPlayer.gridX;
        var gridY :int = byPlayer.gridY;
        var north :Vector2 = new Vector2(gridX, gridY - 1);
        var south :Vector2 = new Vector2(gridX, gridY + 1);
        var east :Vector2 = new Vector2(gridX + 1, gridY);
        var west :Vector2 = new Vector2(gridX - 1, gridY);
        switch (byPlayer.moveDirection) {
        case Constants.DIR_NORTH:
            spitLocations = [ south, east, west, north ];
            break;

        case Constants.DIR_SOUTH:
            spitLocations = [ north, west, east, south ];
            break;

        case Constants.DIR_EAST:
            spitLocations = [ west, south, north, east ];
            break;

        case Constants.DIR_WEST:
        default:
            spitLocations = [ east, north, south, west ];
            break;
        }

        var board :Board = byPlayer.curBoard;
        var newLoc :Vector2;
        for each (var loc :Vector2 in spitLocations) {
            var cell :BoardCell = board.getCell(loc.x, loc.y);
            if (cell != null && !cell.isObstacle) {
                newLoc = loc;
                break;
            }
        }

        if (newLoc == null) {
            newLoc = new Vector2(gridX, gridY);
        }

        _loc.x = (newLoc.x + 0.5) * GameContext.levelData.cellSize;
        _loc.y = (newLoc.y + 0.5) * GameContext.levelData.cellSize;

        // we're dazed for a little while
        _state = STATE_EATEN;
        addNamedTask(GOT_EATEN_TASK_NAME,
            After(GameContext.levelData.gotEatenTime,
                new FunctionTask(function () :void {
                    _state = STATE_NORMAL;
                })));

        dispatchEvent(GameEvent.createWasEaten(byPlayer, this));
    }

    public function beginSwitchBoards () :void
    {
        if (!this.canSwitchBoards) {
            return;
        }

        _state = STATE_SWITCHINGBOARDS;
        addNamedTask(SWITCH_BOARDS_TASK_NAME,
            After(GameContext.levelData.switchBoardsTime,
                new FunctionTask(switchBoards)));
    }

    public function move (direction :int) :void
    {
        _scheduledTurns = [ new PlayerMove(direction) ];
    }

    public function scheduleMoves (moves :Array) :void
    {
        _scheduledTurns = moves;
    }

    public function moveTo (gridX :int, gridY :int) :void
    {
        var dx :Number = gridX - this.gridX;
        var dy :Number = gridY - this.gridY;

        var dirX :int = Constants.getDirection(dx, 0);
        var dirY :int = Constants.getDirection(0, dy);

        if (dx != 0 && dy == 0) {
            move(dirX);

        } else if (dx == 0 && dy != 0) {
            move(dirY);

        } else if (dx != 0 && dy != 0) {
            if (Math.abs(dx) < Math.abs(dy)) {
                scheduleMoves([
                    new PlayerMove(dirX),
                    new PlayerMove(dirY, gridX, this.gridY)
                ]);

            } else {
                scheduleMoves([
                    new PlayerMove(dirY),
                    new PlayerMove(dirX, this.gridX, gridY)
                ]);
            }
        }
    }

    public function addGem (gemType :int) :void
    {
        _gems.push(gemType);
        _gemCounts[gemType] += 1;
    }

    public function addGems (gems :Array) :void
    {
        for each (var gemType :int in gems) {
            addGem(gemType);
        }
    }

    public function clearGems () :void
    {
        _gems = [];
        for (var ii :int = 0; ii < _gemCounts.length; ++ii) {
            _gemCounts[ii] = 0;
        }
    }

    public function get canSwitchBoards () :Boolean
    {
        return (_state != STATE_SWITCHINGBOARDS &&
            (_teamId == _curBoardId || this.numGems >= GameContext.levelData.returnHomeGemsMin));
    }

    public function get playerIndex () :int
    {
        return _playerIndex;
    }

    public function get isLocalPlayer () :Boolean
    {
        return _playerIndex == GameContext.localPlayerIndex;
    }

    public function get playerName () :String
    {
        return _playerName;
    }

    public function get teamId () :int
    {
        return _teamId;
    }

    public function get curBoardId () :int
    {
        return _curBoardId;
    }

    public function get curBoard () :Board
    {
        return GameContext.gameMode.getBoard(_curBoardId);
    }

    public function get isOnOwnBoard () :Boolean
    {
        return _teamId == _curBoardId;
    }

    public function get color () :uint
    {
        return _color;
    }

    public function get loc () :Vector2
    {
        return _loc;
    }

    public function get state () :int
    {
        return _state;
    }

    public function get score () :int
    {
        return _score;
    }

    public function get moveSpeed () :Number
    {
        var data :LevelData = GameContext.levelData;
        var speedBase :Number =
            (this.isOnOwnBoard ? data.ownBoardSpeedBase : data.otherBoardSpeedBase);
        return speedBase + (this.numGems * data.speedOffsetPerGem);
    }

    public function get gridX () :int
    {
        return _loc.x / _cellSize;
    }

    public function get gridY () :int
    {
        return _loc.y / _cellSize;
    }

    public function get curBoardCell () :BoardCell
    {
        return GameContext.getCellAt(_curBoardId, this.gridX, this.gridY);
    }

    public function get numGems () :int
    {
        return _gems.length;
    }

    public function get gems () :Array
    {
        return _gems;
    }

    public function get moveDirection () :int
    {
        return _moveDirection;
    }

    public function get isMoving () :Boolean
    {
        return _isMoving;
    }

    public function get canMove () :Boolean
    {
        return _state != STATE_SWITCHINGBOARDS && _state != STATE_EATEN;
    }

    public function isGemValidForPickup (gemType :int) :Boolean
    {
        if (this.numGems == 0) {
            return true;
        }

        // Can't pick up the same gem twice in a row
        var lastGem :int = _gems[_gems.length - 1];
        if (lastGem == gemType) {
            return false;
        }

        // Can't have 2 more gems of any type than you have gems of the other types
        var thisGemCount :int = _gemCounts[gemType];
        for (var otherGemType :int = 0; otherGemType < _gemCounts.length; ++otherGemType) {
            if (gemType != otherGemType && thisGemCount > _gemCounts[otherGemType]) {
                return false;
            }
        }

        return true;
    }

    override protected function update (dt :Number) :void
    {
        super.update(dt);

        var startX :Number = _loc.x;
        var startY :Number = _loc.y;

        if (this.canMove) {
            handleNextMove(this.moveSpeed * dt);

            var cell :BoardCell = this.curBoardCell;
            // If we're on the other team's board, pickup gems when we enter their cells
            if (!this.isOnOwnBoard && this.numGems < GameContext.levelData.maxCarriedGems &&
                cell.hasGem && isGemValidForPickup(cell.gemType)) {
                addGem(cell.takeGem());
            }

            // If we're on our board, redeem our gems when we touch a gem redemption tile
            if (this.isOnOwnBoard && this.numGems > 0 && cell.isGemRedemption) {
                redeemGems(cell);
            }
        }

        _isMoving = (_loc.x != startX || _loc.y != startY);
    }

    protected function handleNextMove (moveDist :Number) :void
    {
        if (_scheduledTurns.length == 0) {
            // We have no scheduled moves
            if (_moveDirection >= 0) {
                handleMoveInDirection(moveDist, _moveDirection);
            }

            return;
        }

        var turn :PlayerMove = _scheduledTurns[0];
        var canTurn :Boolean;

        if (_moveDirection < 0) {
            canTurn = true;

        } else {
            var attemptTurn :Boolean;
            var prevIsec :Number;
            var nextIsec :Number;

            if (turn.doAsap) {
                if (Constants.isParallel(_moveDirection, turn.direction)) {
                    // we can always switch direction along the same axis
                    canTurn = true;
                } else {
                    prevIsec = getPrevCellIntersection(_moveDirection);
                    nextIsec = getNextCellIntersection(_moveDirection);
                    attemptTurn = true;
                }

            } else if (this.gridY == turn.atGridY && Constants.isHoriz(_moveDirection)) {
                nextIsec = prevIsec = turn.atPixelX;
                attemptTurn = true;

            } else if (this.gridX == turn.atGridX && Constants.isVert(_moveDirection)) {
                nextIsec = prevIsec = turn.atPixelY;
                attemptTurn = true;
            }

            if (attemptTurn) {
                var oldX :Number = _loc.x;
                var oldY :Number = _loc.y;
                canTurn = tryTurn(moveDist, turn.direction, prevIsec, nextIsec);
                moveDist -= (Math.abs(_loc.x - oldX) + Math.abs(_loc.y - oldY));
            }
        }

        if (canTurn) {
            _moveDirection = turn.direction;
            _scheduledTurns.shift();

            handleNextMove(moveDist);
            return;

        } else if (_moveDirection != -1 && moveDist > 0) {
            handleMoveInDirection(moveDist, _moveDirection);
        }
    }

    protected function tryTurn (moveDist :Number, turnDirection :int, prevIsec :Number,
        nextIsec :Number) :Boolean
    {
        var maxTurnOvershoot :Number = GameContext.levelData.maxTurnOvershoot;
        var moveDir :Vector2 = Constants.DIRECTION_VECTORS[_moveDirection];
        var canTurn :Boolean;

        // If we've just overshot our turn, and we're allowed to enter the cell
        // we'd like to turn towards, allow the turn anyway
        if (moveDir.x != 0 &&
            Math.abs(prevIsec - _loc.x) <= maxTurnOvershoot &&
            canMoveTowards(prevIsec, _loc.y, turnDirection)) {

            moveDist -= Math.min(moveDist, Math.abs(prevIsec - _loc.x));
            _loc.x = prevIsec;
            canTurn = true;

        } else if (moveDir.y != 0 &&
                   Math.abs(prevIsec - _loc.y) <= maxTurnOvershoot &&
                   canMoveTowards(_loc.x, prevIsec, turnDirection)) {

            moveDist -= Math.min(moveDist, Math.abs(prevIsec - _loc.y));
            _loc.y = prevIsec;
            canTurn = true;

        } else {
            // Otherwise, allow the turn once we reach our next intersection
            if (moveDir.x != 0 &&
                Math.abs(nextIsec - _loc.x) <= moveDist &&
                canMoveTowards(nextIsec, _loc.y, turnDirection)) {

                moveDist -= Math.abs(nextIsec - _loc.x);
                _loc.x = nextIsec;
                canTurn = true;

            } else if (moveDir.y != 0 &&
                       Math.abs(nextIsec - _loc.y) <= moveDist &&
                       canMoveTowards(_loc.x, nextIsec, turnDirection)) {

               moveDist -= Math.abs(nextIsec - _loc.y);
               _loc.y = nextIsec;
               canTurn = true;
            }
        }

        return canTurn;
    }

    protected function handleMoveInDirection (dist :Number, direction :int) :Number
    {
        var dir :Vector2 = Constants.DIRECTION_VECTORS[direction];
        var oldX :Number = _loc.x;
        var oldY :Number = _loc.y;
        tryMoveTo(_loc.x + (dir.x * dist), _loc.y + (dir.y * dist));

        return dist - (Math.abs(_loc.x - oldX) + Math.abs(_loc.y - oldY));
    }

    protected function getNextCellIntersection (moveDirection :int) :Number
    {
        var halfCell :int = _cellSize * 0.5;
        var dir :Vector2 = Constants.DIRECTION_VECTORS[moveDirection];
        if (dir.x > 0) {
            return (Math.floor((_loc.x + halfCell) / _cellSize) * _cellSize) + halfCell;
        } else if (dir.x < 0) {
            return (Math.floor((_loc.x - halfCell) / _cellSize) * _cellSize) + halfCell;
        } else if (dir.y > 0) {
            return (Math.floor((_loc.y + halfCell) / _cellSize) * _cellSize) + halfCell;
        } else {
            return (Math.floor((_loc.y - halfCell) / _cellSize) * _cellSize) + halfCell;
        }
    }

    protected function getPrevCellIntersection (moveDirection :int) :Number
    {
        switch (moveDirection) {
        case Constants.DIR_EAST: return getNextCellIntersection(Constants.DIR_WEST);
        case Constants.DIR_WEST: return getNextCellIntersection(Constants.DIR_EAST);
        case Constants.DIR_NORTH: return getNextCellIntersection(Constants.DIR_SOUTH);
        case Constants.DIR_SOUTH: return getNextCellIntersection(Constants.DIR_NORTH);
        default: throw new Error("Unrecognized direction: " + moveDirection);
        }
    }

    protected function canMoveTowards (fromX :Number, fromY :Number, moveDirection :int) :Boolean
    {
        var nextCell :BoardCell;
        var board :Board = GameContext.gameMode.getBoard(_curBoardId);
        switch (moveDirection) {
        case Constants.DIR_EAST:
            nextCell = board.getCellAtPixel(fromX + _cellSize, fromY);
            break;

        case Constants.DIR_WEST:
            nextCell = board.getCellAtPixel(fromX - _cellSize, fromY);
            break;

        case Constants.DIR_NORTH:
            nextCell = board.getCellAtPixel(fromX, fromY - _cellSize);
            break;

        case Constants.DIR_SOUTH:
            nextCell = board.getCellAtPixel(fromX, fromY + _cellSize);
            break;
        }

        return (nextCell != null && !nextCell.isObstacle);
    }

    protected function tryMoveTo (xNew :Number, yNew :Number) :void
    {
        // Tries to move the player to the new location. Clamps the move if a collision occurs.
        // Don't collide into tiles
        var board :Board = GameContext.gameMode.getBoard(_curBoardId);
        var nextCell :BoardCell;
        var xOffset :Number = xNew - _loc.x;
        var yOffset :Number = yNew - _loc.y;
        var halfCell :int = _cellSize * 0.5;
        var gx :int;
        var gy :int;
        if (xOffset > 0) {
            gx = board.pixelToGrid(_loc.x + xOffset + halfCell + 1);
            gy = board.pixelToGrid(_loc.y);
            nextCell = board.getCell(gx, gy);
            if (nextCell == null || nextCell.isObstacle) {
                xNew = ((gx - 1) * _cellSize) + halfCell;
            }

        } else if (xOffset < 0) {
            gx = board.pixelToGrid(_loc.x + xOffset - halfCell);
            gy = board.pixelToGrid(_loc.y);
            nextCell = board.getCell(gx, gy);
            if (nextCell == null || nextCell.isObstacle) {
                xNew = ((gx + 1) * _cellSize) + halfCell;
            }

        } else if (yOffset > 0) {
            gx = board.pixelToGrid(_loc.x);
            gy = board.pixelToGrid(_loc.y + yOffset + halfCell + 1);
            nextCell = board.getCell(gx, gy);
            if (nextCell == null || nextCell.isObstacle) {
                yNew = ((gy - 1) * _cellSize) + halfCell;
            }

        } else if (yOffset < 0) {
            gx = board.pixelToGrid(_loc.x);
            gy = board.pixelToGrid(_loc.y + yOffset - halfCell);
            nextCell = board.getCell(gx, gy);
            if (nextCell == null || nextCell.isObstacle) {
                yNew = ((gy + 1) * _cellSize) + halfCell;
            }
        }

        _loc.x = xNew;
        _loc.y = yNew;
    }

    protected function redeemGems (cell :BoardCell) :void
    {
        _score += GameContext.levelData.gemValues.getValueAt(this.numGems);
        dispatchEvent(GameEvent.createGemsRedeemed(this, _gems, cell));
        clearGems();
    }

    protected function switchBoards () :void
    {
        _state = STATE_NORMAL;
        _curBoardId = Constants.getOtherTeam(_curBoardId);
    }

    protected var _playerIndex :int;
    protected var _playerName :String;
    protected var _teamId :int;
    protected var _curBoardId :int;
    protected var _gems :Array = [];
    protected var _gemCounts :Array = ArrayUtil.create(Constants.GEM__LIMIT, 0);
    protected var _score :int;
    protected var _moveDirection :int = -1;
    protected var _scheduledTurns :Array = [];
    protected var _loc :Vector2 = new Vector2();
    protected var _state :int;
    protected var _color :uint;
    protected var _isMoving :Boolean;

    protected var _cellSize :int; // we access this value all the time

    protected static const SWITCH_BOARDS_TASK_NAME :String = "SwitchBoards";
    protected static const GOT_EATEN_TASK_NAME :String = "GotEaten";
}

}
