defmodule Gateway.PageControllerTest do
  use Gateway.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert response(conn, 404) =~ "{\"message\":\"Route is not available\"}"
  end
end
