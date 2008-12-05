package cells.ladder
{
	import cells.CellCodes;
	
	import interactions.Sabotage;
	import interactions.SabotageType;
	
	import server.Messages.CellState;
	
	/** 
	 * An oiled ladder cell looks similar to a regular ladder, except that it causes the player to 
	 * fall on contact.
	 */
	public class OiledLadderTopCell extends LadderTopCell implements Sabotage
	{
		public function OiledLadderTopCell(owner:Owner, state:CellState) :void
		{
			super(owner, state.position);
			_saboteurId = state.attributes.saboteur;
		}
		
		override public function get code () :int
		{
			return CellCodes.OILED_LADDER_TOP;
		}
		
		override public function get type () :String 
		{ 
			return "oiled ladder top";
		}	
				
		/**
		 * An oily ladder cannot be gripped
		 */
		override public function get grip () :Boolean
		{			
			return ! isAboveGroundLevel();
		}
		
		public function get saboteurId () :int
		{
		    return _saboteurId;
		}

        public function get sabotageType () :String
        {
            return SabotageType.OILED;
        }
		
		protected var _saboteurId:int;
	}
}