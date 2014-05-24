module syslog.service;

import std.traits:isSomeString;

import vibe.d;

///
static bool equalComponents(T,COMPONENTS...)(T _a, T _b)
{
	foreach(comp; COMPONENTS)
	{
		static assert(is(typeof(comp) : string), "components must be strings");

		static assert(__traits(compiles, mixin("_a."~comp)), "component '"~comp~"' not a member of '"~T.stringof~"'");
		
		if(__traits(getMember, _a, comp) != __traits(getMember, _b, comp))
			return false;
	}
	
	return true;
}

///
final class SysLogService
{
private:
	///
	public alias RequestCallback = void delegate(string, in string[], HTTPServerRequest);

	bool m_quiet;
	ushort m_port = 8888;
	string m_hostName = "hostUnknown";
	string m_logFolder = "./";
	string m_fileSuffix = "";
	bool m_dashesInFileNameTimeStamp = false;
	bool m_oneLogPerHour = false;
	RequestCallback m_requestModifierCallback;

	SysTime m_lastFileNameUpdateTime = SysTime.min;
	string m_lastFileName;

	static immutable FORMATSTR_DAILY = "%04d-%02d-%02d_%s%s.log";
	static immutable FORMATSTR_DAILY_SHORT = "%04d%02d%02d%s%s.log";
	static immutable FORMATSTR_HOURLY = "%04d-%02d-%02d-%02d00_%s%s.log";
	static immutable FORMATSTR_HOURLY_SHORT = "%04d%02d%02d%02d00_%s%s.log";

	///
	@property public void port(ushort _port) { m_port = _port; }
	///
	@property public void quiet(bool _quiet) { m_quiet = _quiet; }
	///
	@property public void hostName(string _hostname) { m_hostName = _hostname; }
	///
	@property public void fileSuffix(string _suffix) { m_fileSuffix = _suffix.length>0 ? "_"~_suffix : ""; }
	///
	@property public void oneLogPerHour(bool _value) { m_oneLogPerHour = _value; }
	///
	@property public void enableDashesInTimeStampOfLogFiles(bool _value) { m_dashesInFileNameTimeStamp = _value; }
	///
	@property public void logFolder(string _logFolder) { m_logFolder = _logFolder; }
	///
	@property public void requestModifierCallback(RequestCallback _cb) { m_requestModifierCallback = _cb; }

	/++ 
	 + starts the http server.
	 + If not changed the default listens on port 8888, 
	 + is quiet (does not print every log msg to the stdout), 
	 + is named "hostUnknown" and 
	 + writes the logfiles to "./".
	 +/
	public void start()
	{
		auto settings = new HTTPServerSettings();
		settings.port = m_port;
		settings.options = HTTPServerOption.parseFormBody;
		settings.bindAddresses = ["0.0.0.0"];
		
		listenHTTP(settings, &handleRequest);
	}

	///
	void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
	{
		res.statusCode = 200;
		res.headers["Content-Length"]="0";
		res.writeBody("");

		if(req.requestURL.startsWith("/"))
			req.requestURL = req.requestURL[1..$];

		auto eventNames = req.requestURL.split("/");
		
		if(eventNames.length == 0 || eventNames[$-1].length == 0)
		{
			logError("req has no event set: %s",req.requestURL);
			return;
		}

		auto event = eventNames[$-1];

		//note: ignore this default request
		if(event == "favicon.ico")
			return;

		if(m_requestModifierCallback)
			m_requestModifierCallback(event, eventNames[0..$-1], req);
		
		syslog(eventNames, req.form, req.peer, req.clientAddress.port);
	}

	///
	void syslog(string[] _events, FormFields _values, string _ip, ushort _port)
	{
		auto logline = createSyslogLine(_events, _values);
		
		if(!m_quiet)
			logInfo("%s",logline);
		
		appendToFile(m_logFolder ~ getLogFileName(), logline);
	}

	///
	string getLogFileName()
	{
		auto currentTime = Clock.currTime();

		if(!m_oneLogPerHour)
		{
			if(!equalComponents!(SysTime,"year","month","day")(currentTime,m_lastFileNameUpdateTime))
			{
				m_lastFileName = format(m_dashesInFileNameTimeStamp?FORMATSTR_DAILY:FORMATSTR_DAILY_SHORT,
		              currentTime.year,
		              currentTime.month,
		              currentTime.day,
		              m_hostName,
		              m_fileSuffix);

				m_lastFileNameUpdateTime = currentTime;
			}
		}
		else
		{
			if(!equalComponents!(SysTime,"year","month","day","hour")(currentTime,m_lastFileNameUpdateTime))
			{
				m_lastFileName = format(m_dashesInFileNameTimeStamp?FORMATSTR_HOURLY:FORMATSTR_HOURLY_SHORT,
				                        currentTime.year,
				                        currentTime.month,
				                        currentTime.day,
				                        currentTime.hour,
				                        m_hostName,
				                        m_fileSuffix);
				
				m_lastFileNameUpdateTime = currentTime;
			}
		}

		return m_lastFileName;
	}

	///
	string getLogLineDate()
	{
		auto currentTime = Clock.currTime();
		
		enum monthNames = [ 
			"Jan", "Feb", "Mar", "Apr", "May", "Jun", 
			"Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ];
		
		//Sep 11 00:02:14
		return format("%s %02d %02d:%02d:%02d",
		              monthNames[currentTime.month-1],
		currentTime.day,
		currentTime.hour,
		currentTime.minute,
		currentTime.second);
	}

	///
	string createSyslogLine(string[] _events, FormFields _values)
	{
		import std.array;
		
		Appender!string line;
		
		line.put(getLogLineDate());
		
		line ~= " "; 
		line ~= m_hostName;

		foreach(e; _events[0..$-1])
		{
			line ~= " ";
			line ~= e;
		}

		line ~= " - ";
		line ~= _events[$-1];
		
		if(_values.length > 0)
		{
			line ~= " [";
			
			foreach(k, v; _values)
			{
				line ~= k;
				line ~= "=\"";
				line ~= v; 
				line ~= "\" ";
			}
			
			line ~= "]";
		}
		
		line ~= "\n";
		
		return line.data;
	}
}
