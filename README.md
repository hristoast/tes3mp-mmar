# Multiple Mark And Recall for TES3MP

Inspired by [Multiple Teleport Marking (OpenMW and Tamriel Rebuilt)](https://www.nexusmods.com/morrowind/mods/44825) by Marcel Hesselbarth and rot.

**Requires [DataManager](https://github.com/tes3mp-scripts/DataManager)!**

Also known as MMAR.  Moves mark and recall spell functionality to chat commands, and allows for more than one mark up to a configurable max.

The spells are required, a configurable amount of magicka is used, the proper spell chance is calculated, and a configurable amount of progress is given to Mysticism on a successful "cast".

The default mark and recall spells still work normally.

## Installation

1. Place this repo into your `CoreScripts/scripts/custom/` directory.

1. Add the following to `CoreScripts/scripts/customScripts.lua`:

        ...
        -- DataManager needs to before MMAR, like this
        DataManager = require("custom/DataManager/main")

        require("custom/tes3mp-mmar/main")

1. Ensure that `DataManager` loads before this mod as seen above.

1. Optionally configure MMAR by editing the `CoreScripts/data/custom/__config_MultipleMarkAndRecall.json` file (see below).

## Configuration

* `maxMarks`

Integer.  The maximum allowed number of mark points.  Default: `18`

* `msgMark`

String.  The chat message shown on a successful mark.  Any occurance of `%s` will be replaced with the given mark name.  Default: `#008000The mark \"%s\" has been set!#FFFFFF`

* `msgMarkRm`

String.  The chat message shown on a successful mark deletion.  Any occurance of `%s` will be replaced with the given mark name.  Default: `#008000The mark \"%s\" has been deleted!#FFFFFF`

* `msgNotAllowed`

String.  The chat message shown when teleportation from the current cell is not allowed.  Default: `#FF0000Teleportation is not allowed here!#FFFFFF`

* `msgRecall`

String.  The chat message shown on a successful recall.  Any occurance of `%s` will be replaced with the given mark name.  Default: `#008000Recalled to: \"%s\"!#FFFFFF`

* `msgRecallFailed`

String.  The chat message shown when a nonexistent recall name is given.  Default: `#FF0000Recall failed; that mark doesn't exist!#FFFFFF`

* `over10mod`

Integer.  Magic number that affects the number of marks you get every 10 levels after your Mysticism hits 10.  Default: `2`

* `over50mod`

Integer.  Magic number that affects the number of marks you get every 5 levels after your Mysticism hits 50.  Default: `7`

* `skillProgressPoints`

Integer.  The number of progress points given to Mysticism on a successful spell cast; defaults to the value given by [MBSP](https://github.com/IllyaMoskvin/tes3mp-mbsp), for the vanilla value set this to `1`.  Default: `2`

* `spellCost`

Integer.  How much magicka should mark and recall spells cost?  Default: `18`

* `teleportForbidden`

Array of strings.  A list of cell names from which teleportation is forbidden.  The default value is taken from   Default: `18`
