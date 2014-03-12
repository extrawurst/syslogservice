module syslogserviceclient;

import vibe.core.core:runTask;
import vibe.http.client;

///
class SyslogServiceClient
{
private:
	immutable string url;

public:
	///
	this(in string _url)
	{
		import std.string:endsWith;

		if(!_url.endsWith("/"))
			url = _url~"/";
		else
			url = _url;
	}

	///
	void log(string _event)(in string[string] params)
	{
		if(url.length == 0)
			return;

		runTask({
			auto requestUrl = url~getAdditionalUrlString()~_event;

			requestHTTP(requestUrl,
			(scope HTTPClientRequest req) {
				req.method = HTTPMethod.POST;
	
				import vibe.http.form;
				req.writeFormBody(params);
			},(scope HTTPClientResponse res) {});
		});
	}

	///
	void log(string _event)()
	{
		if(url.length == 0)
			return;

		runTask({
			auto requestUrl = url~getAdditionalUrlString()~_event;

			requestHTTP(requestUrl,
			(scope HTTPClientRequest req) {
				req.method = HTTPMethod.POST;
				
				req.writeBody(cast(ubyte[])"");
			},(scope HTTPClientResponse res) {});
		});
	}

	///
	protected string getAdditionalUrlString()
	{
		return "";
	}
}


