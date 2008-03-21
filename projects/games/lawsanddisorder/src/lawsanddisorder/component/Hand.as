﻿package lawsanddisorder.component {

import flash.display.Sprite;
import flash.geom.Point;
import flash.text.TextField;
import flash.events.MouseEvent;

import lawsanddisorder.*;

/**
 * Container for a player's cards.
 */
public class Hand extends CardContainer
{
    /** The name of the hand data distributed value. */
    public static const HAND_DATA :String = "handData";
    
    /**
     * Constructor
     */
    public function Hand (ctx :Context, player :Player)
    {
        this.player = player;
        ctx.eventHandler.addDataListener(HAND_DATA, handChanged, player.id);
        super(ctx);
    }
    
    /**
     * Called by first user during game start.  Remove any cards and draw a fresh hand.
     */
    public function setup () :void
    {
    	clearCards();
    	var cardArray :Array = _ctx.board.deck.drawStartingHand(DEFAULT_HAND_SIZE);
        addCards(cardArray);
    }
    
    /**
     * Rearrange hand when cards are added or subtracted
     */
    override protected function updateDisplay () :void
    {
    	arrangeCards();
    }
    
    /*
     * TODO fix issue with this and use it instead of discard down?
     *      Issue is this function doesn't block other players from doing things that interfere
     * Override addCards to force discard first if too many cards in hand
     *
    override public function addCards (cardArray :Array, distribute :Boolean = true, insertIndex :int = -1) :void
    {
    	var discardNum :int = cards.length + cardArray.length - MAX_HAND_SIZE;
    	if (discardNum > 0) {
            _ctx.notice("You may not have more than " + MAX_HAND_SIZE + " cards.  Please choose and discard " + discardNum);
            //discardDownListener = listener;
            var cardsSelectedListener :Function = function () :void {
                player.loseCards(_ctx.state.selectedCards);
                _ctx.state.deselectCards();
                addCards(cardArray, distribute, insertIndex);
            };
            _ctx.state.selectCards(discardNum, cardsSelectedListener);
    	}
    	else {
    		_ctx.log("yer cards are fine");
    	   super.addCards(cardArray, distribute, insertIndex);
    	}
    }
    */
    
    /**
     * Draw a card (or X cards, if numCards is provided) from the deck.
     */
    public function drawCard (numCards :int = 1) :void
    {
        var cardArray :Array = new Array();
        for (var i :int = 1; i <= numCards; i++) {
            var card :Card = _ctx.board.deck.drawCard();
            if (card == null) {
            	// no more cards in the deck!
                break;
            }
            cardArray.push(card);
        }
        addCards(cardArray);
        
        // if the deck is ever empty after drawing from it, game ends
        // TODO move this to deck and go one more round
        if (_ctx.board.deck.numCards == 0) {
        	_ctx.eventHandler.endGame();
        }
    }
	
	/**
	 * Return true if the global coordinates are within the area of the hand.
	 */
	override public function hitTestPoint(x:Number, y:Number, shapeFlag:Boolean = false) :Boolean
	{
		// Bounding region is 0, 0, 690, 90
		var globalPoint :Point = new Point(x, y);
		var localPoint :Point = globalToLocal(globalPoint);
		if (localPoint.x >= 0 && localPoint.y >= 0 && localPoint.x <= 690 &&  localPoint.y <= 90) {
			return true;
		}
		return false;
	}
    
    /**
     * Called whenever distributed card data needs updating
     */
    override protected function setDistributedData () :void
    {
        _ctx.eventHandler.setData(HAND_DATA, getSerializedCards(), player.id);
    }
    
    /**
     * Public function to allow setting distributed hand data
     * TODO make setDistributedData public or find another solution
     */
    public function setDistributedHandData () :void
    {
    	setDistributedData();
    }
    
    /**
     * Returns the index of the card at a given global point, or -1 for none.
     */
    override public function getCardIndexByPoint (point :Point) :int
    {
        var localPoint :Point = globalToLocal(point);
        // cards are spaced CARD_SPACING_X apart starting at 0
    	var cardSpacingX :int = CARD_SPACING_X;
		var numCards :int = (point == null) ? cards.length : cards.length + 1;
    	if (numCards > (MAX_HAND_SIZE)) {
    		cardSpacingX = ((MAX_HAND_SIZE) * CARD_SPACING_X) / numCards;
    	}
        var index :int = Math.floor(localPoint.x / cardSpacingX);
        if (index < 0) {
        	index = 0;
        }
        if (index > cards.length) {
        	index = cards.length;
        }
        return index;
    }
    
    /**
     * Shift cards out of the way as another card is being dragged over them.
	 * TODO move this to CardContainer for both Hand and NewLaw
     */
    override public function arrangeCards (point :Point = null) :void
    {
    	var i :int;
    	var card :Card;
    	
    	// adjust the spacing depeding on the number of cards
    	var cardSpacingX :int = CARD_SPACING_X;
		var numCards :int = (point == null) ? cards.length : cards.length + 1;
    	if (numCards > (MAX_HAND_SIZE)) {
    		cardSpacingX = ((MAX_HAND_SIZE) * CARD_SPACING_X) / numCards;
    	}
    	
    	// if no point is supplied, arrange as normal.
    	if (point == null) {
	        for (i = 0; i < cards.length; i++) {
	            card = cards[i];
	            card.x = i * cardSpacingX;
	            card.y = 10;
	        }
	        return;
    	}
    	
        // localize the point to our coordinate map
        var localPoint :Point = globalToLocal(point);
        
        // position the cards horizontally
        for (i = 0; i < cards.length; i++) {
            card = cards[i];
            // if the card would overlap the point or be to its right, shift it right
            if ((i+1) * cardSpacingX > localPoint.x) {
                card.x = (i+1) * cardSpacingX;
            }
            else {
                card.x = i * cardSpacingX;
            }
        }
    }
    
    /**
     * Handler for changes to distributed hand data.  If it's data for this hand,
     * update the hand display.
     */
    protected function handChanged (event :DataChangedEvent) :void
    {
        setSerializedCards(event.newValue);
    }
    
    /**
     * If player has more than the maximum allowed number of cards in their hand, force them to
     * select and discard the excess number of cards.  When finished, call the listener function.
     */
    public function discardDown (listener :Function) :void
    {
    	if (cards.length <= MAX_HAND_SIZE) {
    		listener();
    		return;
    	}
    	_ctx.notice("You have too many cards... please discard down to " + MAX_HAND_SIZE);
    	discardDownListener = listener;
    	_ctx.state.selectCards(cards.length - MAX_HAND_SIZE, discardDownCardsSelected);
    }
    
    /**
     * Called when the player has selected cards to be discarded.
     */
    protected function discardDownCardsSelected () :void
    {
    	player.loseCards(_ctx.state.selectedCards);
    	_ctx.state.deselectCards();
    	discardDownListener();
    }
        
    /**
     * Called when the player leaves the game; remove listeners
     */
    public function unload () :void
    {
        _ctx.eventHandler.removeDataListener(HAND_DATA, handChanged, player.id);
    }
    
    /**
     * Pick and return an array of random cards from this hand.     */
    public function getRandomCards (numCards :int = 1) :Array
    {
    	// make a copy of the cards array
        var availableCards :Array = new Array();
        for each (var card :Card in cards) {
            availableCards.push(card);
        }
        
        var randomCards :Array = new Array();
        for (var i :int = 0; i < numCards; i++) {
	    	// pick a random card (from zero to length-1)
	        var randomIndex :int = Math.round(Math.random() * (availableCards.length-1));
	        var randomCard :Card = availableCards[randomIndex];
	        availableCards.splice(randomIndex, 1);
	        randomCards.push(randomCard);
        }
        
	    return randomCards;
    }
    
    /** Record the listener function while selecting cards to discard. */
    protected var discardDownListener :Function;
    
    /** Player owning this hand */
    protected var player :Player;
    
    /** Player must go down to this many cards at end of turn */
    protected var MAX_HAND_SIZE :int = 11;
    
    /** Draw this number of cards at the start of the game */
    protected var DEFAULT_HAND_SIZE :int = 7;
    
    /** distance between the left edges of cards */
    protected static const CARD_SPACING_X :int = 57;
}
}