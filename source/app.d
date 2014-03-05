module app;

import vibe.d;

import std.stdio;

ushort port = 8888;
string hostName = "hostUnknown";
string logFolder = "./";
bool quiet = true;

shared static this()
{
	getOption("folder",&logFolder,"log folder");
	getOption("hostport",&port,"port");
	getOption("hostname",&hostName,"hostname");
	getOption("quiet",&quiet,"no logging");

	auto settings = new HTTPServerSettings();
	settings.port = port;
	settings.options = HTTPServerOption.parseFormBody;
	settings.bindAddresses = ["0.0.0.0"];

	listenHTTP(settings, &handleRequest);

	logInfo("hostname: %s",hostName);
	logInfo("quiet: %s",quiet);
	logInfo("logfolder: '%s'",logFolder);
	logInfo(" ");
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

	syslog(event, req.form, req.peer, req.clientAddress.port, req.headers["user-agent"]);
}

void syslog(string _event, FormFields _values, string _ip, ushort _port, string _userAgent)
{
	auto logline = createSyslogLine(_event, _values);

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

string createSyslogLine(string _event, FormFields _values)
{
	//TODO: use appender
	auto line = getLogLineDate();

	line ~= " " ~ hostName;

	line ~= " " ~ _event;

	if(_values.length > 0)
	{
		line ~= " - [";
		
		foreach(k, v; _values)
		{
			line ~= k ~ "=\"" ~ v ~ "\" ";
		}

		line ~= "]";
	}

	return (line ~ '\n');
}
