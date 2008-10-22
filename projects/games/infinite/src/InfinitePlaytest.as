package {
	import com.whirled.game.GameControl;
	
	import flash.display.Sprite;
	
	import sprites.*;
	
	import world.InfiniteWorld;
	import world.LocalWorld;
	import world.RemoteWorld;

	[SWF(width="700", height="500")]
	public class InfinitePlaytest extends Sprite
	{
		public function InfinitePlaytest()
		{
			_gameControl = new GameControl(this);
			
			const world:InfiniteWorld =
			     _gameControl.isConnected() ? new RemoteWorld(_gameControl) : new LocalWorld();
			
			addChild(new Client(world));
		}				

		/**
		 * The compiler in flexbuilder starts from this class and compiles all of the reachable code.
		 * Under normal circumstances, this means that the server code isn't built.   This method
		 * is never called, but is used to create reachability from the 'main' client class to the server
		 * code.
		 */
		public function compileServer () :void
		{
			const server:Server = new Server();
		}
		
		protected var _gameControl:GameControl;
	}
}