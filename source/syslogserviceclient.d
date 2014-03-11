module syslogserviceclient;

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
	void log(string _event)()
	{
		import vibe.core.core:runTask;
		import vibe.http.client:requestHTTP,HTTPClientRequest,HTTPMethod;

		runTask({
			requestHTTP(url~_event,
			            (scope HTTPClientRequest req) {
				req.method = HTTPMethod.POST;
				
				req.writeBody(cast(ubyte[])"");
			}
			);
		});
	}
}


