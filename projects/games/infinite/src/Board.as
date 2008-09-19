package
{
	import arithmetic.BoardCoordinates;
	
	public interface Board extends BoardAccess
	{		
		/**
		 * Get the starting position for a new user entering this board.
		 */
		function get startingPosition () :BoardCoordinates
	}
}