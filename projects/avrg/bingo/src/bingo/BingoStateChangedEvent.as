package bingo {
    
import flash.events.Event;

public class BingoStateChangedEvent extends Event
{
    public static const NEW_ROUND :String = "newRound";
    public static const NEW_BALL :String = "newBall";
    public static const PLAYER_WON_ROUND :String = "playerWonRound";
    
    public function BingoStateChangedEvent (type :String)
    {
        super(type, false, false);
    }
    
}

}