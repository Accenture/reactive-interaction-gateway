defmodule Gateway.ErrorViewTest do
  use Gateway.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 400.json" do
    assert render_to_string(
      Gateway.ErrorView,
      "400.json",
      [reason: %{exception: %{message: "Bad Request"}}]
    ) == "{\"errors\":{\"message\":\"Bad Request\"}}"
  end

  test "renders 404.json" do
    assert render_to_string(
      Gateway.ErrorView,
      "404.json",
      [reason: %{exception: %{message: "Not Found"}}]
    ) == "{\"errors\":{\"message\":\"Not Found\"}}"
  end
  
  test "renders 500.json" do
    assert render_to_string(
      Gateway.ErrorView,
      "500.json",
      [reason: %{exception: %{message: "Server Error"}}]
    ) == "{\"errors\":{\"message\":\"Server Error\"}}"
  end
  
  test "render any other as 500" do
    assert render_to_string(
      Gateway.ErrorView,
      "123.json",
      [reason: %{exception: %{message: "Server Error"}}]
    ) == "{\"errors\":{\"message\":\"Server Error\"}}"
  end
end
