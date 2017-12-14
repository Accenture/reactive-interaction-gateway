changelog

fixed: "username" hardcoded in presence channel, did not respect JWT_USER_FIELD setting

new

minor: lazy logger calls for debug logs
minor: formatting using Elixir 1.6 formatter
feature: POST /messages



todo

kafka message has user field but what about userfield in http post for POST /messages

socket authentication can be commented out with all tests passing :/

kafka.sup does not respect KAFKA_ENABLED=0 anymore

logging to Kafka is gone... logger app with kafka module?



http://localhost:4000/socket/sse?users[]=foo&roles[]=support&token=asdf



    {:ok, assign(socket, :user_info, %{"user" => "foo", "roles" => ["support", "customer", "user"]})}
