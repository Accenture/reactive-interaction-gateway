defmodule GatewayWeb.Proxy.ControllerTest do
  @moduledoc false
  require Logger
  use ExUnit.Case, async: false
  use GatewayWeb.ConnCase

  import Mock

  describe "GET /apis" do
    test "should return list of APIs" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [list_apis: fn(_server) -> [{@mock_api["id"], @mock_api}] end]},
      ]) do
        conn = build_conn() |> get("/apis")
        assert json_response(conn, 200) |> length == 1
      end
    end

    test "should filter deacivated APIs" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [list_apis: fn(_server) ->
           inactive_api = @mock_api |> Map.put("active", false)
           [{@mock_api["id"], @mock_api}, {"new-service", inactive_api}]
         end]},
      ]) do
        conn = build_conn() |> get("/apis")
        assert json_response(conn, 200) |> length == 1
      end
    end
  end

  describe "GET /apis/:id" do
    test "should return requested API" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> {@mock_api["id"], @mock_api} end]},
      ]) do
        conn = build_conn() |> get("/apis/new-service")
        response = json_response(conn, 200)
        assert response["id"] == "new-service"
      end
    end

    test "should 404 if requested API doesn't exist" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> nil end]},
      ]) do
        conn = build_conn() |> get("/apis/fake-service")
        response = json_response(conn, 404)
        assert response["message"] == "API with id=fake-service doesn't exists."
      end
    end

    test "should return 403 if API exists, but is deactivated" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> {"id", %{"active" => false}} end]},
      ]) do
        conn = build_conn() |> get("/apis/new-service")
        response = json_response(conn, 403)
        assert response["message"] == "Resource with id=new-service is forbidden."
      end
    end

    test "should return 500 if API wasn't read successfully" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> :error end]},
      ]) do
        conn = build_conn() |> get("/apis/new-service")
        response = json_response(conn, 500)
        assert response == %{}
      end
    end
  end

  describe "POST /apis" do
    test "should add new API" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> nil end,
          add_api: fn(_server, _id, _api) -> {:ok, "phx_ref"} end]},
      ]) do
        conn = build_conn() |> post("/apis", @mock_api)
        response = json_response(conn, 201)
        assert response["message"] == "ok"
      end
    end

    test "should return 409 if API already exist" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> {@mock_api["id"], @mock_api} end,
          add_api: fn(_server, _id, _api) -> {:ok, "phx_ref"} end]},
      ]) do
        conn = build_conn() |> post("/apis", @mock_api)
        response = json_response(conn, 409)
        assert response["message"] == "API with id=new-service already exists."
      end
    end

    test "should replaced deactivated API with same ID" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> {"id", %{"active" => false}} end,
          update_api: fn(_server, _id, _api) -> {:ok, "phx_ref"} end]},
      ]) do
        conn = build_conn() |> post("/apis", @mock_api)
        response = json_response(conn, 201)
        assert response["message"] == "ok"
      end
    end

    test "should return 500 if API wasn't added successfully" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> nil end,
          add_api: fn(_server, _id, _api) -> :error end]},
      ]) do
        conn = build_conn() |> post("/apis", @mock_api)
        response = json_response(conn, 500)
        assert response == %{}
      end
    end
  end
  
  describe "PUT /apis/:id" do
    test "should update requested API" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> {@mock_api["id"], @mock_api} end,
          update_api: fn(_server, _id, _api) -> {:ok, "phx_ref"} end]},
      ]) do
        conn = build_conn() |> put("/apis/new-service", @mock_api)
        response = json_response(conn, 200)
        assert response["message"] == "ok"
      end
    end

    test "should return 404 if requested API doesn't exist" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> nil end]},
      ]) do
        conn = build_conn() |> put("/apis/fake-service", %{})
        response = json_response(conn, 404)
        assert response["message"] == "API with id=fake-service doesn't exists."
      end
    end

    test "should return 403 if API exists, but is deactivated" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> {"id", %{"active" => false}} end]},
      ]) do
        conn = build_conn() |> put("/apis/new-service", @mock_api)
        response = json_response(conn, 403)
        assert response["message"] == "Resource with id=new-service is forbidden."
      end
    end

    test "should return 500 if API wasn't updated successfully" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> {@mock_api["id"], @mock_api} end,
          update_api: fn(_server, _id, _api) -> {:error, :down} end]},
      ]) do
        conn = build_conn() |> put("/apis/new-service", @mock_api)
        response = json_response(conn, 500)
        assert response == %{}
      end
    end
  end

  describe "DELETE /apis/:id" do
    test "should delete requested API" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> {@mock_api["id"], @mock_api} end,
          deactivate_api: fn(_server, _id) -> {:ok, "phx_ref"} end]},
      ]) do
        conn = build_conn() |> delete("/apis/new-service")
        response = json_response(conn, 204)
        assert response == %{}
      end
    end

    test "should return 404 if requested API doesn't exist" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> nil end]},
      ]) do
        conn = build_conn() |> delete("/apis/fake-service")
        response = json_response(conn, 404)
        assert response["message"] == "API with id=fake-service doesn't exists."
      end
    end

    test "should return 403 if API exists, but is deactivated" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> {"id", %{"active" => false}} end]},
      ]) do
        conn = build_conn() |> delete("/apis/new-service")
        response = json_response(conn, 403)
        assert response["message"] == "Resource with id=new-service is forbidden."
      end
    end

    test "should return 500 if API wasn't deleted successfully" do
      with_mocks([
        {Gateway.Proxy,
         [],
         [get_api: fn(_server, _id) -> {@mock_api["id"], @mock_api} end,
          deactivate_api: fn(_server, _id) -> {:error, :down} end]},
      ]) do
        conn = build_conn() |> delete("/apis/new-service")
        response = json_response(conn, 500)
        assert response == %{}
      end
    end
  end
end
