expected_text = "the event was consumed from a NATS topic and published to the client"
{:ok, gnat} = Gnat.start_link(%{host: '127.0.0.1', port: 4222})
:ok = Gnat.pub(gnat, "rig-test", ~s({"specversion":"0.2","type":"test","source":"i9ntest","id":"1","data":{"text":"#{expected_text}"}}))
