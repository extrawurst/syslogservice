module syslogserviceclient;

import vibe.core.core:runTask;
import vibe.http.client;

///
final class SyslogServiceClient(alias AddParams=null)
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
			});
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
			});
		});
	}

	///
	private string getAdditionalUrlString()
	{
		static if(AddParams!=null)
		{
			return AddParams()~"/";
		}
		else
		{
			return "";
		}
	}
}


