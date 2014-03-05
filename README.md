syslogservice
=============

webservice that gathers arbitrary requests in syslog format on disk (we use this primarily to feed splunk)

usage
=============

run it with default settings like this:
`dub`

which prints:
```
Running .\syslogservice.exe
Listening for HTTP requests on 0.0.0.0:8888
hostname: hostUnknown
quiet: true
logfolder: './'
```

now the service listens on port 8888 for stuff to write to log.
test it using curl:
`curl --data "param1=value1&param2=value2" http://localhost:8888/foo`

which leads to a log line like this:
`Mar 05 15:30:40 hostUnknown foo - [param1="value1" param2="value2" ]`