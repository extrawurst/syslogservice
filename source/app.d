module app;

import vibe.d;

import syslogservice;

shared static this()
{
	ushort port = 8888;
	string hostName = "hostUnknown";
	string fileSuffix = "";
	string logFolder = "./";
	bool quiet = true;
	bool oneFilePerHour = false;

	getOption("folder",&logFolder,"log folder (default './'");
	getOption("hostport",&port,"port (default '8888')");
	getOption("hostname",&hostName,"hostname (default 'hostUnknown'");
	getOption("quiet",&quiet,"disable logging of each request to stdout (default 'true')");
	getOption("filePerHour",&oneFilePerHour,"split log files per hour (default is split per day)");
	getOption("file-suffix",&fileSuffix,"added to every log filename (default is '')");

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


