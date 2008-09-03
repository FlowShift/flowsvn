package client {

import com.threerings.util.MultiLoader;

import flash.media.Sound;
import flash.system.ApplicationDomain;

public class ShipTypeResources
{
    public var shipAnim :Class, shieldAnim :Class, explodeAnim :Class, shotAnim :Class,
        secondaryAnim :Class;
    public var shotSound :Sound, supShotSound :Sound, spawnSound :Sound, engineSound :Sound;

    public function setShipType (shipType :ShipType) :void
    {
        shipType.addEventListener(ShipType.PRIMARY_SHOT_CREATED,
            function (event :ShotCreatedEvent) :void {
                primaryShotCreated(AppContext.game.getShip(event.args[0]), event.args);
            });

        shipType.addEventListener(ShipType.SECONDARY_SHOT_CREATED,
            function (event :ShotCreatedEvent) :void {
                secondaryShotCreated(AppContext.game.getShip(event.args[0]), event.args);
            });

        shipType.addEventListener(ShipType.PRIMARY_SHOT_SENT,
            function (event :ShotMessageSentEvent) :void {
                primaryShotMessageSent(event.ship);
            });

        shipType.addEventListener(ShipType.SECONDARY_SHOT_SENT,
            function (event :ShotMessageSentEvent) :void {
                secondaryShotMessageSent(event.ship);
            });
    }

    public function loadAssets (callback :Function) :void
    {
        _callback = callback;
        _resourcesDomain = new ApplicationDomain();
        MultiLoader.getLoaders(swfAsset, loadComplete, false, _resourcesDomain);
    }

    protected function primaryShotCreated (ship :Ship, args :Array) :void
    {
        // play a shooting sound
        var sound :Sound = (args[2] == Shot.SUPER) ? supShotSound : shotSound;
        ClientContext.game.playSoundAt(sound, args[3], args[4]);
    }

    protected function secondaryShotCreated (ship :Ship, args :Array) :void
    {
    }

    protected function primaryShotMessageSent (ship :Ship) :void
    {
    }

    protected function secondaryShotMessageSent (ship :Ship) :void
    {
    }

    protected function get swfAsset () :Class
    {
        return null;
    }

    protected function loadComplete (result :Object) :void
    {
        if (result is Error) {
            _callback(false);
        } else {
            _callback(true);
            successHandler();
        }
    }

    protected function successHandler () :void
    {
        shipAnim = getLoadedClass("ship");
        shieldAnim = getLoadedClass("ship_shield");
        explodeAnim = getLoadedClass("ship_explosion_big");
        shotAnim = getLoadedClass("beam");
        shotSound = Sound(new (getLoadedClass("beam.wav"))());
        supShotSound = Sound(new (getLoadedClass("beam_powerup.wav"))());
        spawnSound = Sound(new (getLoadedClass("spawn.wav"))());
        engineSound = Sound(new (getLoadedClass("engine_sound.wav"))());
    }

    protected function getLoadedClass (name :String) :Class
    {
        return _resourcesDomain.getDefinition(name) as Class;
    }

    protected var _resourcesDomain :ApplicationDomain;
    protected var _callback :Function;
}

}
