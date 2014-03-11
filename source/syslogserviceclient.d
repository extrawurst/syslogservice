module syslogserviceclient;

import vibe.core.core:runTask;
import vibe.http.client;

///
final class SyslogServiceClient
{
private:
	immutable string url;

public:
	///
	this(in string _url)
	{
		url = _url;
	}

	///
	void log(string _event)(in string[string] params)
	{
		import vibe.http.form;

		if(url.length == 0)
			return;

		runTask({
			requestHTTP(url~_event,
			            (scope HTTPClientRequest req) {
				req.method = HTTPMethod.POST;
				
				req.writeFormBody(params);
			});
		});
	}

	///
	void log(string _event)()
	{
		if(url.length == 0)
			return;

		runTask({
			requestHTTP(url~_event,
			            (scope HTTPClientRequest req) {
				req.method = HTTPMethod.POST;
				
				req.writeBody(cast(ubyte[])"");
			});
		});
	}
}


