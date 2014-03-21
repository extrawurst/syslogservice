module app;

import vibe.d;
import syslog.serviceclient;

shared static this()
{
	SyslogServiceClient logger = new SyslogServiceClient("http://localhost:8888/");
	
	logger.log!"event1"();
	logger.log!"event2"(["param2":"value"]);

	setTimer(10.msecs,(){
		logger.log!"event1"();
	},true);
}