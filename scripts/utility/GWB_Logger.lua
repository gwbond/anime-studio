--[[

	GWB_Logger

	Author: gwbond
	Version: 1.0
	Compatbility: ASP 9.5

	DESCRIPTION:

	A general purpose utility for logging priority-filtered,
	time-stamped messages to the console.

	USAGE:

	This utility script should be located in your Anime Studio
	scripts/utility folder.

	To use this utility, simply create a logging instance in your
	script and then invoke its 'log' method at the desired logging
	level.

	EXAMPLE:

	For example, to create a logger instance named "My_Logger_Name",
	that logs all messages at priority WARN or greater:

	local logger = GWB_Logger:new( "My_Logger_Name", GWB_Logger.logLevel.WARN ) 

	To log a message at WARN priority:

	logger:log( GWB_Logger.logLevel.WARN, "My Message" )

	Alternatively, there is the following functionally equivalent
	short-form invocation:

	logger:warn( "My Message" )

	To set the logger's current log level to DEBUG:

	logger:setLogLevel( GWB_Logger.logLevel.DEBUG )

 ]]--

	GWB_Logger = {}

	function GWB_Logger:Name()
	    return "GWB_Logger"
	end

	function GWB_Logger:Version()
		return "1.0.0"
	end

	function GWB_Logger:Description()
		return "Log messages to the console."
	end

	function GWB_Logger:Creator()
		return "gwbond"
	end

	--[[ -------------------------------------------------------------------------------- ]]--

	function GWB_Logger:new( loggerName, loggerLevel )
	    local logger = { loggerName = loggerName, loggerLevel = loggerLevel }
		setmetatable( logger, self )
		self.__index = self
		return logger
	end
	
	--[[ -------------------------------------------------------------------------------- ]]--

	GWB_Logger.logLevel = {}

	GWB_Logger.logLevel.NONE = { string = "NONE", value = 0 }
	GWB_Logger.logLevel.ERROR = { string = "ERROR", value = 1 }
	GWB_Logger.logLevel.WARN = { string = "WARN", value = 2 }
	GWB_Logger.logLevel.DEBUG = { string = "DEBUG", value = 3 }

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Prints specified message string to script console with a
    -- timestamp if specified message level is less than or equal to
    -- the current globalLogLevel value. Returns true if message
    -- logged o.w. returns false.

	function GWB_Logger:log( messageLevel, message )

	    if ( messageLevel.value <= self.loggerLevel.value )
		then
		    print( os.date("%Y-%m-%d %H:%M:%S").." "..messageLevel.string.." ("..self.loggerName.."): "..message )
			return true
		else
		    return false
		end
	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Log an ERROR message. Returns true if message logged
    -- o.w. returns false.

	function GWB_Logger:error( message ) 
	
	    return self:log( GWB_Logger.logLevel.ERROR, message )

	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Log an WARN message. Returns true if message logged
    -- o.w. returns false.

	function GWB_Logger:warn( message ) 
	
	    return self:log( GWB_Logger.logLevel.WARN, message )

	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Log an DEBUG message. Returns true if message logged
    -- o.w. returns false.

	function GWB_Logger:debug( message ) 
	
	    return self:log( GWB_Logger.logLevel.DEBUG, message )

	end

	--[[ -------------------------------------------------------------------------------- ]]--

	-- Set logger's current log level.

	function GWB_Logger:setLogLevel( loggerLevel ) 
	
	    self.loggerLevel = loggerLevel

	end

