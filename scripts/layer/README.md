layer
=====

Anime Studio layer scripts. See Smith Micro's [Anime Studio Scripting Reference](http://www.animestudioscripting.com) for API details.

GWB_SwitchTogether.lua
----------------------

Add this layer script to a source switch layer and to duplicate switch layers. During playback, keys on source layer will be duplicated on duplicate layers so that source and duplicate layers have identical switch behavior. This script requires two supporting utility scripts: [GWB_Share](../utility/GWB_Share.lua) and [GWB_Logger](../utility/GWB_Logger.lua). See the [comments in the script header](GWB_SwitchTogether.lua#L2-48) for details.

Tested with Anime Studio v9.5.

GWB_MoveTogether.lua
--------------------

Add this layer script to a source vector layer and to duplicate	vector layers. During playback, point movement and curvature on	the source layer will be replicated on duplicate layers. Other properties on duplicate layers are unaffected. This script requires two supporting utility scripts: [GWB_Share](../utility/GWB_Share.lua) and [GWB_Logger](../utility/GWB_Logger.lua). See the [comments in the script header](GWB_MoveTogether.lua#L2-57) for details.

Tested with Anime Studio v9.5.
