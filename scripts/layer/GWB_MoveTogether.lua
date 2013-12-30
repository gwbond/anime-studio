
--[[

	GWB_MoveTogether

	Author: gwbond
	Version: 1.0
	Compatbility: ASP 9.5

	DESCRIPTION:

	Add this layer script to a source vector layer and to duplicate
	vector layers. During playback, point movement and curvature on
	the source layer will be replicated on duplicate layers. Other
	properties on duplicate layers are unaffected.

	The code for duplicating point motion and curvature is taken from
	Fazek's and Ramon0's fa-rl_meshinstance script.

	USAGE:

	This layer script requires the following two utility scripts to be
	present in your Anime Studio scripts/utility folder:
	GWB_Logger.lua and GWB_Share.lua

	A source vector layer can have any name. Duplicate vector layers
	must have the source layer name with a '.dup' extension. E.g., if
	the source layer is named "Mouth", then duplicate layers must be
	named "Mouth.dup".

	Duplicate layers should have the same points as source layer.

	The source vector layer must be located *below* all duplicate
	layers.

	The source layer and all dup layers must install this layer script.

	Only create/delete point motion and curvature keys for the source
	layer. Dup layer point motion and curvature will be automatically
	modified to match the source layer.

	TODO:

	The approach for duplicating point motion and curvature is taken
	from Fazek's and Ramon0's fa-rl_meshinstance script. This approach
	modifies duplicate point motion/curvature to match source point
	motion/curvature for every animation frame. An alternative
	approach would be to duplicate source point motion/curvature
	keyframes on duplicate layers. This alternative approach would
	permit disabling this script after source layer animation was
	complete.

]]--

--[[ -------------------------------------------------------------------------------- ]]--

function LayerScript(moho)

	-- NOTE: My preference would be to create the 'logger' and 'share'
    -- objects (defined below) outside the scope of the LayerScript
    -- function, in order to prevent their re-creation each time
    -- LayerScript is invoked. Unfortunately, when I tried this, Anime
    -- Studio crashed intermittently.

	-- create a local logger object with desired log level
	local logger = GWB_Logger:new( "GWB_MoveTogether", GWB_Logger.logLevel.ERROR )

	-- create a sharing object with desired log level
	local share = GWB_Share:new( moho, GWB_Logger.logLevel.ERROR )

    --[[ -------------------------------------------------------------------------------- ]]--

	-- Updates point motion/curvature of specified mesh based on point
    -- motion/curvature data contained in specified sharedMeshData
    -- object. This is used to update a dup layer's mesh to match that
    -- of the source layer's mesh.

	local function updateDupLayerMesh( mesh, sharedMeshData )

	    if ( not mesh ) 
		then
			logger:log( GWB_Logger.logLevel.ERROR, "no mesh defined for dup layer" )
			return
		end

		if ( sharedMeshData == nil ) 
		then
			-- create new shared mesh data object
			logger:log( GWB_Logger.logLevel.ERROR, "no shared mesh data defined for dup layer" )
			return
		end

		local numPoints = mesh:CountPoints()
		if ( sharedMeshData.numPoints < numPoints )
		then
		    numPoints = sharedMeshData.numPoints
		end

		local pointRecord
		local meshPoint
		local curve
		local curvePointID

		for pointIndex = 1, numPoints do

			meshPoint = mesh:Point( pointIndex - 1 )
			pointRecord = sharedMeshData.pointTable[ pointIndex ]
			curvePointID = -1

			meshPoint.fPos.x = pointRecord.x
			meshPoint.fPos.y = pointRecord.y
				
			-- this code is Ramon0's and i confess to not
            -- understanding the approach
			for curveIndex = 0, meshPoint:CountCurves() - 1 do
				curve, curvePointID = meshPoint:Curve( curveIndex, curvePointID )
				if tonumber( curve:GetCurvature( curvePointID, moho.layerFrame ) ) ~= tonumber( pointRecord.curvature )
				then
					curve:SetCurvature( curvePointID, pointRecord.curvature, moho.layerFrame )
				end
			end

		end

	end

    --[[ -------------------------------------------------------------------------------- ]]--

	local function initializeSharedMeshData( mesh, sharedMeshData ) 

	    if ( not mesh ) 
		then
			logger:log( GWB_Logger.logLevel.ERROR, "no mesh defined for source layer" )
			return nil
		end

		if ( sharedMeshData == nil ) 
		then
			-- create new shared mesh data object
			logger:log( GWB_Logger.logLevel.WARN, "no shared mesh data defined for source layer" )
		    sharedMeshData = {}
		end

		sharedMeshData.numPoints = mesh:CountPoints()

		-- create new point data table - could clear existing table
        -- here instead of creating new one (and garbage collecting
        -- old one) - unsure which option is most performant
		sharedMeshData.pointTable = {}

		local point
		local curve
		local curvePointID
		local pointRecord

		for pointIndex = 0, sharedMeshData.numPoints - 1 do

			point = mesh:Point( pointIndex )
			curvePointID = -1
			
			-- this code is Ramon0's and i confess to not
            -- understanding the approach
			for curveIndex = 0, point:CountCurves() - 1 do
				curve, curvePointID = point:Curve( curveIndex, curvePointID )			
			end

			-- define point record for current point
			pointRecord = {}
			pointRecord.x = point.fPos.x
			pointRecord.y = point.fPos.y

			pointRecord.curvature = curve:GetCurvature( curvePointID, moho.layerFrame )
			
			-- add point record to the shared point table
			table.insert( sharedMeshData.pointTable, pointRecord )

		end

		return sharedMeshData
	end	

    --[[ -------------------------------------------------------------------------------- ]]--

	local scriptLayer = moho.layer

	-- ensure current layer is a vector layer o.w. return
	if ( scriptLayer:LayerType() ~= MOHO.LT_VECTOR ) 
	then
		logger:log( GWB_Logger.logLevel.ERROR, "layer script for "..scriptLayer:Name().." can only be used with a vector layer" )
	    return
	end

	-- get layer's mesh
	local mesh = moho:Mesh()

	-- two different behaviors depending on whether current layer is
    -- dup layer or source layer:

	if share:isDupLayer( scriptLayer )
	then

	    if share:dupLayerConstraintsSatisfied( scriptLayer )
		then
			-- update dup layer's point motion/curvature based on source's shared data value
		    updateDupLayerMesh( mesh, share:getSharedValue( scriptLayer ) )
		end

	elseif share:sourceLayerConstraintsSatisfied( scriptLayer ) -- current layer is a source layer
	then
		-- update shared data value with source layer's current point motion/curvature
		share:setSharedValue( scriptLayer, initializeSharedMeshData( mesh, share:getSharedValue( scriptLayer ) ) )

	end -- if share:isDupLayer( scriptLayer )

end
