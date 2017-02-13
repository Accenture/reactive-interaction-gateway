defmodule Gateway.PageControllerTest do
  use Gateway.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert response(conn, 503) =~ "{\"message\":\"Route is not available\"}"
  end
end
