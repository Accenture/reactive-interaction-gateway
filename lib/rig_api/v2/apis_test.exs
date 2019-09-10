defmodule RigApi.V2.APIsTest do
  @moduledoc false
  require Logger
  use ExUnit.Case, async: true
  use RigApi.ConnCase

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
  end

  describe "PUT /v2/apis/:id" do
    test "should update requested API" do
      conn = build_conn() |> put("/v2/apis/new-service", @mock_api)
      response = json_response(conn, 200)
      assert response["message"] == "ok"
    end

    test "should return 404 if requested API doesn't exist" do
      conn = build_conn() |> put("/v2/apis/fake-service", %{})
      response = json_response(conn, 404)
      assert response["message"] == "API with id=fake-service doesn't exists."
    end

    test "should return 404 if API exists, but is deactivated" do
      conn = build_conn() |> put("/v2/apis/another-service", @mock_api)
      response = json_response(conn, 404)
      assert response["message"] == "API with id=another-service doesn't exists."
    end
  end

  describe "DELETE /v2/apis/:id" do
    test "should delete requested API" do
      conn = build_conn() |> delete("/v2/apis/new-service")
      response = json_response(conn, 204)
      assert response == %{}
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
