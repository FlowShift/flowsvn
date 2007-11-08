package {

import mx.core.MovieClipAsset;
import flash.media.Sound;
import flash.media.SoundTransform;

public class SaucerShipType extends ShipType
{
    public function SaucerShipType () :void
    {
        name = "Saucer";

        turnAccelRate = 4.0;
        forwardAccel = 0.17;
        backwardAccel = 0.0;
        friction = 0.6;
        turnFriction = 0.5;

        hitPower = 0.2;

        primaryShotCost = 0.2;
        primaryPowerRecharge = 6.0;
        primaryShotRecharge = 0.1;
        primaryShotSpeed = 10;
        primaryShotLife = 0.5;
        primaryShotSize = 0.4;

        armor = 0.8;
        size = 0.9;
        ENGINE_MOV.gotoAndStop(2);
    }

    override public function primaryShot (sf :StarFight, val :Array) :void
    {

    }

    // Shooting sounds.
    [Embed(source="rsrc/ships/wasp/beam.mp3")]
    protected static var beamSound :Class;

    public const BEAM :Sound = Sound(new beamSound());

    [Embed(source="rsrc/ships/wasp/beam_tri.mp3")]
    protected static var triBeamSound :Class;

    public const TRI_BEAM :Sound = Sound(new triBeamSound());

    // Ship spawning.
    [Embed(source="rsrc/ships/wasp/spawn.mp3")]
    protected static var spawnSound :Class;

    public const SPAWN :Sound = Sound(new spawnSound());

    // Looping sound - this is a movieclip to make the looping work without
    //  hiccups.  This is pretty hacky - we can't control the looping sound
    //  appropriately, so we just manipulate the volume.  So, the sounds are
    //  always running, just sometimes really quietly.  Bleh.

    // Engine hum.
    [Embed(source="rsrc/ships/wasp/engine_sound.swf#sound_main")]
    protected static var engineSound :Class;

    public const ENGINE_MOV :MovieClipAsset =
        MovieClipAsset(new engineSound());

    // Animations
    [Embed(source="rsrc/ships/saucer/ship.swf#ship_movie_01")]
    public const SHIP_ANIM :Class;

    [Embed(source="rsrc/ships/saucer/ship_shield.swf")]
    public const SHIELD_ANIM :Class;

    [Embed(source="rsrc/ships/saucer/ship_explosion_big.swf")]
    public const EXPLODE_ANIM :Class;

    [Embed(source="rsrc/ships/saucer/beam.swf")]
    public const SHOT_ANIM :Class;

}
}
