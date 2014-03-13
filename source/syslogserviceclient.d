module syslogserviceclient;

import vibe.core.core:runTask;
import vibe.http.client;

///
class SyslogServiceClient
{
private:
	immutable string m_url;

public:
	///
	this(in string _url)
	{
		import std.string:endsWith;

		if(!_url.endsWith("/"))
			m_url = _url~"/";
		else
			m_url = _url;
	}

	///
	void log(string _event)(in string[string] params)
	{
		if(m_url.length == 0)
			return;

		runTask({
			auto requestUrl = m_url~getAdditionalUrlString()~_event;

			auto res = requestHTTP(requestUrl,
			(scope HTTPClientRequest req) {
				req.method = HTTPMethod.POST;
	
				import vibe.http.form;
				req.writeFormBody(params);
			});
			scope(exit) res.dropBody();
		});
	}

	///
	void log(string _event)()
	{
		if(m_url.length == 0)
			return;

		runTask({
			auto requestUrl = m_url~getAdditionalUrlString()~_event;

			auto res = requestHTTP(requestUrl,
			(scope HTTPClientRequest req) {
				req.method = HTTPMethod.POST;
				
				req.writeBody(cast(ubyte[])"");
			});
			scope(exit) res.dropBody();
		});
	}

	///
	protected string getAdditionalUrlString()
	{
		return "";
	}
}
