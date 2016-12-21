module app;

import vibe.d;

import syslog.service;

shared static this()
{
	ushort port = 8888;
	string hostName = "hostUnknown";
	string fileSuffix = "";
	string logFolder = "./";
	bool quiet = true;
	bool oneFilePerHour = false;

	readOption("folder",&logFolder,"log folder (default './'");
	readOption("hostport",&port,"port (default '8888')");
	readOption("hostname",&hostName,"hostname (default 'hostUnknown'");
	readOption("quiet",&quiet,"disable logging of each request to stdout (default 'true')");
	readOption("filePerHour",&oneFilePerHour,"split log files per hour (default is split per day)");
	readOption("file-suffix",&fileSuffix,"added to every log filename (default is '')");

	auto logger = new SysLogService();
	logger.port = port;
	logger.hostName = hostName;
	logger.logFolder = logFolder;
	logger.quiet = quiet;
	logger.fileSuffix = fileSuffix;
	logger.oneLogPerHour = oneFilePerHour;

	logger.start();

	logInfo("hostname: %s",hostName);
	logInfo("quiet: %s",quiet);
	logInfo("logfolder: '%s'",logFolder);
	logInfo("logfilesuffix: '%s'",fileSuffix);
	logInfo("logFilesSplitByHour: %s",oneFilePerHour);
	logInfo(" ");
}


