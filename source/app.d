module app;

import vibe.d;

import std.stdio;

ushort port = 8888;
string hostName = "hostUnknown";
string logFolder = "logs/";
bool quiet = true;

shared static this()
{
	getOption("folder",&logFolder,"log folder");
	getOption("hostport",&port,"port");
	getOption("hostname",&hostName,"hostname");
	getOption("quiet",&quiet,"no logging");

	auto settings = new HTTPServerSettings();
	settings.port = port;
	settings.bindAddresses = ["0.0.0.0"];

	listenHTTP(settings, &handleRequest);

	logInfo("hostname: %s",hostName);
	logInfo("quiet: %s\n",quiet);
}

void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
{
	scope(exit)
	{
		res.statusCode = 204;
		res.writeBody("");
	}

	syslog(req.form, req.peer, req.clientAddress.port, req.headers["user-agent"]);
}

void syslog(FormFields _values, string _ip, ushort _port, string _userAgent)
{
	//note: just add those two in the start message
	if(_values["_event"] == "app-startup")
	{
		_values["ip"] = _ip;
		_values["user-agent"] = _userAgent;
	}

	auto logline = createSyslogLine(_values);

	if(!quiet)
		logInfo("%s",logline);

	appendToFile(logFolder ~ getLogFileName(),logline);
}

string getLogFileName()
{
	auto currentTime = Clock.currTime();

	return format("%04d-%02d-%02d_%s.log",
		currentTime.year,
		currentTime.month,
		currentTime.day,
		hostName);
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

string createSyslogLine(FormFields _values)
{
	//TODO: use appender
	auto eventName = _values["_event"];
	_values.remove("_event");

	auto line = getLogLineDate();

	line ~= " " ~ hostName;

	line ~= " " ~ eventName;

	line ~= " - [";
	
	foreach(k,v; _values)
	{
		line ~= k ~ "=\"" ~ v ~ "\" ";
	}
	line ~= "]\n";

	return line;
}
