module app;

import vibe.d;

import syslogservice;

shared static this()
{
	ushort port = 8888;
	string hostName = "hostUnknown";
	string logFolder = "./";
	bool quiet = true;

	getOption("folder",&logFolder,"log folder");
	getOption("hostport",&port,"port");
	getOption("hostname",&hostName,"hostname");
	getOption("quiet",&quiet,"no logging");

	auto logger = new SysLogService();
	logger.port = port;
	logger.hostName = hostName;
	logger.logFolder = logFolder;
	logger.quiet = quiet;

	logger.start();

	logInfo("hostname: %s",hostName);
	logInfo("quiet: %s",quiet);
	logInfo("logfolder: '%s'",logFolder);
	logInfo(" ");
}
