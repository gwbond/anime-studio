
--[[

	GWB_SwitchTogether

	Author: gwbond
	Version: 1.0
	Compatbility: ASP 9.5

	DESCRIPTION:

	Add this layer script to a source switch layer and to duplicate
	switch layers. During playback, keys on source layer will be
	duplicated on duplicate layers so that source and duplicate layers
	have identical switch behavior.

	USAGE:

	This layer script requires the following two utility scripts to be
	present in your Anime Studio scripts/utility folder:
	GWB_Logger.lua and GWB_Share.lua

	A layer naming convention is used to associate source and
	duplicate layers. A source layer can have any name. Duplicate
	layers denote they are linked to a source layer using a layer name
	of the form: "Arbitrary Layer Name > Source Layer Name". E.g., if
	the source layer is named "Mouth Layer", then a duplicate layer
	can be named "Anything At All > Mouth Layer", where "> Mouth
	Layer" indicates that the layer is linked to the source layer
	named "Mouth Layer".

	The source switch layer must be located *below* all duplicate
	layers.

	The source layer and all dup layers must install this layer script.

	The sub-layers in the source and dup switch layers must have
	matching names. Sub-layer names are considered matching if they
	are the same, or if they have the same suffix e.g.,
	one is named "mouth.open" and the other is named "jaw.open"

	Only create/delete keys for the source layer. Dup layer keys will
	be automatically created/deleted to match the source layer.

	Sometimes it is necessary to play back an animation a few times to
	force the dup layers keys to match the source layer keys.

]]--

--[[ -------------------------------------------------------------------------------- ]]--

function LayerScript(moho)

	-- NOTE: My preference would be to create the 'logger' and 'share'
    -- objects (defined below) outside the scope of the LayerScript
    -- function, in order to prevent their re-creation each time
    -- LayerScript is invoked. Unfortunately, when I tried this, Anime
    -- Studio crashed intermittently.

	-- create a local logger object with desired log level
	local logger = GWB_Logger:new( "GWB_SwitchTogether", GWB_Logger.logLevel.ERROR )

	-- create a sharing object with desired log level
	local share = GWB_Share:new( moho, GWB_Logger.logLevel.ERROR )

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Returns suffix (excluding the leading period and trailing
    -- whitespace) for specified layerName, o.w. returns nil.

	local function getLayerNameSuffix( layerName )
	    return string.match( layerName, ".*%.(.-)%s*$" )
	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Returns sublayer name of specified dupSwitchLayer that matches
    -- specified sourceSwitchLayerValue. Matching is satisfied if the
    -- two strings are the same, or if string prefixes are the same
    -- e.g., the strings match if one string is "mouth.open" and the
    -- other is "jaw.open". If no matching sublayer name is found then
    -- returns the specified sourceSwitchLayerValue.

	local function getMatchingDupSwitchLayerValue( dupSwitchLayer, sourceSwitchLayerValue )

        local subLayers = moho:LayerAsGroup( dupSwitchLayer )
		local numSubLayers = subLayers:CountLayers()
		local matchingLayerValue = sourceSwitchLayerValue
		local sourceSwitchLayerValueSuffix = getLayerNameSuffix( sourceSwitchLayerValue )
		local subLayerName

		for layerIndex = 0, numSubLayers - 1 do
			subLayerName = subLayers:Layer( layerIndex ):Name()
			if ( ( subLayerName == sourceSwitchLayerValue ) or 
			    getLayerNameSuffix( subLayerName ) == sourceSwitchLayerValueSuffix )
			then
				matchingLayerValue = subLayerName
			    break
			end
		end

		logger:log( GWB_Logger.logLevel.DEBUG, "dup switch sub-layer: "..matchingLayerValue.." matches source switch sub-layer: "..sourceSwitchLayerValue )
	    return matchingLayerValue
	end

	--[[ -------------------------------------------------------------------------------- ]]--

	local scriptLayer = moho.layer
	local sourceSwitchLayerValue
	local switchLayerAnimationChannel

	-- ensure current layer is a switch layer o.w. return
	if ( scriptLayer:LayerType() ~= MOHO.LT_SWITCH ) 
	then
		logger:log( GWB_Logger.logLevel.ERROR, "layer script for "..scriptLayer:Name().." can only be used with a switch layer" )
	    return
	end

	local switchLayer = moho:LayerAsSwitch( scriptLayer ) -- cast current layer to switch layer

	-- two different behaviors depending on whether current layer is
    -- dup layer or source layer:

	if share:isLinked( switchLayer )
	then

	    if share:dupLayerConstraintsSatisfied( switchLayer )
		then
		    -- update dup switch layer based on shared object value
		    sourceSwitchLayerValue = share:getSharedValue( switchLayer )
			switchLayerAnimationChannel = switchLayer:SwitchValues()

			if ( sourceSwitchLayerValue == nil )
			then
				-- no source switch value defined at current
                -- frame so delete dup layer key if one exists
                -- o.w. do nothing
				switchLayerAnimationChannel:DeleteKey( moho.frame ) -- no-op if called when no key exists

			else
			    -- source has a key defined at current frame
                -- so add a key for matching value in dup layer
				local dupSwitchLayerValue = getMatchingDupSwitchLayerValue( switchLayer, sourceSwitchLayerValue )
				switchLayerAnimationChannel:SetValue( moho.frame, dupSwitchLayerValue ) -- creates a key as a side-effect 
			end

		end -- if share:dupLayerConstraintsSatisfied( switchLayer )

	elseif share:sourceLayerConstraintsSatisfied( switchLayer ) -- current layer is a source layer
	then
		switchLayerAnimationChannel = switchLayer:SwitchValues()

		-- value is nil if source switch layer has no sub-layers
		-- o.w. value is current switch sub-layer name
		sourceSwitchLayerValue = switchLayerAnimationChannel:GetValue( moho.frame )

		if ( sourceSwitchLayerValue and switchLayerAnimationChannel:HasKey( moho.frame ) )
		then
		    -- store switch value in shared object if a key is set
            -- at current frame in the source layer
			share:setSharedValue( switchLayer, sourceSwitchLayerValue )

		else
			-- store nil switch value in shared object if no key
            -- set at the current frame in the source layer or no
            -- switch sub-layers exist
		    share:setSharedValue( switchLayer, nil )
		end

	end -- if share:isDupLayer( switchLayer )

end
