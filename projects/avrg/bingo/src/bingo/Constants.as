package bingo {

import flash.geom.Point;

public class Constants
{
    public static const VERSION :Number = 2;

    public static const ALLOW_CHEATS :Boolean = true;
    public static const FORCE_SINGLEPLAYER :Boolean = false;

    // cosmetic bits
    public static const CARD_SCREEN_EDGE_OFFSET :Point = new Point(-460, 240);
    public static const HUD_SCREEN_EDGE_OFFSET :Point = new Point(-150, 240);

    // gameplay bits
    public static const CARD_WIDTH :int = 5;
    public static const CARD_HEIGHT :int = 5;
    public static const FREE_SPACE :Point = new Point(2, 2);

    public static const NEW_BALL_DELAY_S :Number = 7;
    public static const NEW_ROUND_DELAY_S :Number = 5;

    public static const USE_ITEM_NAMES_AS_TAGS :Boolean = false;
    public static const CARD_ITEMS_ARE_UNIQUE :Boolean = true;

    public static const MAX_MATCHES_PER_BALL :int = 999;

    public static const ITEMS :Array = [

        new BingoItem("Pearls", ["jewelry", "necklace", "beaded", "white", ], Resources.IMG_PEARLS),
        new BingoItem("choker", ["jewelry", "necklace", "gem", "pink", "black", ], Resources.IMG_CHOKER),
        new BingoItem("diamond necklace", ["jewelry", "necklace", "gem", "blue", ], Resources.IMG_DIAMONDNECKLACE),
        new BingoItem("brown shell necklace", ["jewelry", "necklace", "shell", "brown", ], Resources.IMG_SHELLNECKLACEBROWN),
        new BingoItem("blue shell necklace", ["jewelry", "necklace", "shell", "blue", ], Resources.IMG_SHELLNECKLACEBLUE),
        new BingoItem("gold locket", ["jewelry", "necklace", "locket", "gold", ], Resources.IMG_LOCKETGOLD),
        new BingoItem("silver locket", ["jewelry", "necklace", "locket", "silver", ], Resources.IMG_LOCKETSILVER),
        new BingoItem("yellow pendant", ["jewelry", "necklace", "pendant", "yellow", "gold", "gem", ], Resources.IMG_GOLDPENDANTYELLOW),
        new BingoItem("green pendant", ["jewelry", "necklace", "pendant", "green", "gold", "gem", ], Resources.IMG_GOLDPENDANTGREEN),
        new BingoItem("orange pendant", ["jewelry", "necklace", "pendant", "orange", "gold", "gem", ], Resources.IMG_GOLDPENDANTORANGE),
        new BingoItem("blue pendant", ["jewelry", "necklace", "pendant", "blue", "gold", "gem", ], Resources.IMG_GOLDPENDANTBLUE),
        new BingoItem("purple pendant", ["jewelry", "necklace", "pendant", "purple", "gold", "gem", ], Resources.IMG_GOLDPENDANTPURPLE),
        new BingoItem("pink pendant", ["jewelry", "necklace", "pendant", "pink", "gold", "gem", ], Resources.IMG_GOLDPENDANTPINK),
        new BingoItem("red pendant", ["jewelry", "necklace", "pendant", "red", "gold", "gem", ], Resources.IMG_GOLDPENDANTRED),
        new BingoItem("white pendant", ["jewelry", "necklace", "pendant", "white", "gold", "gem", ], Resources.IMG_GOLDPENDANTWHITE),
        new BingoItem("black pendant", ["jewelry", "necklace", "pendant", "black", "gold", "gem", ], Resources.IMG_GOLDPENDANTBLACK),
        new BingoItem("pearl earrings", ["head", "jewelry", "earrings", "beaded", "white", ], Resources.IMG_PEARLEARRINGS),
        new BingoItem("dangly earrings", ["head", "jewelry", "earrings", "dangly", "pink", ], Resources.IMG_DANGLYEARRINGSPINK),
        new BingoItem("dangly earrings", ["head", "jewelry", "earrings", "dangly", "green", ], Resources.IMG_DANGLYEARRINGSGREEN),
        new BingoItem("chandalier earrings", ["head", "jewelry", "earrings", "dangly", "pink", "gold", ], Resources.IMG_CHANDALIEREARRINGS),
        new BingoItem("gold diamond ring", ["hands", "jewelry", "ring", "gold", "gem", "blue", ], Resources.IMG_GOLDRINGDIAMOND),
        new BingoItem("gold ruby ring", ["hands", "jewelry", "ring", "gold", "gem", "red", ], Resources.IMG_GOLDRINGRUBY),
        new BingoItem("gold sapphire ring", ["hands", "jewelry", "ring", "gold", "gem", "blue", ], Resources.IMG_GOLDRINGSAPPHIRE),
        new BingoItem("gold emerald ring", ["hands", "jewelry", "ring", "gold", "gem", "green", ], Resources.IMG_GOLDRINGEMERALD),
        new BingoItem("gold peridot ring", ["hands", "jewelry", "ring", "gold", "gem", "green", ], Resources.IMG_GOLDRINGPERIDOT),
        new BingoItem("silver diamond ring", ["hands", "jewelry", "ring", "silver", "gem", "blue", ], Resources.IMG_SILVERRINGDIAMOND),
        new BingoItem("silver amethyst ring", ["hands", "jewelry", "ring", "silver", "gem", "purple", ], Resources.IMG_SILVERRINGAMETHYST),
        new BingoItem("silver zircon ring", ["hands", "jewelry", "ring", "silver", "gem", "pink", ], Resources.IMG_SILVERRINGPINK),
        new BingoItem("silver garnet ring", ["hands", "jewelry", "ring", "silver", "gem", "orange", ], Resources.IMG_SILVERRINGORANGE),
        new BingoItem("red/gold class ring", ["hands", "jewelry", "ring", "gold", "gem", "red", ], Resources.IMG_CLASSRINGRED),
        new BingoItem("purple/gold class ring", ["hands", "jewelry", "ring", "gold", "gem", "purple", ], Resources.IMG_CLASSRINGPURPLE),
        new BingoItem("blue/gold class ring", ["hands", "jewelry", "ring", "gold", "gem", "blue", ], Resources.IMG_CLASSRINGBLUE),
        new BingoItem("green/gold class ring", ["hands", "jewelry", "ring", "gold", "gem", "green", ], Resources.IMG_CLASSRINGGREEN),
        new BingoItem("red/silver class ring", ["hands", "jewelry", "ring", "silver", "gem", "red", ], Resources.IMG_CLASSRINGSILVERRED),
        new BingoItem("purple/silver class ring", ["hands", "jewelry", "ring", "silver", "gem", "purple", ], Resources.IMG_CLASSRINGSILVERPURPLE),
        new BingoItem("blue/silver class ring", ["hands", "jewelry", "ring", "silver", "gem", "blue", ], Resources.IMG_CLASSRINGSILVERBLUE),
        new BingoItem("green/silver class ring", ["hands", "jewelry", "ring", "silver", "gem", "green", ], Resources.IMG_CLASSRINGSILVERGREEN),
        new BingoItem("patterned heel 1", ["feet", "shoes", "heel", "pattern", "brown", "animal", ], Resources.IMG_HEELPATTERN01),
        new BingoItem("patterned heel 2", ["feet", "shoes", "heel", "pattern", "green", "polka-dot", ], Resources.IMG_HEELPATTERN02),
        new BingoItem("patterned heel 3", ["feet", "shoes", "heel", "pattern", "blue", "black", ], Resources.IMG_HEELPATTERN03),
        new BingoItem("patterned heel 4", ["feet", "shoes", "heel", "pattern", "white", "polka-dot", ], Resources.IMG_HEELPATTERN04),
        new BingoItem("patterned heel 5", ["feet", "shoes", "heel", "pattern", "pink", "purple", "orange", "brown", ], Resources.IMG_HEELPATTERN05),
        new BingoItem("short brown boot", ["feet", "shoes", "boot", "brown", "orange", "winter", "heel", ], Resources.IMG_SHORTBOOTBROWN),
        new BingoItem("short pink boot", ["feet", "shoes", "boot", "pink", "winter", "heel", ], Resources.IMG_SHORTBOOTPINK),
        new BingoItem("short blue boot", ["feet", "shoes", "boot", "blue", "winter", "heel", ], Resources.IMG_SHORTBOOTBLUE),
        new BingoItem("short black boot", ["feet", "shoes", "boot", "black", "winter", "heel", ], Resources.IMG_SHORTBOOTBLACK),
        new BingoItem("red boot", ["feet", "shoes", "boot", "red", "winter", "heel", ], Resources.IMG_TALLBOOTRED),
        new BingoItem("black boot", ["feet", "shoes", "boot", "black", "winter", "heel", ], Resources.IMG_TALLBOOTBLACK),
        new BingoItem("brown boot", ["feet", "shoes", "boot", "brown", "orange", "winter", "heel", ], Resources.IMG_TALLBOOTBROWN),
        new BingoItem("green boot", ["feet", "shoes", "boot", "green", "winter", "heel", ], Resources.IMG_TALLBOOTGREEN),
        new BingoItem("purple boot", ["feet", "shoes", "boot", "purple", "winter", "heel", ], Resources.IMG_TALLBOOTPURPLE),
        new BingoItem("silver boot", ["feet", "shoes", "boot", "silver", "winter", "heel", ], Resources.IMG_TALLBOOTSILVER),
        new BingoItem("pink fuzzy slipper", ["feet", "shoes", "flats", "pink", ], Resources.IMG_FUZZYSLIPPERPINK),
        new BingoItem("blue fuzzy slipper", ["feet", "shoes", "flats", "blue", ], Resources.IMG_FUZZYSLIPPERBLUE),
        new BingoItem("red fuzzy slipper", ["feet", "shoes", "flats", "red", ], Resources.IMG_FUZZYSLIPPERRED),
        new BingoItem("yellow fuzzy slipper", ["feet", "shoes", "flats", "yellow", ], Resources.IMG_FUZZYSLIPPERYELLOW),
        new BingoItem("black wedge", ["feet", "shoes", "wedge", "black", ], Resources.IMG_WEDGEBLACK),
        new BingoItem("green wedge", ["feet", "shoes", "wedge", "green", ], Resources.IMG_WEDGEGREEN),
        new BingoItem("red wedge", ["feet", "shoes", "wedge", "red", ], Resources.IMG_WEDGERED),
        new BingoItem("blue wedge", ["feet", "shoes", "wedge", "blue", ], Resources.IMG_WEDGEBLUE),
        new BingoItem("black sandal", ["feet", "shoes", "flats", "black", "brown", "summer", ], Resources.IMG_SANDALBLACK),
        new BingoItem("blue sandal", ["feet", "shoes", "flats", "blue", "brown", "summer", ], Resources.IMG_SANDALBLUE),
        new BingoItem("orange sandal", ["feet", "shoes", "flats", "orange", "brown", "summer", ], Resources.IMG_SANDALORANGE),
        new BingoItem("purple sandal", ["feet", "shoes", "flats", "purple", "brown", "summer", ], Resources.IMG_SANDALPURPLE),
        new BingoItem("red sandal", ["feet", "shoes", "flats", "red", "brown", "summer", ], Resources.IMG_SANDALRED),
        new BingoItem("green sandal", ["feet", "shoes", "flats", "green", "brown", "summer", ], Resources.IMG_SANDALSGREEN),
        new BingoItem("pink sandal", ["feet", "shoes", "flats", "pink", "brown", "summer", ], Resources.IMG_SANDALSPINK),
        new BingoItem("yellow sandal", ["feet", "shoes", "flats", "yellow", "brown", "summer", ], Resources.IMG_SANDALSYELLOW),
        new BingoItem("red flat", ["feet", "shoes", "flats", "red", "summer", ], Resources.IMG_FLATSRED),
        new BingoItem("pink flat", ["feet", "shoes", "flats", "pink", "summer", ], Resources.IMG_FLATSPINK),
        new BingoItem("purple flat", ["feet", "shoes", "flats", "purple", "summer", ], Resources.IMG_FLATSPURPLE),
        new BingoItem("blue flat", ["feet", "shoes", "flats", "blue", "summer", ], Resources.IMG_FLATSBLUE),
        new BingoItem("orange flat", ["feet", "shoes", "flats", "orange", "summer", ], Resources.IMG_FLATSORANGE),
        new BingoItem("green flat", ["feet", "shoes", "flats", "green", "summer", ], Resources.IMG_FLATSGREEN),
        new BingoItem("yellow flat", ["feet", "shoes", "flats", "yellow", "summer", ], Resources.IMG_FLATSYELLOW),
        new BingoItem("patterned flat 1", ["feet", "shoes", "flats", "pattern", "summer", "green", "floral", ], Resources.IMG_FLATSPATTERN01),
        new BingoItem("patterned flat 2", ["feet", "shoes", "flats", "pattern", "summer", "red", "orange", ], Resources.IMG_FLATSPATTERN02),
        new BingoItem("patterned flat 3", ["feet", "shoes", "flats", "pattern", "summer", "stripes", "animal", "black", "white", ], Resources.IMG_FLATSPATTERN03),
        new BingoItem("patterned flat 4", ["feet", "shoes", "flats", "pattern", "summer", "plaid", ], Resources.IMG_FLATSPATTERN04),
        new BingoItem("patterned flat 5", ["feet", "shoes", "flats", "pattern", "summer", "white", "polka-dot", ], Resources.IMG_FLATSPATTERN05),
        new BingoItem("patterned flat 6", ["feet", "shoes", "flats", "pattern", "summer", "red", "floral", ], Resources.IMG_FLATSPATTERN06),
        new BingoItem("patterned flat 7", ["feet", "shoes", "flats", "pattern", "summer", "brown", "animal", ], Resources.IMG_FLATSPATTERN07),
        new BingoItem("blue sneakers", ["feet", "shoes", "flats", "blue", "white", "stripes", ], Resources.IMG_SNEAKERSBLUE),
        new BingoItem("green sneakers", ["feet", "shoes", "flats", "green", "white", "stripes", ], Resources.IMG_SNEAKERSGREEN),
        new BingoItem("orange sneakers", ["feet", "shoes", "flats", "orange", "white", "stripes", ], Resources.IMG_SNEAKERSORANGE),
        new BingoItem("pink sneakers", ["feet", "shoes", "flats", "pink", "white", "stripes", ], Resources.IMG_SNEAKERSPINK),
        new BingoItem("purple sneakers", ["feet", "shoes", "flats", "purple", "white", "stripes", ], Resources.IMG_SNEAKERSPURPLE),
        new BingoItem("red sneakers", ["feet", "shoes", "flats", "red", "white", "stripes", ], Resources.IMG_SNEAKERSRED),
        new BingoItem("yellow sneakers", ["feet", "shoes", "flats", "white", "yellow", "stripes", ], Resources.IMG_SNEAKERSYELLOW),
        new BingoItem("bobby pins", ["head", "hair", "gem", "beaded", "silver", "blue", ], Resources.IMG_BOBBYPINS),
        new BingoItem("patterned barrette 1", ["head", "hair", "pattern", "red", ], Resources.IMG_BARRETTEPATTERN01),
        new BingoItem("patterned barrette 2", ["head", "hair", "pattern", "blue", ], Resources.IMG_BARRETTEPATTERN02),
        new BingoItem("patterned barrette 3", ["head", "hair", "pattern", "orange", "yellow", ], Resources.IMG_BARRETTEPATTERN03),
        new BingoItem("black headband", ["head", "hair", "black", ], Resources.IMG_HEADBANDBLACK),
        new BingoItem("blue headband", ["head", "hair", "blue", ], Resources.IMG_HEADBANDBLUE),
        new BingoItem("green headband", ["head", "hair", "green", ], Resources.IMG_HEADBANDGREEN),
        new BingoItem("orange headband", ["head", "hair", "orange", ], Resources.IMG_HEADBANDORANGE),
        new BingoItem("pink headband", ["head", "hair", "pink", ], Resources.IMG_HEADBANDPINK),
        new BingoItem("purple headband", ["head", "hair", "purple", ], Resources.IMG_HEADBANDPURPLE),
        new BingoItem("red headband", ["head", "hair", "red", ], Resources.IMG_HEADBANDRED),
        new BingoItem("yellow headband", ["head", "hair", "yellow", ], Resources.IMG_HEADBANDYELLOW),
        new BingoItem("red double headband", ["head", "hair", "red", ], Resources.IMG_DOUBLEHEADBANDRED),
        new BingoItem("pink double headband", ["head", "hair", "pink", ], Resources.IMG_DOUBLEHEADBANDPINK),
        new BingoItem("purple double headband", ["head", "hair", "purple", ], Resources.IMG_DOUBLEHEADBANDPURPLE),
        new BingoItem("blue double headband", ["head", "hair", "blue", ], Resources.IMG_DOUBLEHEADBANDBLUE),
        new BingoItem("orange double headband", ["head", "hair", "orange", ], Resources.IMG_DOUBLEHEADBANDORANGE),
        new BingoItem("green double headband", ["head", "hair", "green", ], Resources.IMG_DOUBLEHEADBANDGREEN),
        new BingoItem("yellow double headband", ["head", "hair", "yellow", ], Resources.IMG_DOUBLEHEADBANDYELLOW),
        new BingoItem("black double headband", ["head", "hair", "black", ], Resources.IMG_DOUBLEHEADBANDBLACK),
        new BingoItem("fabric headband 1", ["head", "hair", "pattern", "green", "floral", ], Resources.IMG_FABRICHEADBAND01),
        new BingoItem("fabric headband 2", ["head", "hair", "pattern", "stripes", "animal", "black", "white", ], Resources.IMG_FABRICHEADBAND02),
        new BingoItem("fabric headband 3", ["head", "hair", "pattern", "green", "plaid", ], Resources.IMG_FABRICHEADBAND03),
        new BingoItem("fabric headband 4", ["head", "hair", "pattern", "brown", "polka-dot", ], Resources.IMG_FABRICHEADBAND04),
        new BingoItem("fabric headband 5", ["head", "hair", "pattern", "pink", "floral", ], Resources.IMG_FABRICHEADBAND05),
        new BingoItem("fabric headband 6", ["head", "hair", "pattern", "white", "polka-dot", ], Resources.IMG_FABRICHEADBAND06),
        new BingoItem("fabric headband 7", ["head", "hair", "pattern", "red", "orange", "floral", ], Resources.IMG_FABRICHEADBAND07),
        new BingoItem("fabric headband 8", ["head", "hair", "pattern", "red", "plaid", ], Resources.IMG_FABRICHEADBAND08),
        new BingoItem("fabric headband 9", ["head", "hair", "pattern", "blue", "floral", ], Resources.IMG_FABRICHEADBAND09),
        new BingoItem("fabric headband 10", ["head", "hair", "pattern", "floral", ], Resources.IMG_FABRICHEADBAND10),
        new BingoItem("fabric headband 11", ["head", "hair", "pattern", "brown", "animal", ], Resources.IMG_FABRICHEADBAND11),
        new BingoItem("fabric headband 12", ["head", "hair", "pattern", "pink", "floral", ], Resources.IMG_FABRICHEADBAND12),
        new BingoItem("fabric headband 13", ["head", "hair", "pattern", "green", "floral", ], Resources.IMG_FABRICHEADBAND13),
        new BingoItem("fabric headband 14", ["head", "hair", "pattern", "red", "orange", "brown", "floral", ], Resources.IMG_FABRICHEADBAND14),
        new BingoItem("fabric headband 15", ["head", "hair", "pattern", "yellow", "animal", ], Resources.IMG_FABRICHEADBAND15),
        new BingoItem("fabric headband 16", ["head", "hair", "pattern", "white", "floral", ], Resources.IMG_FABRICHEADBAND16),
        new BingoItem("fabric headband 17", ["head", "hair", "pattern", "green", "polka-dot", ], Resources.IMG_FABRICHEADBAND17),
        new BingoItem("black bow clips", ["head", "hair", "black", "bow", ], Resources.IMG_BOWCLIPSBLACK),
        new BingoItem("blue bow clips", ["head", "hair", "blue", "bow", ], Resources.IMG_BOWCLIPSBLUE),
        new BingoItem("green bow clips", ["head", "hair", "green", "bow", ], Resources.IMG_BOWCLIPSGREEN),
        new BingoItem("orange bow clips", ["head", "hair", "orange", "bow", ], Resources.IMG_BOWCLIPSORANGE),
        new BingoItem("pink bow clips", ["head", "hair", "pink", "bow", ], Resources.IMG_BOWCLIPSPINK),
        new BingoItem("purple bow clips", ["head", "hair", "purple", "bow", ], Resources.IMG_BOWCLIPSPURPLE),
        new BingoItem("red bow clips", ["head", "hair", "red", "bow", ], Resources.IMG_BOWCLIPSRED),
        new BingoItem("white bow clips", ["head", "hair", "white", "bow", ], Resources.IMG_BOWCLIPSWHITE),
        new BingoItem("yellow bow clips", ["head", "hair", "yellow", "bow", ], Resources.IMG_BOWCLIPSYELLOW),
        new BingoItem("patterned bow clips 1", ["head", "hair", "pattern", "bow", "pink", ], Resources.IMG_BOWCLIPSPATTERN01),
        new BingoItem("patterned bow clips 2", ["head", "hair", "pattern", "bow", "red", ], Resources.IMG_BOWCLIPSPATTERN02),
        new BingoItem("patterned bow clips 3", ["head", "hair", "pattern", "bow", "blue", ], Resources.IMG_BOWCLIPSPATTERN03),
        new BingoItem("patterned bow clips 4", ["head", "hair", "pattern", "bow", "green", ], Resources.IMG_BOWCLIPSPATTERN04),
        new BingoItem("patterned bow clips 5", ["head", "hair", "pattern", "bow", "animal", ], Resources.IMG_BOWCLIPSPATTERN05),
        new BingoItem("brown claw", ["head", "hair", "brown", ], Resources.IMG_CLAWBROWN),
        new BingoItem("black claw", ["head", "hair", "black", ], Resources.IMG_CLAWBLACK),
        new BingoItem("red claw", ["head", "hair", "red", ], Resources.IMG_CLAWRED),
        new BingoItem("pink claw", ["head", "hair", "pink", ], Resources.IMG_CLAWPINK),
        new BingoItem("purple claw", ["head", "hair", "purple", ], Resources.IMG_CLAWPURPLE),
        new BingoItem("blue claw", ["head", "hair", "blue", ], Resources.IMG_CLAWBLUE),
        new BingoItem("orange claw", ["head", "hair", "orange", ], Resources.IMG_CLAWORANGE),
        new BingoItem("green claw", ["head", "hair", "green", ], Resources.IMG_CLAWGREEN),
        new BingoItem("yellow claw", ["head", "hair", "yellow", ], Resources.IMG_CLAWYELLOW),
        new BingoItem("red baret", ["head", "hat", "red", ], Resources.IMG_BARET),
        new BingoItem("purple baret", ["head", "hat", "purple", ], Resources.IMG_BARETPURPLE),
        new BingoItem("orange baseball cap", ["head", "hat", "orange", "brown", ], Resources.IMG_BASEBALLCAP),
        new BingoItem("blue baseball cap", ["head", "hat", "blue", ], Resources.IMG_BASEBALLCAPBLUE),
        new BingoItem("green baseball cap", ["head", "hat", "green", ], Resources.IMG_BASEBALLCAPGREEN),
        new BingoItem("black cowboy hat", ["head", "hat", "red", "black", ], Resources.IMG_COWBOYHATBLACK),
        new BingoItem("cowboy hat", ["head", "hat", "green", "brown", ], Resources.IMG_COWBOYHAT),
        new BingoItem("'earflap' hat", ["head", "hat", "winter", "blue", ], Resources.IMG_EARFLAPHAT),
        new BingoItem("brown 'earflap' hat", ["head", "hat", "winter", "brown", ], Resources.IMG_EARFLAPHATBROWN),
        new BingoItem("fedora", ["head", "hat", "white", "orange", "brown", ], Resources.IMG_FEDORA),
        new BingoItem("patterned fedora", ["head", "hat", "white", "black", "floral", ], Resources.IMG_FEDORAPATTERN),
        new BingoItem("newsboy hat", ["head", "hat", "blue", "floral", ], Resources.IMG_NEWSBOYHAT),
        new BingoItem("patterned newsboy hat", ["head", "hat", "orange", "pink", "purple", "pattern", "floral", ], Resources.IMG_NEWSBOYHATPATTERN),
        new BingoItem("blue snow cap", ["head", "hat", "winter", "blue", ], Resources.IMG_SNOWCAPBLUE),
        new BingoItem("snow cap", ["head", "hat", "winter", "pink", ], Resources.IMG_SNOWCAP),
        new BingoItem("straw/sun hat", ["head", "hat", "summer", "red", ], Resources.IMG_STRAWHAT),
        new BingoItem("patterned straw/sun hat", ["head", "hat", "summer", "green", "pattern", "floral", ], Resources.IMG_STRAWHATPATTERN),
        new BingoItem("patterned tote 1", ["bag", "tote", "pattern", "stripes", "animal", "purple", "black", "white", ], Resources.IMG_TOTEPATTERN01),
        new BingoItem("patterned tote 2", ["bag", "tote", "pattern", "brown", "floral", ], Resources.IMG_TOTEPATTERN02),
        new BingoItem("patterned tote 3", ["bag", "tote", "pattern", "pink", "white", "polka-dot", ], Resources.IMG_TOTEPATTERN03),
        new BingoItem("patterned tote 4", ["bag", "tote", "pattern", "red", "orange", "floral", ], Resources.IMG_TOTEPATTERN04),
        new BingoItem("patterned tote 5", ["bag", "tote", "pattern", "blue", "floral", ], Resources.IMG_TOTEPATTERN05),
        new BingoItem("patterned tote 6", ["bag", "tote", "pattern", "green", "floral", ], Resources.IMG_TOTEPATTERN06),
        new BingoItem("patterned tote 7", ["bag", "tote", "pattern", "brown", "animal", ], Resources.IMG_TOTEPATTERN07),
        new BingoItem("patterned tote 8", ["bag", "tote", "pattern", "pink", "stripes", ], Resources.IMG_TOTEPATTERN08),
        new BingoItem("patterned tote 9", ["bag", "tote", "pattern", "pink", "white", "floral", ], Resources.IMG_TOTEPATTERN09),
        new BingoItem("patterned tote 10", ["bag", "tote", "pattern", "pink", "purple", "orange", "floral", ], Resources.IMG_TOTEPATTERN10),
        new BingoItem("patterned tote 11", ["bag", "tote", "pattern", "yellow", "black", "animal", ], Resources.IMG_TOTEPATTERN11),
        new BingoItem("patterned tote 12", ["bag", "tote", "pattern", "white", "pink", "floral", ], Resources.IMG_TOTEPATTERN12),
        new BingoItem("patterned tote 13", ["bag", "tote", "pattern", "black", "white", "floral", ], Resources.IMG_TOTEPATTERN13),
        new BingoItem("patterned tote 14", ["bag", "tote", "pattern", "yellow", "floral", ], Resources.IMG_TOTEPATTERN14),
        new BingoItem("patterned tote 15", ["bag", "tote", "pattern", "green", ], Resources.IMG_TOTEPATTERN15),
        new BingoItem("brown woven tote", ["bag", "tote", "brown", ], Resources.IMG_WOVENTOTEBROWN),
        new BingoItem("orange woven tote", ["bag", "tote", "orange", ], Resources.IMG_WOVENTOTEORANGE),
        new BingoItem("yellow woven tote", ["bag", "tote", "yellow", ], Resources.IMG_WOVENTOTEYELLOW),
        new BingoItem("blue change purse", ["bag", "change purse", "blue", ], Resources.IMG_CHANGEPURSEBLUE),
        new BingoItem("red change purse", ["bag", "change purse", "red", ], Resources.IMG_CHANGEPURSERED),
        new BingoItem("pink change purse", ["bag", "change purse", "pink", ], Resources.IMG_CHANGEPURSEPINK),
        new BingoItem("purple change purse", ["bag", "change purse", "purple", ], Resources.IMG_CHANGEPURSEPURPLE),
        new BingoItem("orange change purse", ["bag", "change purse", "orange", ], Resources.IMG_CHANGEPURSEORANGE),
        new BingoItem("green change purse", ["bag", "change purse", "green", ], Resources.IMG_CHANGEPURSEGREEN),
        new BingoItem("yellow change purse", ["bag", "change purse", "yellow", ], Resources.IMG_CHANGEPURSEYELLOW),
        new BingoItem("clutch", ["bag", "brown", "gold", ], Resources.IMG_CLUTCH),
        new BingoItem("green baguette", ["bag", "green", ], Resources.IMG_BAGUETTEGREEN),
        new BingoItem("purple baguette", ["bag", "purple", ], Resources.IMG_BAGUETTEPURPLE),
        new BingoItem("patterned purse 1", ["bag", "pattern", "green", "polka-dot", ], Resources.IMG_PURSEPATTERN01),
        new BingoItem("patterned purse 2", ["bag", "pattern", "blue", "floral", ], Resources.IMG_PURSEPATTERN02),
        new BingoItem("patterned purse 3", ["bag", "pattern", "brown", "polka-dot", ], Resources.IMG_PURSEPATTERN03),
        new BingoItem("patterned purse 4", ["bag", "pattern", "red", "floral", ], Resources.IMG_PURSEPATTERN04),

        // recolored items
        new BingoItem("garnet gemstone earrings", ["head", "jewelry", "earrings", "gem", "red", ], Resources.IMG_GEMEARRINGS,       true, 0xCC0000, 0.51 ),
        new BingoItem("purple gemstone earrings", ["head", "jewelry", "earrings", "gem", "purple", ], Resources.IMG_GEMEARRINGS,    true, 0x660066, 0.51),
        new BingoItem("teal gemstone earrings", ["head", "jewelry", "earrings", "gem", "blue", ], Resources.IMG_GEMEARRINGS,        true, 0x99FFFF, 0.51),
        new BingoItem("silver gemstone earrings", ["head", "jewelry", "earrings", "gem", "silver", ], Resources.IMG_GEMEARRINGS,    true, 0xFFFFFF, 0.51),
        new BingoItem("green gemstone earrings", ["head", "jewelry", "earrings", "gem", "green", ], Resources.IMG_GEMEARRINGS,      true, 0x006600, 0.51),
        new BingoItem("ruby gemstone earrings", ["head", "jewelry", "earrings", "gem", "red", ], Resources.IMG_GEMEARRINGS,         true, 0xFF0000, 0.51),
        new BingoItem("light green gemstone earrings", ["head", "jewelry", "earrings", "gem", "green", ], Resources.IMG_GEMEARRINGS, true, 0x99FF66, 0.51),
        new BingoItem("blue gemstone earrings", ["head", "jewelry", "earrings", "gem", "blue", ], Resources.IMG_GEMEARRINGS,        true, 0x0000FF, 0.51),
        new BingoItem("pink gemstone earrings", ["head", "jewelry", "earrings", "gem", "pink", ], Resources.IMG_GEMEARRINGS,        true, 0xFF0066, 0.51),
        new BingoItem("yellow gemstone earrings", ["head", "jewelry", "earrings", "gem", "yellow", ], Resources.IMG_GEMEARRINGS,    true, 0xFFFF66, 0.51),
        new BingoItem("light blue gemstone earrings", ["head", "jewelry", "earrings", "gem", "blue", ], Resources.IMG_GEMEARRINGS,  true, 0x0099FF, 0.51),

        new BingoItem("silver hoop earrings", ["head", "jewelry", "earrings", "hoop", "silver", "dangly", ], Resources.IMG_HOOPEARRINGS, true, 0xCCCCCC, 0.51),
        new BingoItem("gold hoop earrings", ["head", "jewelry", "earrings", "hoop", "gold", "dangly", ], Resources.IMG_HOOPEARRINGS, true, 0xCC9900, 0.51),

        new BingoItem("silver thick hoop earrings", ["head", "jewelry", "earrings", "hoop", "silver", "dangly", ], Resources.IMG_THICKHOOPEARRINGS, true, 0xCCCCCC, 0.51),
        new BingoItem("gold thick hoop earrings", ["head", "jewelry", "earrings", "hoop", "gold", "dangly", ], Resources.IMG_THICKHOOPEARRINGS, true, 0xCC9900, 0.51),

        new BingoItem("silver bubble earrings", ["head", "jewelry", "earrings", "hoop", "silver", "dangly", ], Resources.IMG_BUBBLEEARRINGS, true, 0xCCCCCC, 0.51),
        new BingoItem("gold bubble earrings", ["head", "jewelry", "earrings", "hoop", "gold", "dangly", ], Resources.IMG_BUBBLEEARRINGS, true, 0xCC9900, 0.51),

        new BingoItem("silver basic ring", ["hands", "jewelry", "ring", "silver", ], Resources.IMG_BASICRING, true, 0xCCCCCC, 0.51),
        new BingoItem("gold basic ring", ["hands", "jewelry", "ring", "gold", ], Resources.IMG_BASICRING, true, 0xCC9900, 0.51),

        new BingoItem("red solid heel", ["feet", "shoes", "heel", "red", ], Resources.IMG_HEELSOLID, true, 0xFF0000, 0.51),
        new BingoItem("pink solid heel", ["feet", "shoes", "heel", "pink", ], Resources.IMG_HEELSOLID, true, 0xFF3366, 0.51),
        new BingoItem("purple solid heel", ["feet", "shoes", "heel", "purple", ], Resources.IMG_HEELSOLID, true, 0x660066, 0.51),
        new BingoItem("blue solid heel", ["feet", "shoes", "heel", "blue", ], Resources.IMG_HEELSOLID, true, 0x003399, 0.51),
        new BingoItem("orange solid heel", ["feet", "shoes", "heel", "orange", ], Resources.IMG_HEELSOLID, true, 0xFF6600, 0.51),
        new BingoItem("green solid heel", ["feet", "shoes", "heel", "green", ], Resources.IMG_HEELSOLID, true, 0x006633, 0.51),
        new BingoItem("yellow solid heel", ["feet", "shoes", "heel", "yellow", ], Resources.IMG_HEELSOLID, true, 0xFFCC00, 0.51),
        new BingoItem("black solid heel", ["feet", "shoes", "heel", "black", ], Resources.IMG_HEELSOLID, true, 0x000000, 0.56),

    ];




    // network bits
    public static const PROP_STATE :String = "state";
    public static const PROP_SCORES :String = "scores";
    public static const MSG_REQUEST_BINGO :String = "r_bingo";

}

}
