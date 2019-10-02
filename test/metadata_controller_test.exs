defmodule RigInboundGatewayWeb.V1.MetadataControllerTest do
    use ExUnit.Case, async: false

    alias RigInboundGatewayWeb.V1.MetadataController

    describe "Extract metadata:" do
        test " from JWT" do
            auth_tokens = [
                {"bearer", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5YWIxYmZmMi1hOGQ4LTQ1NWMtYjQ4YS01MDE0NWQ3ZDhlMzAiLCJuYW1lIjoiSm9obiBEb2UiLCJpYXQiOjE1Njg3MTMzNjEsImV4cCI6NDEwMzI1ODE0M30.kjiR7kFyOEeMJaY1zPCctut39eEWmKswUCNZdK5Q3-w"}
            ]

            {:ok, jwt_values} = MetadataController.extract_metadata_from_jwt(auth_tokens)
            assert jwt_values["userid"] === "9ab1bff2-a8d8-455c-b48a-50145d7d8e30"
        end

        test " from JSON" do
            json = "{\"metadata\": { \"locale\": \"de-AT\", \"timezone\": \"GMT+2\" } }"
            
            {:ok,json_values} = MetadataController.extract_metadata_from_json(json)
            assert json_values["locale"] === "de-AT"
            assert json_values["timezone"] === "GMT+2"
        end
    end

    describe "Fail extract metadata:" do
        test " from JWT" do
            auth_tokens = [
                {"bearer", "eyJhbGciOiJIUzI1NiIsInR5cCeMJaY1zPCctut39eEWmKswUCNZdK5Q3-w"}
            ]
    
            {err, jwt_values} = MetadataController.extract_metadata_from_jwt(auth_tokens)
            assert err === :error
            assert jwt_values === %{}
        end

        test " from JSON" do
            json = "{\"metadata\": { locale\": \"de-AT\", \"timezone\": \"GMT+2\" } }"
            
            {err, json_values} = MetadataController.extract_metadata_from_json(json)
            assert err === :error
            assert is_binary(json_values) 
        end
    end

end  