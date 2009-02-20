package vampire.client
{
import com.threerings.flash.DisplayUtil;
import com.threerings.flash.SimpleTextButton;
import com.threerings.flash.TextFieldUtil;
import com.threerings.util.Command;
import com.threerings.util.Log;
import com.whirled.avrg.AVRGamePlayerEvent;
import com.whirled.contrib.simplegame.objects.SceneObject;
import com.whirled.contrib.simplegame.objects.SimpleSceneObject;
import com.whirled.contrib.simplegame.tasks.SelfDestructTask;
import com.whirled.contrib.simplegame.tasks.SerialTask;
import com.whirled.contrib.simplegame.tasks.TimedTask;
import com.whirled.contrib.simplegame.util.Rand;
import com.whirled.net.ElementChangedEvent;
import com.whirled.net.MessageReceivedEvent;
import com.whirled.net.PropertyChangedEvent;

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.filters.BlurFilter;
import flash.filters.DropShadowFilter;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

import vampire.avatar.VampireAvatarHUDOverlay;
import vampire.client.events.ClosestPlayerChangedEvent;
import vampire.data.Codes;
import vampire.data.Logic;
import vampire.data.SharedPlayerStateClient;
import vampire.data.VConstants;
import vampire.server.BloodBloomGameRecord;

/**
 * The main game HUD, showing e.g. blood, game notifications, and buttons to select the subgame to
 * play.
 */
public class HUD extends SceneObject
{
    public function HUD()
    {
        _displaySprite = new Sprite();
        
        setupUI();
        
        //Listen to events that might cause us to update ourselves
        registerListener( ClientContext.gameCtrl.player, AVRGamePlayerEvent.ENTERED_ROOM, updateOurPlayerState );
        registerListener( ClientContext.gameCtrl.room.props, PropertyChangedEvent.PROPERTY_CHANGED, propChanged );
        registerListener( ClientContext.gameCtrl.room.props, ElementChangedEvent.ELEMENT_CHANGED, elementChanged);
        
//        registerListener( ClientContext.model, ClosestPlayerChangedEvent.CLOSEST_PLAYER_CHANGED, closestPlayerChanged);

        registerListener( ClientContext.gameCtrl.room, MessageReceivedEvent.MESSAGE_RECEIVED, handleMessageReceived);

        
        updateOurPlayerState();

        if( VConstants.LOCAL_DEBUG_MODE) {
            showTarget( ClientContext.gameCtrl.player.getPlayerId() );
        }

          
    }
    
    protected function handleMessageReceived( e :MessageReceivedEvent ) :void
    {
        if( e.name == VConstants.NAMED_EVENT_BLOODBLOOM_COUNTDOWN ) {
            var bb :BloodBloomGameRecord = BloodBloomGameRecord.fromArray( e.value as Array );
            trace("Prey " + bb.preyId + ", time=" + bb.currentCountDownSecond);
        }
    }
    
    override protected function destroyed () :void
    {
        trace("HUD destroyed");
    }
    
    override public function get displayObject () :DisplayObject
    {
        return _displaySprite;
    }
    
    override public function get objectName () :String
    {
        return "HUD";
    }
    
//    public function destroy() :void
//    {
//        EventHandlers.
//    }
    
    protected function closestPlayerChanged( e :ClosestPlayerChangedEvent ) :void
    {
        if( e.closestPlayerId > 0) {
            _target.text = "Target: " + ClientContext.gameCtrl.room.getAvatarInfo( e.closestPlayerId ).name;
        }
        else {
            _target.text = "Target: ";
        }
    }
    
    protected function propChanged (e :PropertyChangedEvent) :void
    {
        //Check if it is non-player properties changed??
//        log.debug("propChanged", "e", e);
//        trace("Player stats: " + SharedPlayerStateClient.toStringForPlayer( ClientContext.ourPlayerId));
        //Otherwise check for player updates
        
        
        if( e.name == Codes.ROOM_PROP_NON_PLAYERS ) {
            
        }
        else {
        
            var playerIdUpdated :int = SharedPlayerStateClient.parsePlayerIdFromPropertyName( e.name );
            
            if( isNaN(playerIdUpdated) ) {
                log.warning("propChanged, but no player id, ", "e", e);
                return;
            }
            
            //If the ROOM_PROP_NON_PLAYERS prop is changed, update it
            if( playerIdUpdated == ClientContext.ourPlayerId) {
                updateOurPlayerState();
            }
        }
        
    }
    
    protected function elementChanged (e :ElementChangedEvent) :void
    {
//        trace("element changed in HUD");
        //Check if it is non-player properties changed??
//        log.debug("elementChanged", "e", e);
//        log.debug("elementChanged", "e", e);
//        trace("Player stats: " + SharedPlayerStateClient.toStringForPlayer( ClientContext.ourPlayerId));
        //Otherwise check for player updates
        var playerIdUpdated :int = SharedPlayerStateClient.parsePlayerIdFromPropertyName( e.name );
        
        
        if( !isNaN( playerIdUpdated ) ) { 
            //If it's us, update the player HUD
            if( playerIdUpdated == ClientContext.ourPlayerId) {
            
                if( e.index == Codes.ROOM_PROP_PLAYER_DICT_INDEX_CURRENT_BLOOD) {
                    showBlood( ClientContext.ourPlayerId );
                }
                else if( e.index == Codes.ROOM_PROP_PLAYER_DICT_INDEX_XP) {
                    showXP( ClientContext.ourPlayerId );
                    showBlood( ClientContext.ourPlayerId );
                }
//                else if( e.index == Codes.ROOM_PROP_PLAYER_DICT_INDEX_LEVEL) {
//                    showLevel( ClientContext.ourPlayerId );
//                }
                else if( e.index == Codes.ROOM_PROP_PLAYER_DICT_INDEX_BLOODBONDED
                    || e.index == Codes.ROOM_PROP_PLAYER_DICT_INDEX_BLOODBONDED_NAME) {
                    showBloodBonds( ClientContext.ourPlayerId );
                    showTarget( ClientContext.ourPlayerId );
                }
                else if( e.index == Codes.ROOM_PROP_PLAYER_DICT_INDEX_CURRENT_ACTION) {
                    showAction( ClientContext.ourPlayerId );
                }
                else if( e.index == Codes.ROOM_PROP_PLAYER_DICT_INDEX_PREVIOUS_TIME_AWAKE) {
                    showTime( ClientContext.ourPlayerId );
                }
                else if( e.index == Codes.ROOM_PROP_PLAYER_DICT_INDEX_TARGET_DISPLAY_VISIBLE
                         || e.index == Codes.ROOM_PROP_PLAYER_DICT_INDEX_TARGET_NAME
                         || e.index == Codes.ROOM_PROP_PLAYER_DICT_INDEX_LOCATION
                         || e.index == Codes.ROOM_PROP_PLAYER_DICT_INDEX_HOTSPOT
                         || e.index == Codes.ROOM_PROP_PLAYER_DICT_INDEX_TARGET_BLOOD
                         || e.index == Codes.ROOM_PROP_PLAYER_DICT_INDEX_TARGET_MAXBLOOD
                ) {
                    showTarget( ClientContext.ourPlayerId );
                }
            }
            else {
//                log.debug("  Failed to update ElementChangedEvent" + e);
            }
        }
        else {
            log.error("isNaN( " + playerIdUpdated + " ), failed to update ElementChangedEvent" + e);
        }
        
    }
    
    
    protected function checkPlayerRoomProps( ...ignored) :void
    {
//        trace("checkPlayerRoomProps"    );
//        trace("Player stats: " + SharedPlayerStateClient.toStringForPlayer( ClientContext.ourPlayerId));
        if( !SharedPlayerStateClient.isProps( ClientContext.ourPlayerId )) {
//            log.debug("checkPlayerRoomProps, but no props found");
        }
        else {
            updateOurPlayerState();
//            EventHandlers.unregisterListener( _checkRoomProps2ShowStatsTimer, TimerEvent.TIMER, checkPlayerRoomProps);
//            _checkRoomProps2ShowStatsTimer.stop();
        }
    }
    

    
    
//    override public function hitTestPoint (
//        x :Number, y :Number, shapeFlag :Boolean = false) :Boolean
//    {
//        return _hud != null && _hud.hitTestPoint(x, y, shapeFlag);
//    }
    protected function findSafely (name :String) :DisplayObject
    {
        var o :DisplayObject = DisplayUtil.findInHierarchy(_displaySprite, name);
        if (o == null) {
            throw new Error("Cannot find object: " + name);
        }
        return o;
    }
    
    
    override protected function addedToDB () :void
    {
//        db.addObject( _targetingOverlay );
        db.addObject( _targetingOverlay, _displaySprite );
//        _targetingOverlay.setDisplayMode( VampireAvatarHUDOverlay.DISPLAY_MODE_SHOW_INFO_ALL_AVATARS );
        _targetingOverlay.setDisplayMode( VampireAvatarHUDOverlay.DISPLAY_MODE_OFF );
//        _targetingOverlay.displayObject.visible = false;
    }
    
    
    protected function setupUI() :void
    {
        
        _hud = new DraggableSprite(ClientContext.gameCtrl, "HUD");
        _displaySprite.addChild( _hud );
        _hud.init( new Rectangle(0, 0, 100, 100), 10, 10, 10, 10);
        
        
        //Create the ratgeting overlay
        _targetingOverlay = new VampireAvatarHUDOverlay( ClientContext.gameCtrl, 
            ClientContext.model.avatarManager );
        
        
//        _displaySprite.addChild( _targetingOverlay.displayObject );
//            ClientContext.model.avatarManager, function(...ignored) :void {
//                trace("Target Clicked");    
//            });
//        _targetingOverlay.visible = false;
        
        
            
        
        _hudMC = ClientContext.instantiateMovieClip("HUD", "HUD", true);
        
        _hud.addChild( _hudMC );
        
        
        
        
        
        _hudFeedback = TextField( findSafely("HUDfeedback") );
//        _hudFeedback.visible = true;
//        _hudFeedback.text = "afsadfafa sdf";
//        _hudFeedback.embedFonts = true;
//        _hudFeedback.appendText("sdfsdfsdfsdf");
//        trace("_hudFeedback=" + _hudFeedback);
        //The _hudFeedback is stealing mouse focus while invisible.  We'll add it when we need to
        _hudMC.removeChild( _hudFeedback );
        
        
        if( VConstants.LOCAL_DEBUG_MODE) {
            _hudMC.x = 500;
            _hudMC.y = 400;
        }
        else {
//            var screen :Rectangle = ClientContext.gameCtrl.local.getPaintableArea();
//            _hudMC.x = screen.width - _hudMC.width/2 - 10
//            _hudMC.y = screen.height - _hudMC.height/2 - 10;
            
            var bottomRight :Point = ClientContext.gameCtrl.local.locationToPaintable(1.0, 0, 0);
            
            _hudMC.x = bottomRight.x - _hudMC.width/2 - 10
            _hudMC.y = bottomRight.y - _hudMC.height/2 - 10;
        }
        
        _hudMC.mouseChildren = true;
        _hudMC.mouseEnabled = false;
        
        //Hackery to remove the invisible popup textfield stealing mouse focus
        for( var i :int = 0; i < _hudMC.numChildren; i++) {
            if( _hudMC.getChildAt(i) is TextField) {
                TextField(_hudMC.getChildAt(i)).mouseEnabled = false;
            }
            else if( _hudMC.getChildAt(i) is MovieClip) {
                MovieClip(_hudMC.getChildAt(i)).mouseEnabled = true;
            }
        }
        
//        _hudMC.addEventListener( MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void {
//            trace("mouse over hud");   
//            _sprite.graphics.beginFill(0);
//            _sprite.graphics.drawCircle(e.stageX, e.stageY, 3);
//            _sprite.graphics.endFill();
//            
//            trace(ClassUtil.getClassName( e.target ));
//        });
//        
//        _hudFeedback = ClientContext.instantiateMovieClip("HUD", "HUDfeedback", true);
//        if( _hudFeedback ) {
//            _hudFeedback.mouseEnabled = false;
//        }
//        else {
//            trace("failed to make feedback");
//        }
        
        _hudBlood = MovieClip( findSafely("HUDblood") );
        _hudBlood.gotoAndStop(0);
        _hudBloodBottom = _hudBlood.y ;//+ _hudBlood.height;
        _hudBloodStartHeight = _hudBlood.height;
        
//        _DEBUG_BLOOD_BAR_OUTLINE = new Sprite();
//        _hudBlood.parent.addChild( _DEBUG_BLOOD_BAR_OUTLINE );
//        _DEBUG_BLOOD_BAR_OUTLINE.graphics.lineStyle(1, 0xffffff);
//        _DEBUG_BLOOD_BAR_OUTLINE.graphics.drawRect(-_hudBlood.width/2, -_hudBlood.height/2, _hudBlood.width, _hudBlood.height);
//        _DEBUG_BLOOD_BAR_OUTLINE.x = _hudBlood.x;
//        _DEBUG_BLOOD_BAR_OUTLINE.y = _hudBlood.y;
        
        
        _hudXP = MovieClip( findSafely("HUDxp") );
        _hudXP.gotoAndStop(0);
        _hudXPBottom = _hudXP.y;// + _hudXP.height;
        _hudXPStartHeight = _hudXP.height;
        
        
        var hudPredator :SimpleButton = SimpleButton( findSafely("HUDpredator") );
//        Command.bind( hudPredator, MouseEvent.CLICK, VampireController.SWITCH_MODE, Constants.GAME_MODE_FEED_FROM_PLAYER);
        Command.bind( hudPredator, MouseEvent.CLICK, VampireController.FEED_REQUEST, [_targetingOverlay, _displaySprite, this] );
        
        var hudPrey :SimpleButton = SimpleButton( findSafely("HUDprey") );
        Command.bind( hudPrey, MouseEvent.CLICK, VampireController.SWITCH_MODE, VConstants.GAME_MODE_BARED);
        
        var hudHierarchy :SimpleButton = SimpleButton( findSafely("HUDhierarchy") );
        Command.bind( hudHierarchy, MouseEvent.CLICK, VampireController.SHOW_HIERARCHY, _hudMC );
        
        var hudHelp :SimpleButton = SimpleButton( findSafely("HUDhelp") );
        Command.bind( hudHelp, MouseEvent.CLICK, VampireController.SHOW_INTRO);
        
        var hudClose :SimpleButton = SimpleButton( findSafely("HUDclose") );
        Command.bind( hudClose, MouseEvent.CLICK, VampireController.QUIT);
        
        
        
        //Add the mouse over and rollout events.
        //When the mouse is over the HUD, show the avatar info for all players.
        //When the mouse rolls out, disable the avatar info
//        registerListener(_hudMC, MouseEvent.ROLL_OVER, function(...ignored) :void {
//            if( _targetingOverlay.displayMode != VampireAvatarHUDOverlay.DISPLAY_MODE_SELECT_FEED_TARGET && 
//                _targetingOverlay.displayMode != VampireAvatarHUDOverlay.DISPLAY_MODE_SHOW_FEED_TARGET ) {
//                _targetingOverlay.setDisplayMode( VampireAvatarHUDOverlay.DISPLAY_MODE_SHOW_INFO_ALL_AVATARS ); 
//            }
//        });
//        
//        registerListener(_hudMC, MouseEvent.ROLL_OUT, function(...ignored) :void {
//            if( _targetingOverlay.displayMode == VampireAvatarHUDOverlay.DISPLAY_MODE_SHOW_INFO_ALL_AVATARS ) {
//                _targetingOverlay.setDisplayMode( VampireAvatarHUDOverlay.DISPLAY_MODE_OFF ); 
//            }
//        });
//        
        
        
        registerListener(hudPrey, MouseEvent.ROLL_OVER, function(...ignored) :void {
            if( _targetingOverlay.displayMode != VampireAvatarHUDOverlay.DISPLAY_MODE_SELECT_FEED_TARGET && 
                _targetingOverlay.displayMode != VampireAvatarHUDOverlay.DISPLAY_MODE_SHOW_FEED_TARGET ) {
                _targetingOverlay.setDisplayMode( VampireAvatarHUDOverlay.DISPLAY_MODE_SHOW_INFO_ALL_AVATARS ); 
            }
        });
        
        registerListener(hudPrey, MouseEvent.ROLL_OUT, function(...ignored) :void {
            if( _targetingOverlay.displayMode == VampireAvatarHUDOverlay.DISPLAY_MODE_SHOW_INFO_ALL_AVATARS ) {
                _targetingOverlay.setDisplayMode( VampireAvatarHUDOverlay.DISPLAY_MODE_OFF ); 
            }
        });
        
        registerListener(hudPredator, MouseEvent.ROLL_OVER, function(...ignored) :void {
            if( _targetingOverlay.displayMode != VampireAvatarHUDOverlay.DISPLAY_MODE_SELECT_FEED_TARGET && 
                _targetingOverlay.displayMode != VampireAvatarHUDOverlay.DISPLAY_MODE_SHOW_FEED_TARGET ) {
                _targetingOverlay.setDisplayMode( VampireAvatarHUDOverlay.DISPLAY_MODE_SHOW_INFO_ALL_AVATARS ); 
            }
        });
        
        registerListener(hudPredator, MouseEvent.ROLL_OUT, function(...ignored) :void {
            if( _targetingOverlay.displayMode == VampireAvatarHUDOverlay.DISPLAY_MODE_SHOW_INFO_ALL_AVATARS ) {
                _targetingOverlay.setDisplayMode( VampireAvatarHUDOverlay.DISPLAY_MODE_OFF ); 
            }
        });
        
        
        
        
        
        
        
        
        
        
        
//        _hud.graphics.beginFill(0xffffff);
//        _hud.graphics.drawRect(0, 0, 600, 50);
//        _hud.graphics.drawRect(290, 50, 260, 100);
//        _hud.graphics.endFill();
        
        var startX :int = 30;
        var startY :int = 0;
            
        for each ( var mode :String in VConstants.GAME_MODES) {
            var button :SimpleTextButton = new SimpleTextButton( mode );
            button.x = startX;
            button.y = startY;
            startX += 85;
//            Command.bind( button, MouseEvent.CLICK, VampireController.SWITCH_MODE, mode);
//            _hud.addChild( button );
        }
        
        
        //Help Button
        var help :SimpleTextButton = new SimpleTextButton( "Help" );
        help.x = startX;
        help.y = startY;
        startX += 90;
        Command.bind( help, MouseEvent.CLICK, VampireController.SHOW_INTRO);
//        _hud.addChild( help );
        
        //Show blood as a horizontal bar
        _blood = new Sprite();
//        _hud.addChild( _blood );
        _blood.x = 180;
        _blood.y = 35; 
        
        _bloodText = TextFieldUtil.createField("", {mouseEnabled:false, selectable:false});
        _bloodText.x = 50;
        _blood.addChild( _bloodText );
        
        //Show xp as a horizontal bar
        _xp = new Sprite();
//        _hud.addChild( _xp );
        _xp.x = 320;
        _xp.y = 35; 
        
        _xpText = TextFieldUtil.createField("", {mouseEnabled:false, selectable:false});
        _xpText.x = 50;
        _xp.addChild( _xpText );
        
        
        //Quit button
        var quitButton :SimpleTextButton = new SimpleTextButton( "Quit" );
        quitButton.x = startX;
        button.y = startY;
        startX += 90;
        Command.bind( quitButton, MouseEvent.CLICK, VampireController.QUIT);
//        _hud.addChild( quitButton );
        
        
        _action = TextFieldUtil.createField("Action: ", {mouseEnabled:false, selectable:false, x:300, y:45});
//        _hud.addChild( _action );
        
        _level = TextFieldUtil.createField("Level: ", {mouseEnabled:false, selectable:false, x:300, y:65});
//        _hud.addChild( _level );
        
        _target = TextFieldUtil.createField("Target: ", {mouseEnabled:false, selectable:false, x:300, y:85, width:400});
//        _hud.addChild( _target );
        
        _bloodbonds = TextFieldUtil.createField("Bloodbonds: ", {mouseEnabled:false, selectable:false, x:300, y:105, width:300});
//        _hud.addChild( _bloodbonds );
        
        _time = TextFieldUtil.createField("Time: ", {mouseEnabled:false, selectable:false, x:300, y:125, width:450});
//        _hud.addChild( _time );
        
        _myName = TextFieldUtil.createField("Me: Testing locally", {mouseEnabled:false, selectable:false, x:20, y:35, width:150});
        if( !VConstants.LOCAL_DEBUG_MODE) {
            _myName = TextFieldUtil.createField("Me: " + ClientContext.gameCtrl.room.getAvatarInfo( ClientContext.ourPlayerId).name, {mouseEnabled:false, selectable:false, x:20, y:35, width:150});
        }
            
//        _hud.addChild( _myName );
        
        //The target overlay
        _targetSprite = new Sprite();
        _displaySprite.addChild( _targetSprite );
//        _targetSprite.graphics.lineStyle(4, 0xcc0000);
//        _targetSprite.graphics.drawCircle(0, 0, 20);
        _targetSprite.visible = false;
        
        _targetSpriteBlood = ClientContext.instantiateMovieClip("HUD", "target_blood_meter", true);
        _targetSprite.addChild( _targetSpriteBlood );
        
        _targetSpriteBloodText = TextFieldUtil.createField("", {mouseEnabled:false, selectable:false});
        _targetSpriteBlood.addChild( _targetSpriteBloodText );
        
        _targetSpriteBloodBondIcon = ClientContext.instantiateMovieClip("HUD", "bond_icon", true);
        _targetSpriteHierarchyIcon = ClientContext.instantiateButton("HUD", "button_hierarchy_no_mouse");
        
    }
    
    override protected function update(dt:Number):void
    {
        //Show feedback messages in queue, and fade out old messages.
        if( _feedbackMessageQueue.length > 0 && db != null) {
            _feedbackMessageTimeElapsed += dt;
            
            if( _feedbackMessageTimeElapsed > VConstants.TIME_FEEDBACK_MESSAGE_DISPLAY ) {
                _feedbackMessageTimeElapsed = 0;
                var feedbackMessage :String = _feedbackMessageQueue.shift() as String;
                if( feedbackMessage != null ) {
                    
                    var textSprite :Sprite = new Sprite();
                    
                    var feedbackMessageTextField :TextField = 
                        TextFieldUtil.createField(feedbackMessage);
                    feedbackMessageTextField.selectable = false;
                    feedbackMessageTextField.tabEnabled = false;
                    feedbackMessageTextField.embedFonts = true;
                    
                    var lineageformat :TextFormat = new TextFormat();
                    lineageformat.font = "JuiceEmbedded";
                    lineageformat.size = 24.;
                    lineageformat.color = 0x000000;
                    lineageformat.align = TextFormatAlign.RIGHT;
                    lineageformat.bold = true;
                    feedbackMessageTextField.setTextFormat( lineageformat );
                    feedbackMessageTextField.textColor = _hudFeedback.textColor;
                    feedbackMessageTextField.width = _hudFeedback.width;
                    feedbackMessageTextField.height = _hudFeedback.height;
                    feedbackMessageTextField.x = _hudFeedback.x - 10;
                    feedbackMessageTextField.y = _hudFeedback.y + 10;
                    feedbackMessageTextField.multiline = _hudFeedback.multiline;
                    
                    
                    
                    var shadowText :TextField = 
                        TextFieldUtil.createField(feedbackMessage);
                    shadowText.selectable = false;
                    shadowText.tabEnabled = false;
                    shadowText.embedFonts = true;
                    
                    shadowText.setTextFormat( lineageformat );
                    shadowText.textColor = 0xffffff;
                    shadowText.width = _hudFeedback.width;
                    shadowText.height = _hudFeedback.height;
                    shadowText.x = _hudFeedback.x - 10;
                    shadowText.y = _hudFeedback.y + 10;
                    shadowText.multiline = _hudFeedback.multiline;
                    
                    var blurredShadow:DropShadowFilter = new DropShadowFilter(0.8, 0, 0xffffff, 1.0, 5, 5, 1000 );
                    var storedBlurShadow :Array = [blurredShadow];
                    shadowText.filters = storedBlurShadow;
                    
                    
                    textSprite.addChild( shadowText );
                    textSprite.addChild( feedbackMessageTextField );
                    
                    
                    var textSceneObject :SimpleSceneObject = 
                        new SimpleSceneObject( textSprite );
                    db.addObject( textSceneObject, _hudMC);
                    
                    var serialTask :SerialTask = new SerialTask();
                    serialTask.addTask( 
                        new TimedTask( VConstants.TIME_FEEDBACK_MESSAGE_DISPLAY * 0.9 ));
                    serialTask.addTask( new SelfDestructTask() );  
                    textSceneObject.addTask( serialTask );
                    
                }
            }
        }
        
//        _DEBUGGING_add_feedback_timer += dt;
//        if( _DEBUGGING_add_feedback_timer > 2 ) {
//            _DEBUGGING_add_feedback_timer = 0;
//            
//            _feedbackMessageQueue.push(generateRandomString(Rand.nextIntRange(10, 40, 0)));
//            trace("_feedbackMessageQueue=" + _feedbackMessageQueue);
//        }
    }
    
    public function showFeedBack( msg :String ) :void
    {
        _feedbackMessageQueue.push( msg )
    }
    
    
    protected function playerUpdated( e :PlayerStateChangedEvent ) :void
    {
        if( e.playerId == ClientContext.ourPlayerId) {
            updateOurPlayerState();
        }
    }
    
    public function updateOurPlayerState( ...ignored ) :void
    {
        
        
        
        if( !SharedPlayerStateClient.isProps( ClientContext.ourPlayerId )) {
            log.warning("updatePlayerState, but no props found");
            return;
        }
        
        
        showBlood( ClientContext.ourPlayerId );
        showXP( ClientContext.ourPlayerId );
        showLevel( ClientContext.ourPlayerId );
        showBloodBonds( ClientContext.ourPlayerId );
        showAction( ClientContext.ourPlayerId );
        showTime( ClientContext.ourPlayerId );
        showTarget( ClientContext.ourPlayerId );
        
    }
    
    protected function showBlood( playerId :int ) :void
    {
        if( SharedPlayerStateClient.getMaxBlood( playerId ) > 0) {
            var scaleY :Number = SharedPlayerStateClient.getMaxBlood( playerId ) / VConstants.MAX_BLOOD_FOR_LEVEL(1);
            _hudBlood.scaleY = scaleY;
//            _hudBlood.height = SharedPlayerStateClient.getMaxBlood( playerId );
            _hudBlood.gotoAndStop( int( (SharedPlayerStateClient.getBlood( playerId ) * 100.0) / SharedPlayerStateClient.getMaxBlood( playerId )));
        }
        else {
            _hudBlood.gotoAndStop(0);
        }
//        _hudBlood.y = _hudBloodBottom - _hudBlood.height;
        
//        _DEBUG_BLOOD_BAR_OUTLINE.graphics.clear();
//        _DEBUG_BLOOD_BAR_OUTLINE.graphics.lineStyle(1, 0xffffff);
//        _DEBUG_BLOOD_BAR_OUTLINE.graphics.drawRect(-_hudBlood.width/2, -_hudBlood.height/2, _hudBlood.width, _hudBlood.height);
//        _DEBUG_BLOOD_BAR_OUTLINE.x = _hudBlood.x;
//        _DEBUG_BLOOD_BAR_OUTLINE.y = _hudBlood.y;
        
        
//        log.debug("Showing player blood=" + SharedPlayerStateClient.getBlood( playerId ) + "/" + SharedPlayerStateClient.getMaxBlood( playerId ));
//        _blood.graphics.clear();
//        var bloodColor :int = SharedPlayerStateClient.isVampire( playerId ) ? 0xcc0000 : 0x0000ff;//Red or blue for vampire or thrall
//        _blood.graphics.lineStyle(1, bloodColor);
//        _blood.graphics.drawRect(0, 0, 100, 10);
//        _blood.graphics.beginFill( bloodColor );
//        if( SharedPlayerStateClient.getMaxBlood( playerId ) > 0) {
//            _blood.graphics.drawRect(0, 0, (SharedPlayerStateClient.getBlood( playerId ) * 100.0) / SharedPlayerStateClient.getMaxBlood( playerId ), 10);
//        }
//        _blood.graphics.endFill();
//        
//        var bloodtext :String = "" + SharedPlayerStateClient.getBlood( playerId );
//        if( bloodtext.indexOf(".") >= 0) {
//            bloodtext = bloodtext.slice(0, bloodtext.indexOf(".") + 3);
//        }
//        _bloodText.text = bloodtext;
        
    }
    
    protected function showXP( playerId :int ) :void
    {
        showBlood( playerId );
        var xp :int = ClientContext.model.xp;
        
        var level :int = Logic.levelGivenCurrentXp( xp );
        
        var xpNeededForNextLevel :int = Logic.xpNeededForLevel( level + 1);
        var xpNeededForLevel :int = Logic.xpNeededForLevel( level );
        
        var xpOverCurrentLevelMinimum :int = xp - xpNeededForLevel;
        var xpDifference :int = xpNeededForNextLevel - xpNeededForLevel;
        
//        trace("xpOverCurrentLevelMinimum=" + xpOverCurrentLevelMinimum);
//        trace("xpDifference=" + xpDifference);
//        trace("Logic.xpNeededForLevel(2)=" + Logic.xpNeededForLevel(2));
//        var scaleY :Number = Number(xpDifference) / Logic.xpNeededForLevel(2);
//        var scaleY :Number = _hudBlood.height / _hudXP.height;
        _hudXP.scaleY = _hudBlood.scaleY;
        
        var scaledXP :int = xpOverCurrentLevelMinimum * 100 / xpDifference;
        _hudXP.gotoAndStop(scaledXP);
        
//        if( SharedPlayerStateClient.getMaxBlood( playerId ) > 0) {
//            _hudBlood.scaleY = scaleY;
////            _hudBlood.height = SharedPlayerStateClient.getMaxBlood( playerId );
//            _hudBlood.gotoAndStop( int( (SharedPlayerStateClient.getBlood( playerId ) * 100.0) / SharedPlayerStateClient.getMaxBlood( playerId )));
//        }
//        else {
//            _hudBlood.gotoAndStop(0);
//        }
        
        
//        var currentXp :int = SharedPlayerStateClient.getXP( playerId ) ;
//        var xpForNextLevel :int = Logic.xpNeededForLevel(SharedPlayerStateClient.getLevel(playerId) + 1);
//        var xpForCurrentLevelLevel :int = Logic.xpNeededForLevel(SharedPlayerStateClient.getLevel(playerId));
//        log.debug("Showing player xp=" + currentXp + "/" + xpForNextLevel);
//        _xp.graphics.clear();
//        var xpColor :int = 0x009900;//Green
//        _xp.graphics.lineStyle(1, xpColor);
//        _xp.graphics.drawRect(0, 0, 100, 10);
//        _xp.graphics.beginFill( xpColor );
//        if( xpForNextLevel > 0) {
//            _xp.graphics.drawRect(0, 0, (Math.max(0, (currentXp - xpForCurrentLevelLevel)) * 100.0) / (xpForNextLevel - xpForCurrentLevelLevel), 10);
//        }
//        _xp.graphics.endFill();
//        
//        var xptext :String = "" + currentXp + "/" + xpForNextLevel;
//        _xpText.text = xptext;
        
    }
    
    protected function showBloodBonds( playerId :int ) :void
    {
//        var bloodbondedArray :Array = SharedPlayerStateClient.getBloodBonded(ClientContext.ourPlayerId);
//        if( bloodbondedArray == null) {
//            _bloodbonds.text = "Bloodbonds: null" ;
//            return;
//        }
//        var sb :StringBuilder = new StringBuilder();
//        
//        for( var i :int = 0; i < bloodbondedArray.length; i += 2) {
//            sb.append(bloodbondedArray[ i + 1] + " ");
//        }
        _bloodbonds.text = "Bloodbond: " + ClientContext.model.bloodbondedName + " " + (ClientContext.model.bloodbonded > 0 ? ClientContext.model.bloodbonded : "" );
    }
    
    protected function showLevel( playerId :int ) :void
    {
        _level.text = "Level: " + SharedPlayerStateClient.getLevel( ClientContext.ourPlayerId );
        showXP( playerId );
    }
    
    protected function showAction( playerId :int ) :void
    {
        _action.text = "Action: " + SharedPlayerStateClient.getCurrentAction( ClientContext.ourPlayerId );
    }
    protected function showTarget( playerId :int ) :void
    {
        _targetSprite.visible = false;
        _targetSprite.graphics.clear();
        
        if( _targetSpriteHierarchyIcon != null && _targetSprite.contains( _targetSpriteHierarchyIcon)) {
            _targetSprite.removeChild( _targetSpriteHierarchyIcon);
        }
        if( _targetSpriteBloodBondIcon != null && _targetSprite.contains( _targetSpriteBloodBondIcon)) {
            _targetSprite.removeChild( _targetSpriteBloodBondIcon);
        }
        
        
        
        
        var targetId :int = SharedPlayerStateClient.getTargetPlayer( playerId );
        var targetLocation :Array = SharedPlayerStateClient.getTargetLocation( playerId );
        var targetHotspot :Array = SharedPlayerStateClient.getTargetHotspot( playerId );
        trace("HUD showTarget(), targetId=" + targetId + ", targetLocation=" + targetLocation + ", targetHotspot=" + targetHotspot );
        
        _targetSpriteBlood.graphics.clear();
         _targetSpriteBloodText.text = "";
        if( !SharedPlayerStateClient.getTargetVisible( playerId )) {
            return;
        }
        
        if(( targetId > 0 && targetLocation != null && targetHotspot != null && targetHotspot.length > 1) || VConstants.LOCAL_DEBUG_MODE) {
            _targetSprite.visible = true;
            _target.text = "Target: " + SharedPlayerStateClient.getTargetName( playerId );
            
            
//            var halfTargetAvatarHeight :Number = targetHotspot*0.5/ClientContext.gameCtrl.local.getRoomBounds()[1];
            var p :Point;
            if( VConstants.LOCAL_DEBUG_MODE ) {
                p = new Point( 400, 400);
            }
            else {
                var targetAvatarHeight :Number = targetHotspot[1]/ClientContext.gameCtrl.local.getRoomBounds()[1];
                p = ClientContext.gameCtrl.local.locationToPaintable( targetLocation[0], targetAvatarHeight, targetLocation[2]) as Point;
            }
//            p.y -= targetHotspot[1];
            _targetSprite.x = p.x;
            _targetSprite.y = p.y;
            
            _targetSprite.visible = true;
//            _targetSprite.x = targetHotspot[0];
//            _targetSprite.y = targetHotspot[1] - 30;
            
            //Show the targets blood
            var targetBlood :Number = SharedPlayerStateClient.getTargetBlood( playerId );
            var targetMaxBlood :Number = SharedPlayerStateClient.getTargetMaxBlood( playerId );
            
//            trace("showTarget() targetBlood=" + targetBlood); 
//            trace("showTarget() targetMaxBlood=" + targetMaxBlood);
            
            if( !isNaN( targetBlood ) && !isNaN( targetMaxBlood ) ) {
                
                
//                var pointForBloodBar :Point = ClientContext.gameCtrl.local.locationToPaintable( targetLocation[0], targetAvatarHeight, targetLocation[2]) as Point;
//                pointForBloodBar.y = pointForBloodBar.y - 30;//Adjust to be over the player name
//                _targetSpriteBlood.x = pointForBloodBar.x;
//                _targetSpriteBlood.y = pointForBloodBar.y;
//                var bloodColor :int =  0xcc0000;
//                _targetSpriteBlood.y = -30;
//                _targetSpriteBlood.graphics.lineStyle(1, bloodColor);
//                _targetSpriteBlood.graphics.drawRect(-50, -5, 100, 10);
//                _targetSpriteBlood.graphics.beginFill( bloodColor );
                
                _targetSpriteBlood.width = targetMaxBlood;
                
                if( targetBlood > 0 && targetMaxBlood > 0) {
//                    _targetSpriteBlood.graphics.drawRect(-50, -5, (targetBlood * 100.0) / targetMaxBlood, 10);
                    _targetSpriteBlood.gotoAndStop((targetBlood * 100.0) / targetMaxBlood);
                }
//                _targetSpriteBlood.graphics.endFill();
                
                var bloodtext :String = "" + targetBlood;
                if( bloodtext.indexOf(".") >= 0) {
                    bloodtext = bloodtext.slice(0, bloodtext.indexOf(".") + 3);
                }
                _targetSpriteBloodText.text = bloodtext;
                
                
                _targetSprite.graphics.lineStyle(1, 0xffffff);
                _targetSprite.graphics.drawRect( _targetSpriteBlood.x, _targetSpriteBlood.y, _targetSpriteBlood.width, _targetSpriteBlood.height);
                
  
            }
            else {
                _targetSpriteBloodText.text = "";
            }
        
           //Show hierarchy and bloodbond icons if appropriate
           trace("ClientContext.model.targetPlayerId=" + ClientContext.model.targetPlayerId);
           trace("ClientContext.model.bloodbonded=" + ClientContext.model.bloodbonded);
           if( VConstants.LOCAL_DEBUG_MODE || ClientContext.model.targetPlayerId == ClientContext.model.bloodbonded) {
               trace("Showing bloodbond icon");
               _targetSprite.addChild( _targetSpriteBloodBondIcon );
               _targetSpriteBloodBondIcon.x = _targetSpriteBlood.x - _targetSpriteBlood.width/2;
               _targetSpriteBloodBondIcon.y = _targetSpriteBlood.y - _targetSpriteBlood.height;
           }
           
           if( VConstants.LOCAL_DEBUG_MODE || ClientContext.model.hierarchy.isPlayerSireOrMinionOfPlayer( targetId, playerId)) {
               _targetSprite.addChild( _targetSpriteHierarchyIcon );
               _targetSpriteHierarchyIcon.x = _targetSpriteBlood.x - _targetSpriteBlood.width/2 + _targetSpriteBlood.width * 2;
               _targetSpriteHierarchyIcon.y = _targetSpriteBlood.y - _targetSpriteBlood.height;
           }
                
        }
        else {
            log.error("showTarget, but " , "location", targetLocation, "targetHotspot", targetHotspot);
        }
        
    }
    
    protected function showTime( playerId :int ) :void
    {
        var date :Date = new Date( SharedPlayerStateClient.getTime( ClientContext.ourPlayerId ) );
        _time.text = "Quit last game at: " + date.toLocaleTimeString() + " " + date.toDateString();
        
        if( SharedPlayerStateClient.getTime( ClientContext.ourPlayerId ) == 1 ) {
            if( ClientContext.game.ctx.mainLoop.topMode !== new IntroHelpMode() ) {
                ClientContext.game.ctx.mainLoop.pushMode( new IntroHelpMode());
            } 
        }
    }
    
    public function get avatarOverlay() :VampireAvatarHUDOverlay
    {
        return _targetingOverlay;
    }
    
    //Debugging purposes
    protected static function generateRandomString(newLength:uint = 1, userAlphabet:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"):String
    {
        var alphabet:Array = userAlphabet.split("");
        var alphabetLength:int = alphabet.length;
        var randomLetters:String = "";
        for (var i:uint = 0; i < newLength; i++){
            randomLetters += alphabet[int(Math.floor(Math.random() * alphabetLength))];
        }
        return randomLetters;
    }

    protected var _displaySprite :Sprite;
    protected var _hud :DraggableSprite;
    protected var _hudMC :MovieClip;
    
    protected var _hudBlood :MovieClip;
    protected var _hudBloodBottom :int;
    protected var _hudBloodStartHeight :Number;
    
    protected var _hudXP :MovieClip;
    protected var _hudXPBottom :int;
    protected var _hudXPStartHeight :Number;
    
    protected var _hudFeedback :TextField;
    
    protected var _blood :Sprite;
    protected var _bloodText :TextField;
    
//    protected var _DEBUG_BLOOD_BAR_OUTLINE :Sprite;
    
    protected var _xp :Sprite;
    protected var _xpText :TextField;
    
    
    protected var _action :TextField;
    protected var _level :TextField;
    protected var _target :TextField;
    protected var _myName :TextField;
    protected var _bloodbonds :TextField;
    protected var _time :TextField;
    
    
    
    protected var _targetSprite :Sprite;
    protected var _targetSpriteBlood :MovieClip;
    protected var _targetSpriteBloodText :TextField;
    
    protected var _targetSpriteBloodBondIcon :MovieClip;
    protected var _targetSpriteHierarchyIcon :SimpleButton;
    
    protected var _targetingOverlay :VampireAvatarHUDOverlay;
    
    protected var _feedbackMessageQueue :Array = new Array();
    protected var _feedbackMessageTimeElapsed :Number = 0;
    
    protected var _DEBUGGING_add_feedback_timer :Number = 0;
    
//    protected var _checkRoomProps2ShowStatsTimer :Timer;//Stupid hack, the first time a player enters a room, the 
    
    protected static const log :Log = Log.getLog( HUD );
}

}