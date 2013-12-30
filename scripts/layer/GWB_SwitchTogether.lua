
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

	A source switch layer can have any name. Duplicate switch layers
	must have the source layer name with a '.dup' extension. E.g., if
	the source layer is named "Mouth", then duplicate layers must be
	named "Mouth.dup".

	The source switch layer must be located *below* all duplicate
	layers.

	The source layer and all dup layers must install this layer script.

	The sub-layers in the source and dup switch layers must have the
	same names.

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

	if share:isDupLayer( switchLayer )
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
                -- so add a key for same value in dup layer
				switchLayerAnimationChannel:SetValue( moho.frame, sourceSwitchLayerValue ) -- creates a key as a side-effect 
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
