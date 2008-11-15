package
{
	import arithmetic.Vector;
	
	/**
	 * A collection of values that can be tweaked to taste.
	 */
	public class Config
	{		
		// Show a yellow box over the viewpoint.
		public static const showViewPoint:Boolean = false;
		
		// Show the debug board
		public static const boardDebug:Boolean = false;
		
		// Display a debug overlay on cells.
		public static const cellDebug:Boolean = false;
		
		// Set the unit size of a cell.
		public static const cellSize:Vector = new Vector(100, 100);		
	}
}