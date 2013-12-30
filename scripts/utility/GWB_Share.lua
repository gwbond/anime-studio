
--[[

	GWB_Share

	Author: gwbond
	Version: 1.0
	Compatbility: ASP 9.5

	DESCRIPTION:

	A general-purpose utility for layer scripts that enables a
	designated 'source' layer to efficiently share arbitrary data with
	'duplicate' layers on a per-frame basis.

	USAGE:

	This utility script should be located in your Anime Studio
	scripts/utility folder.

	This utility script requires the following utility script to be
	present in your Anime Studio scripts/utility folder: GWB_Logger

	Structure your layer script similar to the following:

	--

	function LayerScript(moho)

	    -- create a sharing object with desired log level
		local share = GWB_Share:new( moho, GWB_Logger.logLevel.ERROR )

		-- get the layer associated with this script
		local scriptLayer = moho.layer

		if share:isDupLayer( scriptLayer ) -- current layer is a dup layer
		then

			if share:dupLayerConstraintsSatisfied( currentLayer )
			then
				-- your dup layer code includes getting the current shared value
				somethingSharedBySourceLayer = share:getSharedValue( currentLayer )
			end

		elseif share:sourceLayerConstraintsSatisfied( currentLayer ) -- current layer is a source layer
		then
				-- your source layer code includes setting the current shared value
				share:setSharedValue( currentLayer, somethingToShareWithDupLayers )
		end

	end

	--

	EXAMPLE:

	See the GWB_SwitchTogether layer script for a concrete example of
	using this class.

	--

	HOW IT WORKS:

	The approach used here, borrowed from Fazek's fa-rl_meshinstance
	script script, is to share an object between the source and dup
	layers. A value to be shared by the source layer for the current
	animation frame is maintained in an object that is stored in the
	source layer. The same object is also stored in dup layers. This
	way, any changes the source layer makes to the object are
	automatically available to dup layers, obviating the need for the
	source layer to explicitly search for dup layers and update them.
	For this to work, the shared object needs to be updated by the
	source layer before the shared object is referenced by dup
	layers. This is guaranteed by placing the source layer beneath the
	dup layers because Anime Studio executes layer scripts bottom-up.

	The main advantage of the shared object approach used here is that
	it provides low-overhead execution in comparison to an approach
	that searches for, and updates, dup layers associated with a
	source layer each time the script executes. The disadvantage of
	this approach is that dup layers are only updated for a frame when
	the playhead is on that frame. This means, for example, if source
	layer keys are dragged to a new position on the timeline, the dup
	layer keys are not updated to the new positions until the playhead
	is located over the new key positions, such as when the
	animation is played back. Playing back an animation once or twice
	after modifying source keys ensures dup layer keys are
	updated. Sometimes playing back more than once is necessary
	because the script isn't guaranteed to be executed on every frame
	during playback.

	Much of the script's logic is concerned with maintaining the
	integrity of the shared source object in the face of users
	changing layer names, moving layers around, and enabling/disabling
	layer scripts.

	The script also guards against unpredictable Anime Studio layer
	script execution behavior: running a script multiple times on a
	frame for a layer, not running a script at all on a frame for a
	layer during playback, intermittlently re-creating layer objects
	(resulting in loss of shared objects), intermittently running a
	script on frame zero when the playhead is not on frame zero.

]]--

	--[[ -------------------------------------------------------------------------------- ]]--

	GWB_Share = {}

	--[[ -------------------------------------------------------------------------------- ]]--

	function GWB_Share:new( moho, loggerLevel ) 
	 	local share = { moho = moho, logger = GWB_Logger:new( "GWB_Share", loggerLevel ) } 
		setmetatable( share, self )
		self.__index = self
		return share
	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Returns true if specfied layer's name ends with ".dup"
    -- extension, o.w. returns false.

	function GWB_Share:isDupLayer( layer )
	    return string.sub( layer:Name(), -4 ) == ".dup"
	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Returns true if specfied layer's name is equal to specified
    -- source layer's name with ".dup" extension, o.w. returns false.

	function GWB_Share:isDupLayerForSourceLayer( layerName, sourceLayerName )
	    return sourceLayerName..".dup" == layerName
	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Strips last four characters from the specified layer name and
    -- returns the result.

	function GWB_Share:getSourceLayerNameFromDupLayerName( dupLayerName ) 
	    return string.sub( dupLayerName, 1, -5 ) -- strip ".dup" extension from dup layer name
	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Function called by getSourceLayer(). Returns a layer in the
    -- project with the specified sourceLayerName if exactly one such
    -- source layer exists, and if no dup layers exist beneath the
    -- source layer, o.w. returns nil.

    function GWB_Share:getSourceLayer4( layers, index, sourceLayerName, sourceLayer )

		local currentLayer = layers:Layer( index )
		local currentLayerName = currentLayer:Name()

		if ( currentLayerName == sourceLayerName ) -- current layer is a source layer
	    then
	        if ( sourceLayer ~= nil ) 
	   	    then
			    return nil -- more than one source layer in document
		    else
			    sourceLayer = currentLayer -- this is first source layer in document
			end
        elseif ( self:isDupLayerForSourceLayer( currentLayerName, sourceLayerName ) ) -- current layer is a dup layer
	    then
			if ( sourceLayer ~= nil ) 
			then
			    return nil -- dup layer is below source layer
			end
		end

		if ( currentLayer:IsGroupType() )  -- current layer is a group layer
		then
		    -- get sub-layers in group
            local subLayers = self.moho:LayerAsGroup( currentLayer )
			local numSubLayers = subLayers:CountLayers()
			if ( numSubLayers > 0 )
			then
			    -- recurse into sub-layers
		        sourceLayer = self:getSourceLayer4( subLayers, numSubLayers - 1, sourceLayerName, sourceLayer )
			end
		end

	    if ( index == 0 )
		then 
		    return sourceLayer -- no layers beneath current layer
		else
		    return self:getSourceLayer4( layers, index - 1, sourceLayerName, sourceLayer ) -- recurse to next layer down
		end

	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- The function returns a layer in the project with the specified
    -- sourceLayerName if exactly one such source layer exists, and if
    -- no dup layers exist beneath the source layer, o.w. returns nil.

	function GWB_Share:getSourceLayer( sourceLayerName )

	    local rootLayers = self.moho.document

	    return self:getSourceLayer4( rootLayers, rootLayers:CountLayers() - 1, sourceLayerName, nil ) 

	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Returns true if a new shared source object is created for the
    -- source layer, o.w. returns false. Also ensures that source
    -- layer name stored in shared object is up to date. Note that the
    -- Anime Studio runtime intermittently re-creates layer
    -- objects. When the source layer is re-created the shared source
    -- object needs to be re-created.

	function GWB_Share:sourceLayerInitialized( sourceLayer )

	    if ( sourceLayer.GWB_SharedSourceObject == nil )
		then
		    -- create and initialize a new shared object
			self.logger:log( GWB_Logger.logLevel.WARN, "source layer creating a new shared source object" )
			sourceLayer.GWB_SharedSourceObject = {}
			sourceLayer.GWB_SharedSourceObject.sourceLayerName = sourceLayer:Name()
			sourceLayer.GWB_SharedSourceObject.currentFrame = self.moho.frame
			sourceLayer.GWB_SharedSourceObject.sharedValue = nil
			return true

		elseif ( sourceLayer.GWB_SharedSourceObject.sourceLayerName ~= sourceLayer:Name() )
		then
			self.logger:log( GWB_Logger.logLevel.WARN, "source layer name has changed" )
		    -- update shared object source layer name
			sourceLayer.GWB_SharedSourceObject.sourceLayerName = sourceLayer:Name()
			-- update current frame
			sourceLayer.GWB_SharedSourceObject.currentFrame = self.moho.frame
			return false

		else
			-- update current frame
			sourceLayer.GWB_SharedSourceObject.currentFrame = self.moho.frame
		    return false
		end

	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Attempt to add shared source object to specified dup
    -- layer. Return true if successful, o.w. return false. 

	function GWB_Share:associateDupLayerWithSource( dupLayer )

	    dupLayer.GWB_SharedSourceObject = nil -- clear reference to existing shared source object

		local sourceLayer = self:getSourceLayer( self:getSourceLayerNameFromDupLayerName( dupLayer:Name() ) )

		if ( sourceLayer == nil ) 
		then
			-- no source layer, more than one source layer, or source layer above a dup layer
			self.logger:log ( GWB_Logger.logLevel.DEBUG, "invalid/missing source layer for: "..dupLayer:Name() )
		    return false

		elseif ( sourceLayer.GWB_SharedSourceObject == nil )
		then
			-- source layer hasn't run this script so initialize it
			self.logger:log ( GWB_Logger.logLevel.DEBUG, "initializing source layer for: "..dupLayer:Name() )
			self:sourceLayerInitialized( sourceLayer )
			-- add reference to newly created source shared object
		    dupLayer.GWB_SharedSourceObject = sourceLayer.GWB_SharedSourceObject
		    return true

		elseif ( sourceLayer.GWB_SharedSourceObject.sourceLayerName ~= sourceLayer:Name() )
		then
			 -- source layer hasn't run this script since its name has changed
			self.logger:log ( GWB_Logger.logLevel.DEBUG, "shared source layer name: "..sourceLayer.GWB_SharedSourceObject.sourceLayerName.." differs from actual source layer name: "..sourceLayer:Name() )
		    return false

		else 
		     -- add reference to source shared object
		    dupLayer.GWB_SharedSourceObject = sourceLayer.GWB_SharedSourceObject
			return true
		end
	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Returns true if specified dup layer has a reference to shared
    -- source object, o.w. returns false. Attempts to add reference to
    -- shared source object if it doesn't already exist.

	function GWB_Share:dupLayerAssociatedWithSource( currentDupLayer )

		if ( currentDupLayer.GWB_SharedSourceObject == nil )
		then
		    -- current dup layer uninitialized
		    self.logger:log( GWB_Logger.logLevel.DEBUG, "re-associating dup layer: "..currentDupLayer:Name().." because shared source object is nil" )
			return self:associateDupLayerWithSource( currentDupLayer ) 

		elseif ( not self:isDupLayerForSourceLayer( currentDupLayer:Name(), currentDupLayer.GWB_SharedSourceObject.sourceLayerName ) )
		then
		    -- current dup layer name has changed or source layer name has changed
		    self.logger:log( GWB_Logger.logLevel.DEBUG, "re-associating dup layer: "..currentDupLayer:Name().." because shared source layer name doesn't match" )
			return self:associateDupLayerWithSource( currentDupLayer )

        else
		    return true
		end
		
	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- (Re-)initializes shared source object in all dup layers
    -- associated with specified source layer.

	function GWB_Share:initializeDupLayers3( layers, index, sourceLayer )

		local currentLayer = layers:Layer( index )

		if ( self:isDupLayerForSourceLayer( currentLayer:Name(), sourceLayer:Name() ) ) -- current layer is a dup layer
		then
		    self.logger:log( GWB_Logger.logLevel.DEBUG, "re-initializing: "..currentLayer:Name().." with source layer name: "..sourceLayer.GWB_SharedSourceObject.sourceLayerName )
		    currentLayer.GWB_SharedSourceObject = sourceLayer.GWB_SharedSourceObject -- (re-)initialize dup layer's shared source object
		end

		if ( currentLayer:IsGroupType() )  -- current layer is a group layer
		then
		    -- get sub-layers in group
            local subLayers = self.moho:LayerAsGroup( currentLayer )
			local numSubLayers = subLayers:CountLayers()

			if ( numSubLayers > 0 )
			then
			    -- recurse into sub-layers
		        self:initializeDupLayers3( subLayers, numSubLayers - 1, sourceLayer )
			end
		end

	    if ( index == 0 )
		then 
		    return -- no layers beneath current layer
		else
		    self:initializeDupLayers3( layers, index - 1, sourceLayer ) -- recurse to next layer down
		end

	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- (Re-)initializes shared source object in all dup layers
    -- associated with specified source layer.

	function GWB_Share:initializeDupLayers( sourceLayer )

	    local rootLayers = self.moho.document
	    self:initializeDupLayers3( rootLayers, rootLayers:CountLayers() - 1, sourceLayer ) 
	end

	--[[ -------------------------------------------------------------------------------- ]]--
	
	-- Sets value of shared object to specified value for specified
    -- layer. Specified layer should be a source layer.

	function GWB_Share:setSharedValue( layer, value )
	    layer.GWB_SharedSourceObject.sharedValue = value
	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Returns current value of shared object from specified layer.

	function GWB_Share:getSharedValue( layer )
	    return layer.GWB_SharedSourceObject.sharedValue
	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Verifies shared object exists for specified dup layer and
    -- verifies integrity of the shared object and its associated
    -- source layer. Attempts to add reference to shared object if
    -- none exists. Returns true if integrity verified, o.w. returns
    -- false.

	function GWB_Share:dupLayerConstraintsSatisfied( dupLayer ) 

	    if ( self:dupLayerAssociatedWithSource( dupLayer ) ) 
		then
		    if ( self.moho.frame == dupLayer.GWB_SharedSourceObject.currentFrame )
			then
				return true
			else -- current frame not equal to stored frame value so ignore

				if ( dupLayer.GWB_SharedSourceObject.currentFrame == nil )
				then
					self.logger:log( GWB_Logger.logLevel.WARN, "current dup frame: "..self.moho.frame.." not equal to current source frame: nil" )
				else
			        self.logger:log( GWB_Logger.logLevel.WARN, "current dup frame: "..self.moho.frame.." not equal to current source frame: "..dupLayer.GWB_SharedSourceObject.currentFrame )
				end
				return false
			end
		else
			self.logger:log( GWB_Logger.logLevel.ERROR, "source layer not associated with "..dupLayer:Name().." - ensure source layer is running this script and is located below dup layers" )
			return false
		end
	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Ensure shared object exists for specified source layer. If
    -- shared object doesn't exist then initializes one for the
    -- specified layer and updates any existing dup layers to
    -- reference the new shared object. Unconditionally returns true.

	function GWB_Share:sourceLayerConstraintsSatisfied( sourceLayer ) 

        if self:sourceLayerInitialized( sourceLayer )
	    then
		    -- initialize dup layer shared source objects in case dup
			-- layers are referencing an old shared source object
			self:initializeDupLayers( sourceLayer )
		end
		return true
	end

	--[[ -------------------------------------------------------------------------------- ]]--