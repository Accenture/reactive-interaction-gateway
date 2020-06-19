defmodule RigApi.V2.APIsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use RigApi.ConnCase

  alias RigInboundGateway.ProxyConfig

  require Logger

  @invalid_config_id "invalid-config"

  describe "GET /v2/apis" do
    test "should return list of APIs and filter deactivated APIs" do
      conn = build_conn() |> get("/v2/apis")
      assert json_response(conn, 200) |> length == 1
    end
  end

  describe "GET /v2/apis/:id" do
    test "should return requested API" do
      conn = build_conn() |> get("/v2/apis/new-service")
      response = json_response(conn, 200)
      assert response["id"] == "new-service"
    end

    test "should 404 if requested API doesn't exist" do
      conn = build_conn() |> get("/v2/apis/fake-service")
      response = json_response(conn, 404)
      assert response["message"] == "API with id=fake-service doesn't exists."
    end

    test "should return 404 if API exists, but is deactivated" do
      conn = build_conn() |> get("/v2/apis/another-service")
      response = json_response(conn, 404)
      assert response["message"] == "API with id=another-service doesn't exists."
    end
  end

  describe "POST /v2/apis" do
    test "should add new API" do
      new_api = @mock_api |> Map.put("id", "different-id")
      conn = build_conn() |> post("/v2/apis", new_api)
      response = json_response(conn, 201)
      assert response["message"] == "ok"
    end

    test "should return 409 if API already exist" do
      conn = build_conn() |> post("/v2/apis", @mock_api)
      response = json_response(conn, 409)
      assert response["message"] == "API with id=new-service already exists."
    end

    test "should replaced deactivated API with same ID" do
      new_api = @mock_api |> Map.put("id", "another-service")
      conn = build_conn() |> post("/v2/apis", new_api)
      response = json_response(conn, 201)
      assert response["message"] == "ok"
    end

    test "should return 400 when target is set to kafka or kinesis, but topic is not" do
      # kinesis topic not set
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo",
          "target" => "kinesis"
        }
      ]

      kinesis_orig_value = ProxyConfig.set("PROXY_KINESIS_REQUEST_STREAM", "")

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints)
      conn = build_conn() |> post("/v2/apis", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config/invalid-config1" => [
                 %{"kinesis_request_stream" => "must be present"},
                 %{"topic" => "must be present"}
               ]
             }

      ProxyConfig.restore("PROXY_KINESIS_REQUEST_STREAM", kinesis_orig_value)

      # kafka topic not set
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo",
          "target" => "kafka"
        }
      ]

      kafka_orig_value = ProxyConfig.set("PROXY_KAFKA_REQUEST_TOPIC", "")

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints)
      conn = build_conn() |> post("/v2/apis", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config/invalid-config1" => [
                 %{"kafka_request_topic" => "must be present"},
                 %{"topic" => "must be present"}
               ]
             }

      ProxyConfig.restore("PROXY_KAFKA_REQUEST_TOPIC", kafka_orig_value)
    end

    test "should return 400 when schema is set, but target is not kafka or kinesis" do
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo",
          "schema" => "some-avro-schema"
        }
      ]

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints)
      conn = build_conn() |> post("/v2/apis", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config/invalid-config1" => [
                 %{"target" => "must be present"}
               ]
             }
    end

    test "should return 400 when secured is set, but auth_type is not jwt" do
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo",
          "secured" => true
        }
      ]

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints)
      conn = build_conn() |> post("/v2/apis", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config/invalid-config1" => [
                 %{"auth_type" => "must be one of [\"jwt\"]"}
               ]
             }
    end

    test "should return 400 when use_header is set, but header_name is not" do
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo"
        }
      ]

      auth = %{"use_header" => true}
      auth_type = "jwt"

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints, auth, auth_type)
      conn = build_conn() |> post("/v2/apis", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config" => [%{"header_name" => "must be present"}]
             }
    end

    test "should return 400 when use_query is set, but query_name is not" do
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo"
        }
      ]

      auth = %{"use_query" => true}
      auth_type = "jwt"

      ProxyConfig.create_proxy_config(@invalid_config_id, endpoints, auth, auth_type)

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints, auth, auth_type)
      conn = build_conn() |> post("/v2/apis", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config" => [%{"query_name" => "must be present"}]
             }
    end

    test "should return 400 when auth is set, but auth_type is not" do
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo"
        }
      ]

      auth = %{"use_query" => true, "query_name" => "test"}

      ProxyConfig.create_proxy_config(@invalid_config_id, endpoints, auth)

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints, auth)
      conn = build_conn() |> post("/v2/apis", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config" => [%{"auth_type" => "must be one of [\"jwt\"]"}]
             }
    end
  end

  describe "PUT /v2/apis/:id" do
    test "should update requested API" do
      conn = build_conn() |> put("/v2/apis/new-service", @mock_api)
      response = json_response(conn, 200)
      assert response["message"] == "ok"
    end

    test "should return 404 if requested API doesn't exist" do
      conn =
        build_conn()
        |> put("/v2/apis/fake-service", %{
          "id" => "fake",
          "name" => "fake",
          "version_data" => %{"default" => %{"endpoints" => []}},
          "proxy" => %{
            "port" => 3000,
            "target_url" => "http://localhost"
          }
        })

      response = json_response(conn, 404)
      assert response["message"] == "API with id=fake-service doesn't exists."
    end

    test "should return 404 if API exists, but is deactivated" do
      conn = build_conn() |> put("/v2/apis/another-service", @mock_api)
      response = json_response(conn, 404)
      assert response["message"] == "API with id=another-service doesn't exists."
    end

    test "should return 400 when api doesn't have required top level properties 'id', 'name', 'proxy' and 'version_data'" do
      conn = build_conn() |> put("/v2/apis/#{@invalid_config_id}", %{})
      response = json_response(conn, 400)

      assert response == %{
               "api" => [
                 %{"name" => "must be string"},
                 %{"name" => "must have a length of at least 1"},
                 %{"proxy" => "must be present"},
                 %{"version_data" => "must be present"}
               ]
             }
    end

    test "should return 400 when 'proxy' doesn't have required properties 'target_url' and 'port'" do
      new_api = %{
        "id" => "invalid_proxy",
        "name" => "invalid_proxy",
        "proxy" => %{},
        "version_data" => %{
          "default" => %{
            "endpoints" => []
          }
        }
      }

      conn = build_conn() |> put("/v2/apis/#{@invalid_config_id}", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "api" => [
                 %{"proxy" => "must be present"},
                 %{"target_url" => "must be string"},
                 %{"target_url" => "must have a length of at least 1"},
                 %{"port" => "must be integer"}
               ]
             }
    end

    test "should return 400 when 'version_data' doesn't have any version" do
      new_api = %{
        "id" => "invalid_proxy",
        "name" => "invalid_proxy",
        "proxy" => %{
          "port" => 3000,
          "target_url" => "http://localhost"
        },
        "version_data" => %{}
      }

      conn = build_conn() |> put("/v2/apis/#{@invalid_config_id}", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "api" => [
                 %{"version_data" => "must be present"},
                 %{
                   "version_data" => "must have at least one version, e.g. default"
                 }
               ]
             }
    end

    test "should return 400 when 'default' version doesn't have 'endpoints' property or is not a list" do
      # missing "endpoints" property
      new_api = %{
        "id" => "invalid_proxy",
        "name" => "invalid_proxy",
        "proxy" => %{
          "port" => 3000,
          "target_url" => "http://localhost"
        },
        "version_data" => %{
          "default" => %{}
        }
      }

      conn = build_conn() |> put("/v2/apis/#{@invalid_config_id}", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "api" => [
                 %{"endpoints" => "must be list"}
               ]
             }

      # "endpoints" not list
      new_api = %{
        "id" => "invalid_proxy",
        "name" => "invalid_proxy",
        "proxy" => %{
          "port" => 3000,
          "target_url" => "http://localhost"
        },
        "version_data" => %{
          "default" => %{"endpoints" => %{}}
        }
      }

      conn = build_conn() |> put("/v2/apis/#{@invalid_config_id}", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "api" => [
                 %{"endpoints" => "must be list"}
               ]
             }
    end

    test "should return 400 when 'endpoint' doesn't have required properties 'id', 'method' and 'path'" do
      endpoints = [%{}]
      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints)
      conn = build_conn() |> put("/v2/apis/#{@invalid_config_id}", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config/" => [
                 %{"id" => "must be string"},
                 %{"id" => "must have a length of at least 1"},
                 %{"path" => "must be string"},
                 %{"path" => "must have a length of at least 1"},
                 %{"method" => "must be string"},
                 %{"method" => "must have a length of at least 1"}
               ]
             }
    end

    test "should return 400 when target is set to kafka or kinesis, but topic is not" do
      # kinesis topic not set
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo",
          "target" => "kinesis"
        }
      ]

      kinesis_orig_value = ProxyConfig.set("PROXY_KINESIS_REQUEST_STREAM", "")

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints)
      conn = build_conn() |> put("/v2/apis/#{@invalid_config_id}", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config/invalid-config1" => [
                 %{"kinesis_request_stream" => "must be present"},
                 %{"topic" => "must be present"}
               ]
             }

      ProxyConfig.restore("PROXY_KINESIS_REQUEST_STREAM", kinesis_orig_value)

      # kafka topic not set
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo",
          "target" => "kafka"
        }
      ]

      kafka_orig_value = ProxyConfig.set("PROXY_KAFKA_REQUEST_TOPIC", "")

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints)
      conn = build_conn() |> put("/v2/apis/#{@invalid_config_id}", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config/invalid-config1" => [
                 %{"kafka_request_topic" => "must be present"},
                 %{"topic" => "must be present"}
               ]
             }

      ProxyConfig.restore("PROXY_KAFKA_REQUEST_TOPIC", kafka_orig_value)
    end

    test "should return 400 when schema is set, but target is not kafka or kinesis" do
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo",
          "schema" => "some-avro-schema"
        }
      ]

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints)
      conn = build_conn() |> put("/v2/apis/#{@invalid_config_id}", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config/invalid-config1" => [
                 %{"target" => "must be present"}
               ]
             }
    end

    test "should return 400 when secured is set, but auth_type is not jwt" do
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo",
          "secured" => true
        }
      ]

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints)
      conn = build_conn() |> put("/v2/apis/#{@invalid_config_id}", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config/invalid-config1" => [
                 %{"auth_type" => "must be one of [\"jwt\"]"}
               ]
             }
    end

    test "should return 400 when use_header is set, but header_name is not" do
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo"
        }
      ]

      auth = %{"use_header" => true}
      auth_type = "jwt"

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints, auth, auth_type)
      conn = build_conn() |> put("/v2/apis/#{@invalid_config_id}", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config" => [%{"header_name" => "must be present"}]
             }
    end

    test "should return 400 when use_query is set, but query_name is not" do
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo"
        }
      ]

      auth = %{"use_query" => true}
      auth_type = "jwt"

      ProxyConfig.create_proxy_config(@invalid_config_id, endpoints, auth, auth_type)

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints, auth, auth_type)
      conn = build_conn() |> put("/v2/apis/#{@invalid_config_id}", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config" => [%{"query_name" => "must be present"}]
             }
    end

    test "should return 400 when auth is set, but auth_type is not" do
      endpoints = [
        %{
          "id" => @invalid_config_id <> "1",
          "method" => "GET",
          "path" => "/foo"
        }
      ]

      auth = %{"use_query" => true, "query_name" => "test"}

      ProxyConfig.create_proxy_config(@invalid_config_id, endpoints, auth)

      new_api = ProxyConfig.create_proxy_config(@invalid_config_id, endpoints, auth)
      conn = build_conn() |> put("/v2/apis/#{@invalid_config_id}", new_api)
      response = json_response(conn, 400)

      assert response == %{
               "invalid-config" => [%{"auth_type" => "must be one of [\"jwt\"]"}]
             }
    end
  end

  describe "DELETE /v2/apis/:id" do
    test "should delete requested API" do
      conn = build_conn() |> delete("/v2/apis/new-service")
      response = text_response(conn, :no_content)
      assert response == ""
    end

    test "should return 404 if requested API doesn't exist" do
      conn = build_conn() |> delete("/v2/apis/fake-service")
      response = json_response(conn, 404)
      assert response["message"] == "API with id=fake-service doesn't exists."
    end

    test "should return 404 if API exists, but is deactivated" do
      conn = build_conn() |> delete("/v2/apis/another-service")
      response = json_response(conn, 404)
      assert response["message"] == "API with id=another-service doesn't exists."
    end
  end
end
