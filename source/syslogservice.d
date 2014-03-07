module syslogservice;

import vibe.d;

///
final class SysLogService
{
private:
	///
	public alias RequestCallback = void delegate(string,HTTPServerRequest);

	bool m_quiet;
	ushort m_port = 8888;
	string m_hostName = "hostUnknown";
	string m_logFolder = "./";
	RequestCallback m_requestModifierCallback;

	///
	@property public void port(ushort _port) { m_port = _port; }
	///
	@property public void quiet(bool _quiet) { m_quiet = _quiet; }
	///
	@property public void hostName(string _hostname) { m_hostName = _hostname; }
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

	void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
	{
		res.statusCode = 200;
		res.writeBody("");
		
		auto lastSlash = req.requestURL.lastIndexOf('/');
		if(lastSlash == -1)
		{
			logError("req has no event set: %s",req.requestURL);
			return;
		}
		
		auto event = req.requestURL[lastSlash+1..$];
		
		if(event.length == 0)
		{
			logError("req has no event set: %s",req.requestURL);
			return;
		}

		//note: ignore this default request
		if(event == "favicon.ico")
			return;

		if(m_requestModifierCallback)
			m_requestModifierCallback(event, req);
		
		syslog(event, req.form, req.peer, req.clientAddress.port, req.headers["user-agent"]);
	}

	void syslog(string _event, FormFields _values, string _ip, ushort _port, string _userAgent)
	{
		auto logline = createSyslogLine(_event, _values);
		
		if(!m_quiet)
			logInfo("%s",logline);
		
		appendToFile(m_logFolder ~ getLogFileName(),logline);
	}
	
	string getLogFileName()
	{
		auto currentTime = Clock.currTime();
		
		return format("%04d-%02d-%02d_%s.log",
		              currentTime.year,
		              currentTime.month,
		              currentTime.day,
		              m_hostName);
	}
	
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
	
	string createSyslogLine(string _event, FormFields _values)
	{
		import std.array;
		
		Appender!string line;
		
		line.put(getLogLineDate());
		
		line ~= " "; 
		line ~= m_hostName;
		
		line ~= " ";
		line ~= _event;
		
		if(_values.length > 0)
		{
			line ~= " - [";
			
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