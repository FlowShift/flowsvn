package joingame.view
{
    import com.threerings.util.ArrayUtil;
    import com.threerings.util.HashMap;
    import com.threerings.util.Random;
    import com.whirled.contrib.simplegame.*;
    import com.whirled.contrib.simplegame.audio.*;
    import com.whirled.contrib.simplegame.objects.*;
    import com.whirled.contrib.simplegame.resource.*;
    import com.whirled.contrib.simplegame.tasks.*;
    import com.whirled.contrib.simplegame.util.*;
    import com.whirled.game.GameControl;
    
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    
    import joingame.*;
    import joingame.model.*;
    import joingame.net.JoinGameEvent;
    
    /**
     * Draws the boards, and creates the animations of board pieces
     * via events from JoinGameModel.
     */
    public class JoinGameBoardsView extends SceneObject
    {
        public function JoinGameBoardsView(joinGameModel :JoinGameModel, gameControl :GameControl, observerState :Boolean = false)
        {
            AppContext.LOG("\nJoinGameBoardsView");
            if (joinGameModel == null || gameControl == null){
                throw new Error("JoinGameBoardsView Problem!!! JoinGameModel or GameControl should not be null");
            }
            _observer = observerState;
            _id2Board = new HashMap();
            
//            var swf :SwfResource = (ResourceManager.instance.getResource("puzzlePieces") as SwfResource);
//            _piece_break_eastwardClass = swf.getClass("piece_break_eastward");
//            _piece_break_westwardClass = swf.getClass("piece_break_westward");
            
            
//            var bg :ImageResource = (ResourceManager.instance.getResource("puzzlePieces") as ImageResource);
              _sprite = new Sprite();
            
            
//            _sprite.y = gameControl.local.getSize().y - Constants.PUZZLE_HEIGHT;
//            _sprite.graphics.beginFill(0.5);
//            _sprite.graphics.drawRect(2,2,30,30);
//            _sprite.graphics.endFill();
//            _sprite.mouseEnabled = true;
            
            
//             var imageLoader:Loader = new Loader();
//             var theURL:String = "rsrc/thePic.jpg";
//             var imageRequest = new URLRequest(theURL);
//        
//             imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
//        
//             imageLoader.load(imageRequest);
//        
//             function onComplete(evt:Event) {
//        
//                  addChild(imageLoader.content);
//        
//             }

            
            
            
            
            
            
            _gameModel = joinGameModel; //new JoinGameModel(_gameControl);
            _gameControl = gameControl;
            
            
            _gameModel.addEventListener(JoinGameEvent.PLAYER_KNOCKED_OUT, playerKnockedOut);
            _gameModel.addEventListener(JoinGameEvent.RECEIVED_BOARDS_FROM_SERVER, updateBoardDisplays);
//            _gameModel.addEventListener(JoinGameEvent.DO_JOIN_VISUALIZATIONS, doJoinVisualizations);
            _gameModel.addEventListener(JoinGameEvent.DELTA_CONFIRM, deltaConfirm);
            _gameModel.addEventListener(JoinGameEvent.DO_PIECES_FALL, doPiecesFall);
            _gameModel.addEventListener(JoinGameEvent.ADD_NEW_PIECES, addNewPieces);
            _gameModel.addEventListener(JoinGameEvent.VERTICAL_JOIN, doVerticalJoins);
            _gameModel.addEventListener(JoinGameEvent.ATTACKING_JOINS, doHorizontalAttack);
            _gameModel.addEventListener(JoinGameEvent.BOARD_UPDATED, boardUpdated);
            _gameModel.addEventListener(JoinGameEvent.DO_DEAD_PIECES, doDeadPieces);
            _gameModel.addEventListener(JoinGameEvent.REMOVE_ROW_PIECES, doRemoveRowPieces);
            _gameModel.addEventListener(JoinGameEvent.REMOVE_BOTTOM_ROW_AND_DROP_PIECES, removeBottomRowAndDropPieces);
            _gameModel.addEventListener(JoinGameEvent.RESET_VIEW_FROM_MODEL, resetViewFromModel);
            
            if(_observer) {//create the boards
                
            }
            
        }
        
        
        protected function resetViewFromModel( e :JoinGameEvent) :void
        {
            var board :JoinGameBoardGameArea = getBoardView( e.boardPlayerID );
            if( board != null) {
                board.resetPositionOfPieces()
            }
        }
        protected function removeBottomRowAndDropPieces( e :JoinGameEvent) :void
        {
            
            adjustZoomOfPlayAreaBasedOnCurrentPlayersBoard();
            
            var board :JoinGameBoardGameArea = getBoardView( e.boardPlayerID );
            var piece :JoinGamePiece;
            var k :int;
//            AppContext.LOG("model removeBottomRowAndDropPieces() model before: " + board._boardRepresentation);
//            AppContext.LOG("view removeBottomRowAndDropPieces() board before: " + board);
            
            if( board != null) {
                
                for( var i :int = 0; i < board._cols; i++) {
                    piece = board.getPieceAt(i, board._rows - 1) as JoinGamePiece;
                    if(piece != null){
                        
                        board._boardPieces[ board.coordsToIdx(i, board._rows - 1) ] = null;
                        piece.boardIndex = -1;//Test
                        piece.destroySelf();
                        
                        var newPiece :JoinGamePiece = new JoinGamePiece();
                        newPiece.scaleX = board._sprite.scaleX;
                        newPiece.scaleY = board._sprite.scaleY;
                        newPiece.color = piece.color;
                        newPiece.type = piece.type
                        newPiece.x = board.x + piece.x * board._sprite.scaleX;
                        newPiece.y = board.y + piece.y * board._sprite.scaleY;
                        db.addObject( newPiece, _sprite);
                        
                        //                        piece.addTask(LocationTask.CreateEaseOut(
                        var pieceAnim :SerialTask = new SerialTask();
                        pieceAnim.addTask(ScaleTask.CreateEaseOut(0.3, 0.3, Constants.PIECE_SCALE_DOWN_TIME));
                        pieceAnim.addTask(new SelfDestructTask());
                        newPiece.addTask(pieceAnim);
                        
                        
                        
                    }
                }
                board._boardPieces.splice((board._rows - 1)*board._cols, board._cols);
                board._rows--;
                
                
                
                
                for( k = 0; k < board._boardPieces.length; k++) {
                    piece = board._boardPieces[k] as JoinGamePiece;
                    if(piece != null){
                        piece.boardIndex = k;
                    }
                }
                
                for( k = 0; k < board._boardPieces.length; k++) {
                    piece = board._boardPieces[k] as JoinGamePiece;
                    if(piece != null){
                        var toX :Number = board.getPieceXLoc( board.idxToX(k));
                        var toY :Number = board.getPieceYLoc( board.idxToY(k));
                    
                        piece.addNamedTask(MOVE_TASK_NAME,
                        LocationTask.CreateEaseIn(toX, toY, Constants.PIECE_DROP_TIME), true);
                    }
                }
                
                for( k = 0; k < board._boardPieces.length; k++) {
                    piece = board._boardPieces[k] as JoinGamePiece;
                    if(piece == null){
                        board.addPieceAtPosition( board._boardRepresentation.idxToX(k), board._boardRepresentation.idxToY(k), Constants.PIECE_TYPE_INACTIVE, 1);
                    }
                }
                
                board.removeAndAddDisplayChildren();
                
                    //Drop the board
                toY = (AppContext.gameHeight - board.height - Constants.GUI_BOARD_FLOOR_GAP) + Constants.PUZZLE_TILE_SIZE*board._sprite.scaleX;
//                toY = board.y + Constants.PUZZLE_TILE_SIZE*board._sprite.scaleX;
                
                var taskAnimation :SerialTask= new SerialTask();
                taskAnimation.addTask( new TimedTask(0) );
                taskAnimation.addTask( LocationTask.CreateEaseIn(board.x, toY + Constants.DISTANCE_OVER_TARGET_DROPPED_PIECES_FALL, Constants.PIECE_DROP_TIME) );
                taskAnimation.addTask( new TimedTask(Constants.PIECE_DROP_BOUNCE1_TIME) );
                taskAnimation.addTask( LocationTask.CreateEaseIn(board.x, toY - Constants.DISTANCE_OVER_TARGET_DROPPED_PIECES_FALL/2, Constants.PIECE_DROP_BOUNCE1_TIME) );
                taskAnimation.addTask( LocationTask.CreateEaseIn(board.x, toY, Constants.PIECE_DROP_BOUNCE1_TIME * 0.7));
                    
                board.addNamedTask(MOVE_TASK_NAME, taskAnimation, true); 
                
                
                
                doGraphicsAndAnimationForDeadBottomRow(board);  //Doesn't work WTF!!!!
                
//                adjustZoomOfPlayAreaBasedOnCurrentPlayersBoard();
                
                
                
//                board.updateYBasedOnBoardHeight();                
            }
            else {
                AppContext.LOG("!!!!!deleteRow(" + e.boardPlayerID + ") board is null");
            }
            
//            AppContext.LOG("view removeBottomRowAndDropPieces() board after: " + board);
                    
        }
        

        
        
        protected function doRemoveRowPieces( e :JoinGameEvent ) :void
        {
            var board :JoinGameBoardGameArea = getBoardView( e.boardPlayerID );
            if( board != null) {
//                AppContext.LOG("view doRemoveRowPieces() before: " + board);
                var row :int = e.row;
                for( var i :int = 0; i < board._cols; i++) {
                    var piece :JoinGamePiece = board.getPieceAt( i, row) as JoinGamePiece;
                    if(piece == null){/* If it's part of another join, it may already be removed */
                        continue;
                    }
                    var pieceAnim :SerialTask = new SerialTask();
                    pieceAnim.addTask(ScaleTask.CreateEaseOut(0.3, 0.3, Constants.PIECE_SCALE_DOWN_TIME));
                    pieceAnim.addTask(new SelfDestructTask());
                    piece.addTask(pieceAnim);
                    board._boardPieces[ board.coordsToIdx(i, row) ] = null;
                    piece.boardIndex = -1;//Test
                     
                    if( ArrayUtil.contains( board._boardPieces, piece) ){
                        AppContext.LOG("!!!doJoinVisualizations(), " + piece + " should be removed, but it's still there WTF? at index="+ ArrayUtil.indexOf(board._boardPieces, piece) );
                    }
                }
//                AppContext.LOG("view doRemoveRowPieces() after: " + board);
            }
            else {
                AppContext.LOG("!!!!!doRemoveRowPieces(" + e.boardPlayerID + ") board is null");
            }
        }
        
        protected function doDeadPieces( e :JoinGameEvent ) :void
        {
            var board :JoinGameBoardGameArea = getBoardView( e.boardPlayerID );
            if( board != null){
                
                doGraphicsAndAnimationForDeadBottomRow(board);                
            }
        }
        
        
        public function doGraphicsAndAnimationForDeadBottomRow( board :JoinGameBoardGameArea) :void
        {
            if( board != null){
                
                for( var k :int = 0; k < board._boardPieces.length; k++){
                    if( board._boardRepresentation._boardPieceTypes[k] == Constants.PIECE_TYPE_POTENTIALLY_DEAD){
                        (board._boardPieces[k] as JoinGamePiece).type = Constants.PIECE_TYPE_POTENTIALLY_DEAD;
                        (board._boardPieces[k] as JoinGamePiece).removeNamedTasks(WOBBL_TASK_NAME);
                    }
                }
                
                var isDeadBottomRow :Boolean = true;
                var i :int;
                var piece :JoinGamePiece;
                
                for(i = 0; i < board._cols; i++) {
                    piece = board.getPieceAt( i, board._rows - 1);
                    if(piece != null && piece.type == Constants.PIECE_TYPE_NORMAL) {
                        isDeadBottomRow = false;
                        break;
                    }
                }
                if(isDeadBottomRow) {
                    AppContext.LOG("animating bottom wobble");
                    for(i = 0; i < board._cols; i++) {
                        piece = board.getPieceAt( i, board._rows - 1);
                        if(piece != null && piece.type != Constants.PIECE_TYPE_INACTIVE) {
                            
//                            var serialAnimation :SerialTask = new SerialTask(); 
//                            serialAnimation.addTask( LocationTask.CreateEaseIn(piece.x - 2, piece.y, 0.05) );
//                            serialAnimation.addTask( LocationTask.CreateEaseIn(piece.x + 2, piece.y, 0.1) );
//                            serialAnimation.addTask( LocationTask.CreateEaseIn(piece.x, piece.y, 0.05) );
//                            var taskAnimation :RepeatingTask = new RepeatingTask(serialAnimation);
//                            piece.addNamedTask(WOBBL_TASK_NAME, taskAnimation);  
                        }
                    }
                }
                
            }
        }
        
        protected function boardUpdated( e :JoinGameEvent ) :void
        {
//            AppContext.LOG("JoinGameBoardsView.boardUpdated, this should only be called in an emergency");
            getBoardView(e.boardPlayerID).updatePieceDimensionsAndCoordinatesAndAddPiecesIfNecessaryOLD();
        }
        
        /**
        * The returned piece is scaled and positioned relative to the board
        * 
        */
        protected function createPieceFromBoard( board :JoinGameBoardGameArea, i :int, j :int) :JoinGamePiece
        {
            var newPiece :JoinGamePiece = new JoinGamePiece();
            newPiece.scaleX = board._sprite.scaleX;
            newPiece.scaleY = board._sprite.scaleY;
            newPiece.x = board.x + board.getPieceXLoc(i) * board._sprite.scaleX;
            newPiece.y = board.y + board.getPieceYLoc(j) * board._sprite.scaleY;
            newPiece.size = Constants.PUZZLE_TILE_SIZE * board._sprite.scaleX;
            return newPiece;
        }
        
        protected function doHorizontalAttack( e :JoinGameEvent ) :void
        {
//            AppContext.LOG("\n\ndoHorizontalAttack(), e.boardAttacked=" + e.boardAttacked + ", boardPlayerID=" + e.boardPlayerID + " on defenders " + (e.side == Constants.LEFT ? " left" : "right, active players=" + _gameModel.currentSeatingOrder));
            var boardAttacked :JoinGameBoardGameArea = getBoardView( e.boardAttacked );
            var sourceboard :JoinGameBoardGameArea = getBoardView( e.boardPlayerID );
//            AppContext.LOG("board attacked.x=" + boardAttacked.x);
//            AppContext.LOG("source board.x=" + sourceboard.x);
//            AppContext.LOG("view doHorizontalAttack() board before:\n" + boardAttacked);
            
            var i :int;
            var k :int;
            var piece :JoinGamePiece;
            var join :JoinGameJoin = e.joins[0] as JoinGameJoin;
            
            /* Determine the animation coords */
            var toX :int;//Relative to the attacking board, not this parent class
            var toY :int;

            
            if( boardAttacked != null && sourceboard != null) {
                var rowIndex :int = boardAttacked._rows - 1 - join.attackRow;
                var alreadyDamagedOffset :int = 0;
                if(e.side == Constants.LEFT) {//This means its attacking the target's left

                    toX = boardAttacked.x - sourceboard.x;
                    
                    
                    
//                    AppContext.LOG("attack to opponents LEFT, toX=" + toX);
//                    for( i = 0; i < boardAttacked._cols; i++){
//                        if(  boardAttacked.getPieceAt( i, rowIndex) != null && ( boardAttacked.getPieceAt( i, rowIndex).type == Constants.PIECE_TYPE_NORMAL || boardAttacked.getPieceAt( i, rowIndex).type == Constants.PIECE_TYPE_POTENTIALLY_DEAD)) {
//                            break;
//                        }
//                        else {
//                            alreadyDamagedOffset++;
//                        }
//                    }
//                    
//                    toX += (alreadyDamagedOffset + 0) * Constants.PUZZLE_TILE_SIZE;
//                    AppContext.LOG("attack to opponents LEFT, toX=" + toX);
                }
                else {
//                    toX = boardAttacked.x + boardAttacked.width;
                    toX = boardAttacked.x + boardAttacked.width * boardAttacked.scaleX  - sourceboard.x;
//                    AppContext.LOG("attack to opponents RIGHT, toX=" + toX + ", from boardAttacked.x (" + boardAttacked.x + ") + boardAttacked.width (" + boardAttacked.width + ")");
//                    for( i = boardAttacked._cols - 1; i >= 0; i--){
//                        if( boardAttacked.getPieceAt( i, rowIndex) != null && (boardAttacked.getPieceAt( i, rowIndex).type == Constants.PIECE_TYPE_NORMAL || boardAttacked.getPieceAt( i, rowIndex).type == Constants.PIECE_TYPE_POTENTIALLY_DEAD)) {
//                            break;
//                        }
//                        else {
//                            alreadyDamagedOffset++ ;
//                        }
//                    }
//                    toX -= (alreadyDamagedOffset + 0) * Constants.PUZZLE_TILE_SIZE;
//                    AppContext.LOG("attack to opponents RIGHT, toX=" + toX);
                }
                
                /* Find the smallest distance between any of the pieces, and the target piece */
                var smallestDistanceBetweenJoinAndTargetPiece :int = 10000;
                for( k = 0; k < join._piecesX.length; k++) {
//                    piece = sourceboard.getPieceAt( join._piecesX[k], join._piecesY[k]);
                    var pieceX :int = sourceboard.getPieceXLoc( join._piecesX[k] );
                    smallestDistanceBetweenJoinAndTargetPiece = Math.min( Math.abs(toX - pieceX), smallestDistanceBetweenJoinAndTargetPiece );
                }
                smallestDistanceBetweenJoinAndTargetPiece += Constants.PUZZLE_TILE_SIZE/2;
                if( sourceboard.x > boardAttacked.x) {
                    smallestDistanceBetweenJoinAndTargetPiece = -smallestDistanceBetweenJoinAndTargetPiece;
                }
                
                /* Convert the pieces to the horizontal join graphic */
                var newPieces :Array = new Array();
                var xBounce :int;
                var yBounce :int;
                var bounceMoveTask :ObjectTask;
                var bounceRotationTask :ObjectTask;
                        
                for( k = 0; k < join._piecesX.length; k++) {
                    piece = sourceboard.getPieceAt( join._piecesX[k], join._piecesY[k]);
                    if(piece != null){/* If it's part of another join, it may already be removed */
                        piece.toHorizontalJoin();
                        sourceboard._boardPieces[ piece.boardIndex ] = null;
                        piece.boardIndex = -1;//Test
                        piece.destroySelf();
                        if(sourceboard._sprite.contains( piece.displayObject)) {
                            sourceboard._sprite.removeChild( piece.displayObject)
                        }
                    }
                    
                    
                    var newPiece :JoinGamePiece = createPieceFromBoard( sourceboard, join._piecesX[k], join._piecesY[k]);
//                    newPiece.scaleX = sourceboard._sprite.scaleX;
//                    newPiece.scaleY = sourceboard._sprite.scaleY;
                    newPieces.push(newPiece);
                    newPiece.color = join._color;
//                    newPiece.x = sourceboard.x + sourceboard.getPieceXLoc(join._piecesX[k]) * sourceboard._sprite.scaleX;
//                    newPiece.y = sourceboard.y + sourceboard.getPieceYLoc(join._piecesY[k]) * sourceboard._sprite.scaleY;
//                    newPiece.size = Constants.PUZZLE_TILE_SIZE * sourceboard._sprite.scaleX;
                    
//                    newPiece.x = sourceboard.x + sourceboard.getPieceXLoc(join._piecesX[k]);
//                    newPiece.y = sourceboard.y + sourceboard.getPieceYLoc(join._piecesY[k]);
                    newPiece.toHorizontalJoin();
                    db.addObject( newPiece, _sprite);
//                    db.addObject( newPiece, sourceboard._sprite);
//                    AppContext.LOG("smallestDistanceBetweenJoinAndTargetPiece="+smallestDistanceBetweenJoinAndTargetPiece);
                    var newPieceXTarget :int = newPiece.x + smallestDistanceBetweenJoinAndTargetPiece;
                    var joinAnim :SerialTask = new SerialTask();
                    joinAnim.addTask(LocationTask.CreateLinear(newPieceXTarget, newPiece.y, Constants.JOIN_ANIMATION_TIME));
                    
                    /* Add a random angle to spin off  */
//                    var angle :Number = rand.nextNumber() * 2 * Math.PI;
//                    angle = rand.nextBoolean() ? -angle : angle;
//                    var pieceBounceDistance :int = 40;
                    
//                    xBounce = Math.cos(angle) * Constants.PIECE_JOIN_BOUNCE_DISTANCE;
//                    yBounce = Math.sin(angle) * Constants.PIECE_JOIN_BOUNCE_DISTANCE;
//                    bounceMoveTask = LocationTask.CreateLinear( newPieceXTarget + xBounce, newPiece.y + yBounce, Constants.JOIN_ANIMATION_TIME);
//                    bounceRotationTask = RotationTask.CreateLinear( 2*angle , Constants.JOIN_ANIMATION_TIME);
//                    
//                    joinAnim.addTask(new ParallelTask(bounceMoveTask, bounceRotationTask));
                    joinAnim.addTask(new SelfDestructTask());
                    newPiece.addTask(joinAnim);

                }
                
//                if(join._piecesX.length == 5 || join._piecesX.length == 7) { /* Joins fly in both directions */
//                    
//                    for( k = 0; k < newPieces.length; k++) {
//                        piece = newPieces[k] as JoinGamePiece;
//                        var newPiece2 : JoinGamePiece = new JoinGamePiece();
//                        newPiece2.color = piece.color;
//                        newPiece2.x = sourceboard.x + piece.x;
//                        newPiece2.y = sourceboard.y + piece.y;
//                        newPiece2.toHorizontalJoin();
//                        db.addObject( newPiece2, _sprite);
//                        
//                        var newPieceXTarget :int = newPiece.x + smallestDistanceBetweenJoinAndTargetPiece;
//                        var joinAnim :SerialTask = new SerialTask();
//                        joinAnim.addTask(LocationTask.CreateLinear(newPieceXTarget, newPiece.y, Constants.JOIN_ANIMATION_TIME));
//                    
//                        
//                        xBounce = Math.cos(angle) * pieceBounceDistance;
//                        yBounce = Math.sin(angle) * pieceBounceDistance;
//                        bounceMoveTask = LocationTask.CreateLinear( newPieceXTarget + xBounce, newPiece.y + yBounce, Constants.JOIN_ANIMATION_TIME);
//                        bounceRotationTask = RotationTask.CreateLinear( 2*angle , Constants.JOIN_ANIMATION_TIME);
//                        
//                        joinAnim.addTask(new ParallelTask(bounceMoveTask, bounceRotationTask));
//                        joinAnim.addTask(new SelfDestructTask());
//                        newPiece.addTask(joinAnim);
//                    }
                    
                    
//                }
             
             
             
             
             
             
                
            }
            else {
                AppContext.LOG("boardAttacked == null");
            }
            
            
            
            var attackAnimation :JoinAttackAnimation;
            var xLocToAttack :int;
            var attackAnimTask :SerialTask;
            var coverPiece :JoinGamePiece;
            var coverAnimTask :SerialTask;
            
//            var firingDuration :Number = 0.3;
            
            var localRowIndex :int = ((_gameModel.getBoardForPlayerID(e.boardAttacked) as JoinGameBoardRepresentation)._rows - 1) - e.row;
            var piecesDestroyed :Array = new Array();
            
            if( boardAttacked != null){
                /* This means FROM the the left */
                if( e.side == Constants.LEFT || e.side == Constants.ATTACK_BOTH){
                    
                    for(var leftAttackCount :int = 0; leftAttackCount < e.damage; leftAttackCount++){
                        for(var leftColIndex :int = 0; leftColIndex < boardAttacked._cols; leftColIndex++){
                            var leftPiece :JoinGamePiece = boardAttacked.getPieceAt( leftColIndex, localRowIndex) as JoinGamePiece;
                            if(leftPiece != null && (leftPiece.type == Constants.PIECE_TYPE_NORMAL || leftPiece.type == Constants.PIECE_TYPE_POTENTIALLY_DEAD)){
                                leftPiece.type = Constants.PIECE_TYPE_DEAD;
                                piecesDestroyed.push(leftPiece);
//                                AppContext.LOG("adding to piecesdos, piecesDestroyed.length=" + piecesDestroyed.length);
//                                pieceDestroyed = leftPiece;
                                break;
                            }
                        }
                    }
                }
                
                if( e.side == Constants.RIGHT|| e.side == Constants.ATTACK_BOTH){
                    for(var rightAttackCount :int = 0; rightAttackCount < e.damage; rightAttackCount++){
                        for(var rightColIndex :int = boardAttacked._cols - 1; rightColIndex >= 0; rightColIndex--){
                            var rightPiece :JoinGamePiece = boardAttacked.getPieceAt( rightColIndex, localRowIndex) as JoinGamePiece;
                            if(rightPiece != null && (rightPiece.type == Constants.PIECE_TYPE_NORMAL || rightPiece.type == Constants.PIECE_TYPE_POTENTIALLY_DEAD)){
                                rightPiece.type = Constants.PIECE_TYPE_DEAD;
                                piecesDestroyed.push(rightPiece);
//                                AppContext.LOG("adding to piecesdos, piecesDestroyed.length=" + piecesDestroyed.length);
//                                pieceDestroyed = rightPiece;
                                break;
                            }
                        }
                    }
                }
                
//                AppContext.LOG("piecesDestroyed.length=" + piecesDestroyed.length);
//                Convert the damaged piece by animating a cover piece
                if(piecesDestroyed.length > 0){
                    
                    for( k = 0; k < piecesDestroyed.length; k++) {
                        
                        var pieceDestroyed :JoinGamePiece = piecesDestroyed[k] as JoinGamePiece;
                        coverPiece = new JoinGamePiece();
                        coverPiece.color = boardAttacked._boardRepresentation._boardPieceColors[ pieceDestroyed.boardIndex ];
                        coverPiece.x = pieceDestroyed.x;
                        coverPiece.y = pieceDestroyed.y;
                        
                        
                        boardAttacked.db.addObject(coverPiece, boardAttacked._sprite);
                        
                        coverAnimTask = new SerialTask();
                        coverAnimTask.addTask(new TimedTask(Constants.JOIN_ANIMATION_TIME));
                        coverAnimTask.addTask(ScaleTask.CreateEaseOut(0.1, 0.1, Constants.PIECE_SCALE_DOWN_TIME));
                        coverAnimTask.addTask(new SelfDestructTask());
                        coverPiece.addTask( coverAnimTask );
//                        
//                        function showExplosion() :void {
//                            var _piece_break_eastward :MovieClip = new _piece_break_eastwardClass();
//                        }
                        
                    }
                    
                    
                    /* Then make the pieces in the vicinity wobble from the shockwave */
                    var colForShockwave :int = e.side == Constants.RIGHT ? boardAttacked._cols - 1 : 0;
                    var colIncrement :int = e.side == Constants.RIGHT ? - 1 : 1;
                    var shockwaveDistanceMax :int = boardAttacked._cols;
                    var shockwavePieceMoveDistance :int = 60;
                    var currentShockwaveDistance :int = 0;
                    while( currentShockwaveDistance <= shockwaveDistanceMax) {
                        var pieceToShock :JoinGamePiece = boardAttacked.getPieceAt( colForShockwave, localRowIndex) as JoinGamePiece;
                        shockwavePieceMoveDistance *= 0.6;
                        if(pieceToShock != null) {
                            var shockAnimTask :SerialTask = new SerialTask();
                            shockAnimTask.addTask( new TimedTask(Constants.JOIN_ANIMATION_TIME + currentShockwaveDistance*0.05) );
                            shockAnimTask.addTask( LocationTask.CreateEaseOut(pieceToShock.x + shockwavePieceMoveDistance*colIncrement*(1.0/(currentShockwaveDistance+1)), pieceToShock.y, 0.2) );
                            shockAnimTask.addTask( LocationTask.CreateEaseIn(pieceToShock.x, pieceToShock.y, 0.05) );
                            pieceToShock.addTask( shockAnimTask );
                        }
                        
                        /* Do the row above and below as well */
                        if(localRowIndex - 1 >= 0) {
                            
                        }
                        
                        colForShockwave += colIncrement;
                        currentShockwaveDistance++;
                    }
                    
                    
                        //localRowIndex
                        
//                        var centerX :int = boardAttacked.idxToX(pieceDestroyed.boardIndex);
//                        var centerY :int = boardAttacked.idxToY(pieceDestroyed.boardIndex);
//                        var centerXCoord :int = boardAttacked.getPieceXLoc(centerX);
//                        var centerYCoord :int = boardAttacked.getPieceYLoc(centerY);
//                        for each (var distance :int in [2,1]) {
//                            for( i = centerX - distance; i < centerX + distance; i++) {
//                                for( var j :int = centerY - distance; j < centerY + distance; j++) {
//                                    if( !(i == centerX && j == centerY)) {
//                                        var pieceToWobble :JoinGamePiece = boardAttacked.getPieceAt(i, j) as JoinGamePiece;
//                                        if(pieceToWobble != null) {
//                                            
//                                            var shockDistance :int = 5;
//                                            
//                                            var xDelta :int = boardAttacked.idxToX(pieceToWobble.boardIndex) < centerX ? -shockDistance*(1.0/distance) : shockDistance*(1.0/(distance*2));
//                                            var yDelta :int = boardAttacked.idxToY(pieceToWobble.boardIndex) < centerY ? -shockDistance*(1.0/distance) : shockDistance*(1.0/(distance*2));
//                                            
//                                            
//                                            var taskAnimation :SerialTask = new SerialTask();
//                                            taskAnimation.addTask( new TimedTask(Constants.JOIN_ANIMATION_TIME) );
//                                            taskAnimation.addTask( LocationTask.CreateEaseOut(pieceToWobble.x + xDelta, pieceToWobble.y + yDelta, 0.2) );
//                                            taskAnimation.addTask( LocationTask.CreateEaseIn(pieceToWobble.x, pieceToWobble.y, 0.2) );
//                                            taskAnimation.addTask( LocationTask.CreateEaseOut(pieceToWobble.x + xDelta, pieceToWobble.y + yDelta, 0.05) );
//                                            taskAnimation.addTask( LocationTask.CreateEaseIn(pieceToWobble.x, pieceToWobble.y, 0.05) );
//                                            
//                                            pieceToWobble.addNamedTask(SHOCKWAVE_TASK_NAME, taskAnimation, true); 
//                                        }
//                                    }
//                                }
//                            }
//                        }
                        
//                    }                    
                        
                }
                else {
                    AppContext.LOG("piecesDestroyed.length == 0 WTF");
                }
            }
            
            doGraphicsAndAnimationForDeadBottomRow(boardAttacked);
            
//            AppContext.LOG("\ndoHorizontalAttack(), view == model ? \n\t boardAttacked=" + boardAttacked.isModelAndViewSame() + "\n\tsourceBoard=" + sourceboard.isModelAndViewSame());
            
//            AppContext.LOG("view doHorizontalAttack() board after:\n" + boardAttacked);

//            _myBoardDisplay.resetPositionOfPiecesNotMoving();
//            _leftBoardDisplay.resetPositionOfPiecesNotMoving();
//            _rightBoardDisplay.resetPositionOfPiecesNotMoving();
        }
        

        
        
        protected function doVerticalJoins( e :JoinGameEvent ) :void
        {
                        
            var board :JoinGameBoardGameArea = getBoardView( e.boardPlayerID );
            var k :int;
            var piece :JoinGamePiece;
            AppContext.LOG("view doVerticalJoins() board before:\n" + board);
            
            
            if( board != null){
                
                var join :JoinGameJoin = e.joins[0] as JoinGameJoin;
                /* Do the join animations */
                for( k = 0; k < join._piecesX.length; k++) {
                    piece = board.getPieceAt( join._piecesX[k], join._piecesY[k]);
                    if(piece == null){/* If it's part of another join, it may already be removed */
                        continue;
                    }
                    
                    board._boardPieces[ piece.boardIndex ] = null;
                    piece.boardIndex = -1;
                    piece.destroySelf();
                    
                    
                    var newPiece :JoinGamePiece = createPieceFromBoard( board, join._piecesX[k], join._piecesY[k]);
                    newPiece.color = piece.color;
                    newPiece.toVerticalJoin();
                    db.addObject( newPiece, _sprite);
                    
                    var joinAnim :SerialTask = new SerialTask();
                    var parallelTask :ParallelTask = new ParallelTask(
                        LocationTask.CreateLinear(newPiece.x + newPiece.width/2, newPiece.y - 200, Constants.JOIN_ANIMATION_TIME),
                        new ScaleTask(0, 0, Constants.JOIN_ANIMATION_TIME)
                    );
                    joinAnim.addTask(parallelTask);
                    joinAnim.addTask(new SelfDestructTask());
                    newPiece.addTask(joinAnim);
                    
                    
                }
                
                
                
                
                while( board._rows < board._boardRepresentation._rows){
                    board._rows++;
                    /* Add a new row to the pieces list */ 
                    for( var c :int = 0; c < board._cols; c++){
                        board._boardPieces.unshift(null); //Add nulls to the beginning
                    }
                    
//                    AppContext.LOG("added a row of nulls:\n " + board); 
                    
                    /* Adjust the indices and position*/
/*                     board.adjustAllChildrenY(Constants.PUZZLE_TILE_SIZE);
                    board.y = _gameControl.local.getSize().y - board._rows*Constants.PUZZLE_TILE_SIZE; */
                    
                    for( var i :int = 0; i < board._boardPieces.length; i++){
                        piece = board._boardPieces[i] as JoinGamePiece;
                        if(piece != null){
                            piece.boardIndex += board._cols;
                            piece.x = board.getPieceXLoc(  board.idxToX( piece.boardIndex));
                            piece.y = board.getPieceYLoc(  board.idxToY( piece.boardIndex));
                        }
                    }
//                    AppContext.LOG("adjusted indices:\n " + board); 
                    
                    /* Add inactive piece placeholders  */ 
                    for( var colForNewiece :int = 0; colForNewiece < board._cols; colForNewiece++){
                        board.addPieceAtPosition(colForNewiece, 0, Constants.PIECE_TYPE_INACTIVE, 0);
                    }
                    AppContext.LOG("after adding new pieces:\n " + board);
                }
                /* Then add empty pieces on the top of the board */
                
                
                
                
                
//                for( var index :int; index < board._boardPieces.length; index++){
//                    var pieceToChange :JoinGamePiece = board._boardPieces[index] as JoinGamePiece;
//                    /* Change the piece type if we haven't filled in an empty piece */
//                    if(pieceToChange != null && pieceToChange.type != board._boardRepresentation._boardPieceTypes[index] ){//&& pieceToChange.type == Constants.PIECE_TYPE_EMPTY
//                        pieceToChange.type = board._boardRepresentation._boardPieceTypes[index];
//                        pieceToChange.color = board._boardRepresentation._boardPieceColors[index];
//                    }
//                }
                
                
//                /* Add the new pieces.  Get the colors from the model. */
//                var newPieceRow :int = board._boardRepresentation.getHighestRowBelowEmptyPieceOrJustTheHighestPiece(e.col);
//                AppContext.LOG("newPieceRow=" + newPieceRow);
//                AppContext.LOG("col=" + e.col);
//                AppContext.LOG("previous type=" + board.getPieceAt( e.col, newPieceRow ).type);
//                
//                board.getPieceAt( e.col, newPieceRow ).type = Constants.PIECE_TYPE_NORMAL;
//                AppContext.LOG("now type=" + board.getPieceAt( e.col, newPieceRow ).type);
//                board.getPieceAt( e.col, newPieceRow ).color = board._boardRepresentation._boardPieceColors[ board._boardRepresentation.coordsToIdx( e.col, newPieceRow) ];
//                if( e.col > 0){
//                    newPieceRow = board._boardRepresentation.getHighestRowBelowEmptyPieceOrJustTheHighestPiece(e.col - 1);
//                    AppContext.LOG("newPieceRow=" + newPieceRow);
//                    AppContext.LOG("col=" + (e.col-1));
//                    board.getPieceAt( e.col - 1, newPieceRow ).type = Constants.PIECE_TYPE_NORMAL;
//                    board.getPieceAt( e.col - 1, newPieceRow ).color = board._boardRepresentation._boardPieceColors[ board._boardRepresentation.coordsToIdx( e.col - 1, newPieceRow) ];
//                }
//                if( e.col < board._cols  - 1){
//                    newPieceRow = board._boardRepresentation.getHighestRowBelowEmptyPieceOrJustTheHighestPiece(e.col + 1);
//                    AppContext.LOG("newPieceRow=" + newPieceRow);
//                    AppContext.LOG("col=" + (e.col+1));
//                    board.getPieceAt( e.col + 1, newPieceRow ).type = Constants.PIECE_TYPE_NORMAL;
//                    board.getPieceAt( e.col + 1, newPieceRow ).color = board._boardRepresentation._boardPieceColors[ board._boardRepresentation.coordsToIdx( e.col + 1, newPieceRow) ];
//                }
                
//                board.removeAndAddDisplayChildren();
                adjustZoomOfPlayAreaBasedOnCurrentPlayersBoard();
            }
            
            
            
            _myBoardDisplay.resetPositionOfPiecesNotMoving();
            _leftBoardDisplay.resetPositionOfPiecesNotMoving();
            _rightBoardDisplay.resetPositionOfPiecesNotMoving();
            
            
            
            
            
            

//            AppContext.LOG("\ndoVerticalJoins() end, view == model ? \n\t board=" + board.isModelAndViewSame() );
        }
        protected function addNewPieces( e :JoinGameEvent ) :void
        {
//            AppContext.LOG("view addNewPieces()");
            
            var board :JoinGameBoardGameArea = getBoardView( e.boardPlayerID );
            
            if( board != null){
                
//                AppContext.LOG("model:\n" + board._boardRepresentation);
//                AppContext.LOG("view addNewPieces before:" + board);
                
                for( var index :int; index < board._boardPieces.length; index++){
                    var pieceToChange :JoinGamePiece = board._boardPieces[index] as JoinGamePiece;
                    
                    if(pieceToChange == null){
                        board.addPieceAtPosition( board._boardRepresentation.idxToX(index), board._boardRepresentation.idxToY(index), Constants.PIECE_TYPE_INACTIVE, 1);
                        pieceToChange = board._boardPieces[index] as JoinGamePiece;
//                        AppContext.LOG("adding piece at index=" + index);
                    }
                    
                    /* Change the piece type if we haven't filled in an empty piece */
                    if( pieceToChange.type != board._boardRepresentation._boardPieceTypes[index]){// || pieceToChange.color != board._boardRepresentation._boardPieceColors[index] ){//&& pieceToChange.type == Constants.PIECE_TYPE_EMPTY
//                        pieceToChange.x = 0;
//                        pieceToChange.y = 0;
//                        AppContext.LOG("changing piece type at index=" + index);
                        pieceToChange.color = board._boardRepresentation._boardPieceColors[index];
                        pieceToChange.type = board._boardRepresentation._boardPieceTypes[index];
                        var pieceAnim :SerialTask = new SerialTask();
//                        pieceAnim.addTask( new FunctionTask(pieceToChange.convertToNormal) );
//                        pieceAnim.addTask(ScaleTask.CreateSmooth(1.0, 1.0, 2.0));
                        pieceAnim.addTask(RotationTask.CreateLinear(360*1, 0.8));//.CreateEaseIn(1.0, 1.0, Constants.PIECE_SCALE_DOWN_TIME));
                        pieceToChange.addTask(pieceAnim);
                        
                        
                        
                    }
                }
                
//                AppContext.LOG("view addNewPieces after:" + board);
                
//                for( var k :int = 0; k < e.newIndices.length; k++){
//                    AppContext.LOG("adding new piece at (" + board.idxToX(e.newIndices[k]) + ", " + board.idxToY(e.newIndices[k]) + "");
//                    board.addPieceAtPosition( board.idxToX(e.newIndices[k]), board.idxToY(e.newIndices[k]), Constants.PIECE_TYPE_NORMAL, e.newColors[k]);
////                    var piece :JoinGamePiece = new JoinGamePiece(Constants.PUZZLE_TILE_SIZE);
////                    piece.type = Constants.PIECE_TYPE_NORMAL;
////                    piece.color = e.newColors[k];
////                    board._boardPieces[ e.indices[k] ] = piece;
////                    (board._boardPieces[ e.indices[k] ] as JoinGamePiece).type = Constants.PIECE_TYPE_NORMAL;
////                    (board._boardPieces[ e.indices[k] ] as JoinGamePiece).color = e.newColors[k];
//                }
//                AppContext.LOG(" after adding, model=\n" + board._boardRepresentation + " \n view:\n" + board);
            }
//            AppContext.LOG("view == model: " + board.isModelAndViewSame());
            
        }
        
        protected function doPiecesFall( e :JoinGameEvent) :void
        {
            var taskAnimation :SerialTask;
            var toX :Number;
            var toY :Number;
            if( getBoardView( e.boardPlayerID ) != null)
            {
//              

                var board :JoinGameBoardGameArea = getBoardView( e.boardPlayerID );

                
                AppContext.LOG("view doPiecesFall() before: " + board);
                
                var highestRowIndexToAbsorbShockForEachColumnWithFallingPieces :HashMap = new HashMap();
//                var fallingPieces :Array = [];
                
                /* Before pieces fall, animate the pieces  */
                
                
                for( var i :int = 0; i < e.toFall.length; i++) {
                    AppContext.LOG(" to fall: " + e.toFall[i] );
                    var fallArray :Array = e.toFall[i] as Array;
                    var piece :JoinGamePiece = board._boardPieces[ board.coordsToIdx( fallArray[0], fallArray[1]) ];
                    
                    if(piece == null){
                        continue;
                    }
                    
//                    fallingPieces.push(piece);
                    
                    var rowIndexUnderThisPiece :int = fallArray[3] + 1;
                    if( rowIndexUnderThisPiece >= 0 && rowIndexUnderThisPiece < board._rows) {
                        if( highestRowIndexToAbsorbShockForEachColumnWithFallingPieces.containsKey( fallArray[0]) ) {
                            highestRowIndexToAbsorbShockForEachColumnWithFallingPieces.put( fallArray[0], Math.max( rowIndexUnderThisPiece, highestRowIndexToAbsorbShockForEachColumnWithFallingPieces.get( fallArray[0])));
                        }
                        else {
                            highestRowIndexToAbsorbShockForEachColumnWithFallingPieces.put( fallArray[0], rowIndexUnderThisPiece);
                        }
                    }
                    
//                    if( !ArrayUtil.contains( columnsWithFallingPieces, fallArray[0])) {
//                        columnsWithFallingPieces.push( fallArray[0] );
//                    }
                    
                    toX = board.getPieceXLoc(fallArray[2]);
                    toY = board.getPieceYLoc(fallArray[3]);
                    taskAnimation = new SerialTask();
                    taskAnimation.addTask( new TimedTask(0) );
                    taskAnimation.addTask( LocationTask.CreateEaseIn(toX, toY + Constants.DISTANCE_OVER_TARGET_DROPPED_PIECES_FALL, Constants.PIECE_DROP_TIME) );
                    taskAnimation.addTask( new TimedTask(Constants.PIECE_DROP_BOUNCE1_TIME) );
//                    taskAnimation.addTask( LocationTask.CreateEaseIn(toX, toY - Constants.DISTANCE_OVER_TARGET_DROPPED_PIECES_FALL/2, Constants.PIECE_DROP_BOUNCE1_TIME) );
                    taskAnimation.addTask( LocationTask.CreateEaseIn(toX, toY - Constants.DISTANCE_OVER_TARGET_DROPPED_PIECES_FALL/2, Constants.PIECE_DROP_BOUNCE1_TIME) );
//                    taskAnimation.addTask( LocationTask.CreateEaseIn(toX, toY - Constants.PIECE_DROP_BOUNCE2_DISTANCE, Constants.PIECE_DROP_BOUNCE2_TIME) );
                    taskAnimation.addTask( LocationTask.CreateEaseIn(toX, toY, Constants.PIECE_DROP_BOUNCE1_TIME * 0.7));
                    
                    piece.removeAllTasks();
//                    piece.addNamedTask(MOVE_TASK_NAME, taskAnimation, true);
                    piece.addTask(taskAnimation);  
//                    AppContext.LOG("piece " + piece.boardIndex + " should be eased to " + toX + ", " + toY + ", at index=" + board.coordsToIdx( fallArray[2], fallArray[3])  );
                    
                    board._boardPieces[ piece.boardIndex ] = null;
                    piece.boardIndex = board.coordsToIdx( fallArray[2], fallArray[3]);
                    
                    board._boardPieces[ piece.boardIndex ] = piece;
                    
//                    AppContext.LOG("so, piece at index=" + piece.boardIndex + " is " + piece);
                }
                
                /* Animate the column absorbing the shock of the falling pieces */
//                AppContext.LOG("highestRowIndexToAbsorbShockForEachColumnWithFallingPieces=" + highestRowIndexToAbsorbShockForEachColumnWithFallingPieces);
                for each ( var key: int in highestRowIndexToAbsorbShockForEachColumnWithFallingPieces.keys()) {
                    i = key;
                    var j :int = highestRowIndexToAbsorbShockForEachColumnWithFallingPieces.get(key) as int;
//                    AppContext.LOG("key=" + key + ", value=" + j);
//                    for( var j :int = 0; j < board._rows; j++) {
                        var nonFallingPiece :JoinGamePiece = board._boardPieces[ board.coordsToIdx( i, j) ];
                        if( nonFallingPiece != null) { /* Only act on non-falling pieces */
//                            AppContext.LOG("Animating ( " + i + ", " + j + ")");


                            toX = board.getPieceXLoc(board.idxToX(nonFallingPiece.boardIndex));
                            toY = board.getPieceYLoc(board.idxToY(nonFallingPiece.boardIndex));
                            
                            taskAnimation = new SerialTask();
                            taskAnimation.addTask( new TimedTask(Constants.PIECE_DROP_TIME) );
                            taskAnimation.addTask( LocationTask.CreateEaseOut(toX, toY + Constants.DISTANCE_OVER_TARGET_DROPPED_PIECES_FALL/2, Constants.PIECE_DROP_BOUNCE1_TIME) );
                            taskAnimation.addTask( LocationTask.CreateEaseIn(toX, toY, Constants.PIECE_DROP_BOUNCE1_TIME * 0.7) );
                            nonFallingPiece.removeAllTasks();
                            nonFallingPiece.addTask( taskAnimation );
                        }
//                        else { AppContext.LOG(" piece null ");}
//                    }
                     
                }
                
                
                
                
                
                AppContext.LOG("view doPiecesFall() after: " + board);
                
//                AppContext.LOG("doPiecesFall() model " + e.boardPlayerID + "==view: " + board.isModelAndViewSame());
                
                
//                adjustPieceIndicesFromFalling(board);
                
//                /* Put the pieces in the corrent array position */
//                for( var k :int = 0; k < e.oldIndices.length; k++){
//                    (board._boardPieces[ e.oldIndices[k] ] as JoinGamePiece).boardIndex = e.newIndices[k];
//                }
//                board.resetPiecesArrayPosition();
                
            }
            else {AppContext.LOG("doPiecesFall() no board found for id=" + e.boardPlayerID );}
            
              
            
        }
        
        /**
        * 
        * If the model sends us a confirm, we update the indices of 
        * the pieces.  A previous call of movePieceToLocationAndShufflePieces
        * only changes the positions, which was temporary.
        */
        protected function deltaConfirm( e :JoinGameEvent) :void
        {
            
            var boardview :JoinGameBoardGameArea = getBoardView( e.boardPlayerID );
            
            if( boardview != null)
            {
                boardview.movePieceToLocationAndShufflePieces( e.deltaPiece1X, e.deltaPiece1Y, e.deltaPiece2X, e.deltaPiece2Y);
//                AppContext.LOG("\nview deltaConfirm() model " + e.boardPlayerID + "==view: " + boardview.isModelAndViewSame());
                boardview.isModelAndViewSame();
//                if( !) {
//                    AppContext.LOG("model \n" + boardview._boardRepresentation);
//                }
//                AppContext.LOG("view \n" + boardview);
            }
            
//            _myBoardDisplay.resetPositionOfPiecesNotMoving();
//            _leftBoardDisplay.resetPositionOfPiecesNotMoving();
//            _rightBoardDisplay.resetPositionOfPiecesNotMoving();
//            adjustZoomOfPlayAreaBasedOnCurrentPlayersBoard();
        }
        
        
        
        /**
        * Updates position and placement of game boards.
        * 
        */
        public function updateBoardDisplays(event :JoinGameEvent = null) :void
        {
//            AppContext.LOG("\updateBoardDisplays, _observer="+_observer);
            if(_observer) {
                updateBoardDisplaysForObserver();
            }
            else {
                updateBoardDisplaysFor3BoardViews();
            }
        }
        
        protected function updateBoardDisplaysFor3BoardViews() :void 
        {
//            AppContext.LOG("\nJoinGameBoardsView.updateBoardDisplays()");
            if(_myBoardDisplay != null && _myBoardDisplay.board.playerID != _gameControl.game.getMyId())
            {
                _myBoardDisplay.doBoardDistructionAnimation();
                _myBoardDisplay.board = null;
            }
                
            if(_myBoardDisplay == null)
            {
                _myBoardDisplay = new JoinGameBoardGameArea( _gameControl, true);
                this.db.addObject(_myBoardDisplay, _sprite);
                /* The board must be added AFTER the display is added to the db, so all the pieces
                are added to the db also. */
                _myBoardDisplay.board = _gameModel.getBoardForPlayerID( _gameControl.game.getMyId() );
//                _sprite.addChild(_myBoardDisplay);
                _myBoardDisplay.doBoardEnterFromBottomAnimation( Constants.GUI_MIDDLE_BOARD_CENTER - _myBoardDisplay.width/2);
                
                // add the BoardView to the mode, as a child of the board sprite
                
        
            }

            var leftPlayerId :int =  _gameModel.getPlayerIDToLeftOfPlayer(_gameControl.game.getMyId());
            var rightPlayerId :int =  _gameModel.getPlayerIDToRightOfPlayer(_gameControl.game.getMyId());

            if(_leftBoardDisplay != null && _leftBoardDisplay.board.playerID != _gameModel.getPlayerIDToLeftOfPlayer(_gameControl.game.getMyId()))
            {
//                AppContext.LOG("removing player on left, as " + _leftBoardDisplay.board.playerID + "!=" + _gameModel.getPlayerIDToLeftOfPlayer(_gameControl.game.getMyId()) );
                _leftBoardDisplay.doBoardDistructionAnimation();
                _leftBoardDisplay = null;
            }
            if(_leftBoardDisplay == null)
            {
//                AppContext.LOG("adding board to my left");
                _leftBoardDisplay = new JoinGameBoardGameArea( _gameControl );
//                _sprite.addChild(_leftBoardDisplay);
                
                // add the BoardView to the mode, as a child of the board sprite
                this.db.addObject(_leftBoardDisplay, _sprite);
//                if( leftPlayerId != rightPlayerId ) {

                    AppContext.LOG("me==" + AppContext.gameCtrl.game.getMyId() + ", leftPlayerId=" + leftPlayerId );
                    _leftBoardDisplay.board = _gameModel.getBoardForPlayerID( leftPlayerId );
//                }
//                else if( _gameModel._initialSeatedPlayerIds.length == 2) {
//                    _leftBoardDisplay.board = _gameModel.getBoardForPlayerID( leftPlayerId );
//                }
//                else {
//                    _leftBoardDisplay.board = _gameModel.getBoardForPlayerID( -1 );
//                }
                _leftBoardDisplay.doBoardEnterFromSideAnimation(Constants.LEFT);
            }
            
            
            if( _rightBoardDisplay != null && _leftBoardDisplay.board.playerID == _gameModel.getPlayerIDToRightOfPlayer(_gameControl.game.getMyId())) {
                _rightBoardDisplay.addTask( new SerialTask( LocationTask.CreateEaseOut( 2000, _rightBoardDisplay.y, 0.5), new SelfDestructTask() ));
                _rightBoardDisplay = null;
            }
            
            if(_rightBoardDisplay != null && _rightBoardDisplay.board.playerID != _gameModel.getPlayerIDToRightOfPlayer(_gameControl.game.getMyId()))
            {
                _rightBoardDisplay.doBoardDistructionAnimation();
                _rightBoardDisplay = null;
            }
            if(_rightBoardDisplay == null)
            {
                _rightBoardDisplay = new JoinGameBoardGameArea(_gameControl);
                this.db.addObject(_rightBoardDisplay, _sprite);
                if( leftPlayerId != rightPlayerId) {
                    _rightBoardDisplay.board = _gameModel.getBoardForPlayerID( rightPlayerId );
                }
                else {
                    _rightBoardDisplay.board = _gameModel.getBoardForPlayerID( -1 );
                }
                
//                _rightBoardDisplay.board = _gameModel.getBoardForPlayerID( _gameModel.getPlayerIDToRightOfPlayer(_gameControl.game.getMyId()));
                _rightBoardDisplay.doBoardEnterFromSideAnimation(Constants.RIGHT);
            }
            
//            AppContext.LOG("\nWhen id="+_gameControl.game.getMyId()+" starts, left="+_gameModel.getPlayerIDToLeftOfPlayer(_gameControl.game.getMyId() )+ ", right="+_gameModel.getPlayerIDToRightOfPlayer(_gameControl.game.getMyId() ));
//            updateGameField();
        }
        
        protected function updateBoardDisplaysForObserver() :void 
        {
            
            var board :JoinGameBoardGameArea;  
            var id :int;
            var scaleTask: ScaleTask;
            var moveTask :LocationTask;
            var parallelTask :ParallelTask;
            var toX :int;
            var toY :int;   
                      
            
                      
            for each ( id in _gameModel.currentSeatingOrder) {
                
                if( !_id2Board.containsKey( id) ) {//Create the board
                    board = new JoinGameBoardGameArea(null);
                    this.db.addObject(board, _sprite);
                    board.board = _gameModel.getBoardForPlayerID( id );
                    _id2Board.put( id, board );
                }
            }
            
            
            var boardWidth :int = Constants.PUZZLE_TILE_SIZE * Constants.PUZZLE_STARTING_COLS;
            
            var availableHorizontalSpaceForBoards :Number = AppContext.gameWidth - 2*Constants.GUI_OBSERVER_VIEW_GAP_BETWEEN_BORDER_AND_BOARDS;
//            AppContext.LOG("availableHorizontalSpaceForBoards=" + availableHorizontalSpaceForBoards);
            var playerCount :int = _gameModel.currentSeatingOrder.length;
            var boardScale :Number = ((availableHorizontalSpaceForBoards - (Constants.GUI_OBSERVER_VIEW_GAP_BETWEEN_BOARDS * playerCount  + 1))/ playerCount) / boardWidth;
//            AppContext.LOG("boardScale=" + boardScale);
            boardScale = Math.min(0.7, boardScale);
            var actualBoardWidth :int = boardWidth * boardScale;
            var totalWidthOfAllBoards :int = actualBoardWidth * playerCount + Constants.GUI_OBSERVER_VIEW_GAP_BETWEEN_BOARDS * (playerCount - 1);
            var adjustedXOffset :int = (availableHorizontalSpaceForBoards - totalWidthOfAllBoards)/2;
//            AppContext.LOG("boardScale=" + boardScale);
            var currentXPosition :int = Constants.GUI_OBSERVER_VIEW_GAP_BETWEEN_BORDER_AND_BOARDS + adjustedXOffset;
            
            var boardHeight :int;
            for each ( id in _gameModel.currentSeatingOrder) {
                
                board = _id2Board.get(id) as JoinGameBoardGameArea;
                
                if(board == null) {
                    board = new JoinGameBoardGameArea(null);
                    
                }
                
                boardHeight = Constants.PUZZLE_TILE_SIZE * board._rows * boardScale;
                toX = currentXPosition;
                toY = (AppContext.gameHeight - boardHeight) - Constants.GUI_OBSERVER_VIEW_GAP_BETWEEN_FLOOR_AND_BOARDS;
                
                scaleTask = new ScaleTask(boardScale, boardScale, Constants.HEADSHOT_MOVEMENT_TIME);
                moveTask = LocationTask.CreateEaseOut(toX, toY, Constants.HEADSHOT_MOVEMENT_TIME);
                parallelTask = new ParallelTask( scaleTask, moveTask);
                board.addTask( parallelTask ); 
                currentXPosition +=  actualBoardWidth + Constants.GUI_OBSERVER_VIEW_GAP_BETWEEN_BOARDS;
            }
        }
        
        
        /** Respond to messages from other clients. */
        protected function playerKnockedOut (e :JoinGameEvent) :void
        {
            
            //Play a board distruction animation
            if( getBoardView( e.boardPlayerID ) != null)
            {
                var boardview :JoinGameBoardGameArea = getBoardView( e.boardPlayerID );
                
                boardview.doBoardDistructionAnimation();
//                AppContext.LOG("view deltaConfirm() model " + e.boardPlayerID + "==view: " + boardview.isModelAndViewSame());
            }
            
            
            
//            AppContext.LOG("playerKnockedOut(), player=" + event.boardPlayerID);
            updateBoardDisplays();
            
            dispatchEvent( new JoinGameEvent( e.boardPlayerID, JoinGameEvent.PLAYER_KNOCKED_OUT));
            
//            AppContext.LOG("\nplayerKnockedOut="+event.boardPlayerID);
//            
//            if( _rightBoardDisplay._boardRepresentation.playerID == event.boardPlayerID)
//            {
//                _rightBoardDisplay.board = _gameModel.getBoardForPlayerID( _gameModel.getPlayerIDToRightOfPlayer( _myBoardDisplay._boardRepresentation.playerID));
//            }
//            
//            if( _leftBoardDisplay._boardRepresentation.playerID == event.boardPlayerID)
//            {
//                _leftBoardDisplay.board = _gameModel.getBoardForPlayerID( _gameModel.getPlayerIDToLeftOfPlayer( _myBoardDisplay._boardRepresentation.playerID));
//            }
//            
//            if( _myBoardDisplay._boardRepresentation.playerID == event.boardPlayerID)
//            {
//                _myBoardDisplay.board = _gameModel.getBoardForPlayerID( -1);
//            }
//            
//            updateGameField();

        }
        
        
        protected function XXXDELETEdoJoinVisualizations( e :JoinGameEvent ) :void
        {
//            AppContext.LOG("view doJoinVisualizations()");
            var boardview :JoinGameBoardGameArea = getBoardView( e.boardPlayerID );
            var k :int;
            var i :int;
            
            if( boardview != null  && e.joins != null)
            {
                for( i = 0; i < e.joins.length; i++)
                {
                    var join :JoinGameJoin = e.joins[i] as JoinGameJoin;
                    //TODO: put the animations here.
                    
                    if( join._widthInPieces > 1) {//Horizontal join
                        
                        var boardAttacked :JoinGameBoardGameArea = getBoardView( e.boardAttacked );
                        var sourceboard :JoinGameBoardGameArea = getBoardView( e.boardPlayerID );
                        
                        
//                        AppContext.LOG("board attacked=" + e.boardAttacked);
//                        AppContext.LOG("view doHorizontalAttack() board before:\n" + boardAttacked);
                        
                        
                        
                        /* Determine the animation coords */
                        var fromX :int;
                        var fromY :int;
                        var toX :int;
                        var toY :int;
            
                        if( sourceboard != null ) {//Get the x coord from the source board
            //                var pieceIndex :int = sourceboard.coordsToIdx( join._piecesX[k], join._piecesY[k]);
//                            fromX = sourceboard.getPieceXLoc( join._piecesX[0] );
                            for( k = 1; k < join._piecesX.length; k++) {
                                fromX = Math.min(fromX, sourceboard.getPieceXLoc( join._piecesX[k] ));
                            } 
                            fromX = sourceboard.x + fromX;
                            fromY = sourceboard.y + sourceboard.getPieceYLoc( join._piecesY[0] );
                            toY = fromY;
                        }
                        else {
                            if(e.side == Constants.LEFT) {/* This means FROM the the left */
                                fromX = boardAttacked.x - Constants.GUI_BETWEEN_BOARDS*2;//HACK
                            }
                            else {
                                fromX = boardAttacked.x + boardAttacked.width + Constants.GUI_BETWEEN_BOARDS*2;
                            }
                        }
                        
                        if( boardAttacked != null ) {
                            var rowIndex :int = boardAttacked._rows - 1 - join.attackRow;
                            fromY = boardAttacked.y + boardAttacked.getPieceYLoc( rowIndex );
                            toY = fromY;
                            
                            var alreadyDamagedOffset :int = 0;
                            if(e.side == Constants.LEFT) {
//                                AppContext.LOG("from left");
                                toX = boardAttacked.x;
                                for(  i = 0; i < boardAttacked._cols; i++){
                                    if( boardAttacked.getPieceAt( i, rowIndex).type == Constants.PIECE_TYPE_NORMAL || boardAttacked.getPieceAt( i, rowIndex).type == Constants.PIECE_TYPE_POTENTIALLY_DEAD) {
                                        break;
                                    }
                                    else {
                                        alreadyDamagedOffset += Constants.PUZZLE_TILE_SIZE;
                                    }
                                }
                                toX += alreadyDamagedOffset;
                            }
                            else {
//                                AppContext.LOG("from right");
                                toX = boardAttacked.x + boardAttacked.width;
                                for( i = 0; i < boardAttacked._cols; i++){
                                    if( boardAttacked.getPieceAt( i, rowIndex).type == Constants.PIECE_TYPE_NORMAL || boardAttacked.getPieceAt( i, rowIndex).type == Constants.PIECE_TYPE_POTENTIALLY_DEAD) {
                                        break;
                                    }
                                    else {
                                        alreadyDamagedOffset += Constants.PUZZLE_TILE_SIZE;
                                    }
                                }
                                toX -= alreadyDamagedOffset;
                            }
                            
                            
            //                fromX = sourceboard.getPieceXLoc( join._piecesX[0] );
            //                for( var k :int = 1; k < join._piecesX.length; k++) {
            //                    fromX = Math.min(fromX, sourceboard.getPieceXLoc( join._piecesX[k] ));
            //                } 
            //                fromX = sourceboard.x + fromX;
            //                fromY = sourceboard.y + sourceboard.getPieceYLoc( join._piecesY[0] );
            //                toY = fromY;
                        }
                        else {
                            AppContext.LOG("target null, making up some coords");
                            if(e.side == Constants.LEFT) {/* This means FROM the the left */
                                toX = sourceboard.x + sourceboard.width + Constants.GUI_BETWEEN_BOARDS*2;//HACK
                            }
                            else {
                                toX = sourceboard.x - Constants.GUI_BETWEEN_BOARDS*2;
                            }
                        }
//                        AppContext.LOG("toX=" +toX);
                        
                        /* Convert the pieces to the horizontal join graphic */
                        for( k = 0; k < join._piecesX.length; k++) {
                            var piece :JoinGamePiece = boardview.getPieceAt( join._piecesX[k], join._piecesY[k]);
                            
                            
                            
                            
                            if(piece == null){/* If it's part of another join, it may already be removed */
                                continue;
                            }
                            piece.toHorizontalJoin();
                            boardview._boardPieces[ piece.boardIndex ] = null;
                            piece.boardIndex = -1;//Test
                            var joinAnim :SerialTask = new SerialTask();
                            
                            joinAnim.addTask(LocationTask.CreateLinear(toX, toY, Constants.JOIN_ANIMATION_TIME));
                            joinAnim.addTask(new SelfDestructTask());
                            piece.addTask(joinAnim);
                        }
            
//                        
//                            
//                            
//                        /* Animate the horizontal join */ 
//                        AppContext.LOG("starting h animation");
//                        var joinClass :Class = SWF_HORIZ_CLASSES[join._color - 1];
//                        var joinMovie :MovieClip = new joinClass();
//                        joinMovie.mouseEnabled = false;
//                        joinMovie.mouseChildren = false;
//                        joinMovie.cacheAsBitmap = true;
//                        var animation :SimpleSceneObject = new SimpleSceneObject(joinMovie);
//                        
//                        
//                        
//                        
//                        
//                        animation.x = fromX;
//                        animation.y = fromY;
//                        
//                        
//                        var joinAnim :SerialTask = new SerialTask();
//                        joinAnim.addTask(LocationTask.CreateLinear(toX, toY, Constants.JOIN_ANIMATION_TIME));
//                        joinAnim.addTask(new SelfDestructTask());
//                        animation.addTask(joinAnim);
//                        this.db.addObject(animation, _sprite);
//                        
//                        
//                        
                        
                        
                        
                        
                        
                    }
                    
                    
                    
                    
                    
                    
//                    for( var k :int = 0; k < join._piecesX.length; k++)
//                    {
//                        var piece :JoinGamePiece = boardview.getPieceAt( join._piecesX[k], join._piecesY[k]);
//                        if(piece == null){/* If it's part of another join, it may already be removed */
//                            continue;
//                        }
//                        // animate the pieces exploding
//                        var pieceAnim :SerialTask = new SerialTask();
//                        pieceAnim.addTask(ScaleTask.CreateEaseOut(0.3, 0.3, Constants.PIECE_SCALE_DOWN_TIME));
//                        pieceAnim.addTask(new SelfDestructTask());
//                        piece.addTask(pieceAnim);
//                        boardview._boardPieces[ piece.boardIndex ] = null;
//                        piece.boardIndex = -1;//Test
//                        if( ArrayUtil.contains( boardview._boardPieces, piece) ){
//                            AppContext.LOG("!!!doJoinVisualizations(), " + piece + " should be removed, but it's still there WTF? at index="+ ArrayUtil.indexOf(boardview._boardPieces, piece) );
//                        }
//                    }
                }
            }
        }
        
        
        public function adjustPieceIndicesFromFalling(board :JoinGameBoardGameArea): void
        {
                
            //Start at the bottom row moving up
            //If there are any empty pieces, swap with the next highest fallable block
            
            for(var j: int = board._rows - 2; j >= 0 ; j--)
            {
                for(var i: int = 0; i <  board._cols ; i++)
                {
                    var pieceIndex :int = board.coordsToIdx(i, j);
                    var piece :JoinGamePiece = board._boardPieces[pieceIndex] as JoinGamePiece;
                    //Now drop the piece as far as there are empty spaces below it.
                    if( !(piece.type == Constants.PIECE_TYPE_NORMAL || piece.type == Constants.PIECE_TYPE_DEAD || piece.type == Constants.PIECE_TYPE_POTENTIALLY_DEAD))
                    {
                        continue;
                    } 
                    
                    var yToFall: int = j;
                
                
                    while(yToFall < board._rows)
                    {
                        if(  board.isPieceAt(i, yToFall+1) &&  (board._boardPieces[board.coordsToIdx(i, yToFall+1)] as JoinGamePiece).type == Constants.PIECE_TYPE_EMPTY)
                        {
                            yToFall++;
                        }
                        else
                        {
                            break;
                        }
                    }
                    
                    
                    if( yToFall != j)
                    {
                        board.swapPieces(board.coordsToIdx(i, j), board.coordsToIdx(i, yToFall));
//                        board.movePieceToLocationAndShufflePieces(board.coordsToIdx(i, j), board.coordsToIdx(i, yToFall));
                    }
                
                
                }
            }
            

            
        }

        
        /**
         * 
         * Must be called after createOrUpdateOtherPlayerDisplay() because we need the player order
         * 
         */
        private function XXXDELETEupdateGameField(): void
        {
//            if(GameContext._playerIDsInOrderOfPlay == null)
//            {
//                return;
//            }
            
            _leftBoardDisplay.x = Constants.GUI_LEFT_BOARD_CENTER - _leftBoardDisplay.width/2;
            _myBoardDisplay.x = Constants.GUI_MIDDLE_BOARD_CENTER - _myBoardDisplay.width/2;
            _rightBoardDisplay.x = Constants.GUI_RIGHT_BOARD_CENTER - _rightBoardDisplay.width/2;
            
            
            
            adjustZoomOfPlayAreaBasedOnCurrentPlayersBoard();
            
        }
        
        
        
        protected function getBoardView( playerid :int) :JoinGameBoardGameArea
        {
            if(_observer) {
                return _id2Board.get( playerid ) as JoinGameBoardGameArea;
            }
            else {
                if( playerid == _myBoardDisplay._boardRepresentation.playerID )
                {
                    return _myBoardDisplay;
                }
                else if( playerid == _leftBoardDisplay._boardRepresentation.playerID )
                {
                    return _leftBoardDisplay;
                }
                else if( playerid == _rightBoardDisplay._boardRepresentation.playerID )
                {
                    return _rightBoardDisplay;
                }
            }
            return null;
        }
        
        
        protected function adjustZoomOfPlayAreaBasedOnCurrentPlayersBoard() :void
        {
            
            
//            AppContext.LOG("\nadjustZoomOfPlayAreaBasedOnCurrentPlayersBoard, _myBoardDisplay.height=" + _myBoardDisplay.height);
            
            if( _myBoardDisplay != null && _myBoardDisplay.height > Constants.PUZZLE_HEIGHT) {
                
                _myBoardDisplay.scaleX = 1.0;
                _myBoardDisplay.scaleY = 1.0;
                var newScale :Number = Constants.PUZZLE_HEIGHT / _myBoardDisplay.height;
                _myBoardDisplay.scaleX = newScale;
                _myBoardDisplay.scaleY = newScale;
                
                if(_leftBoardDisplay != null) {
                    _leftBoardDisplay.scaleX = newScale;
                    _leftBoardDisplay.scaleY = newScale;
                }
                
                if(_rightBoardDisplay != null) {
                    _rightBoardDisplay.scaleX = newScale;
                    _rightBoardDisplay.scaleY = newScale;
                }
            }
            
            
            
            if(_myBoardDisplay != null) {
                _myBoardDisplay.updateYBasedOnBoardHeight();
                _myBoardDisplay.x = Constants.GUI_MIDDLE_BOARD_CENTER - _myBoardDisplay.width/2;
            }
            
            
            if(_leftBoardDisplay != null) {
                _leftBoardDisplay.updateYBasedOnBoardHeight();
                _leftBoardDisplay.x = Constants.GUI_LEFT_BOARD_CENTER - _leftBoardDisplay.width/2;
            }
            
            if(_rightBoardDisplay != null) {
                _rightBoardDisplay.updateYBasedOnBoardHeight();
                _rightBoardDisplay.x = Constants.GUI_RIGHT_BOARD_CENTER - _rightBoardDisplay.width/2;
            }
            
        }
        
        override public function destroySelf():void
        {
            super.destroySelf();
            _gameModel.removeEventListener(JoinGameEvent.PLAYER_KNOCKED_OUT, playerKnockedOut);
            _gameModel.removeEventListener(JoinGameEvent.RECEIVED_BOARDS_FROM_SERVER, updateBoardDisplays);
//            _gameModel.removeEventListener(JoinGameEvent.DO_JOIN_VISUALIZATIONS, doJoinVisualizations);
            _gameModel.removeEventListener(JoinGameEvent.DELTA_CONFIRM, deltaConfirm);
            _gameModel.removeEventListener(JoinGameEvent.DO_PIECES_FALL, doPiecesFall);
            _gameModel.removeEventListener(JoinGameEvent.ADD_NEW_PIECES, addNewPieces);
            _gameModel.removeEventListener(JoinGameEvent.VERTICAL_JOIN, doVerticalJoins);
            _gameModel.removeEventListener(JoinGameEvent.ATTACKING_JOINS, doHorizontalAttack);
            _gameModel.removeEventListener(JoinGameEvent.BOARD_UPDATED, boardUpdated);
            _gameModel.removeEventListener(JoinGameEvent.DO_DEAD_PIECES, doDeadPieces);
            _gameModel.removeEventListener(JoinGameEvent.REMOVE_ROW_PIECES, doRemoveRowPieces);
            _gameModel.removeEventListener(JoinGameEvent.REMOVE_BOTTOM_ROW_AND_DROP_PIECES, removeBottomRowAndDropPieces);
        }
            
 
        override public function get displayObject () :DisplayObject
        {
            return _sprite;
        }     
        
        private var _myBoardDisplay :JoinGameBoardGameArea;
        private var _leftBoardDisplay :JoinGameBoardGameArea;
        private var _rightBoardDisplay :JoinGameBoardGameArea;
        
        private var _id2Board :HashMap;
        
        private var rand :Random = new Random();
        
        
        /*This variable represents the entire game state */
        private var _gameModel :JoinGameModel;
        
        private var _gameControl :GameControl;
        
        protected var _sprite :Sprite;
        
        
        protected static const MOVE_TASK_NAME :String = "move";
        
        protected static const SHOCKWAVE_TASK_NAME :String = "shock";
        public static const WOBBL_TASK_NAME :String = "wobble";
        
        
        
        
        private var _piece_break_eastwardClass :Class;
        private var _piece_break_westwardClass :Class;
        
        private var _observer :Boolean;     

        
        
//        protected static var SWF_VERT_CLASSES :Array;
//        protected static const SWF_VERT_CLASS_NAMES :Array = [ "01_vert", "02_vert", "03_vert", "04_vert", "05_vert"];
//        protected static var SWF_HORIZ_CLASSES :Array;
//        protected static const SWF_HORIZ_CLASS_NAMES :Array = [ "01_horiz", "02_horiz", "03_horiz", "04_horiz", "05_horiz" ];
        

    }
}