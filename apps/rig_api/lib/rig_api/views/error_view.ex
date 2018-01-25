defmodule RigApi.ErrorView do
  use RigApi, :view

  def render("404.json", _assigns) do
    %{errors: %{detail: "Not found"}}
  end

  def render("401.json", _assigns) do
    %{errors: %{detail: "Unauthorized"}}
  end

  def render("4" <> <<_::bytes-size(2)>> <> ".json", _assigns) do
    %{errors: %{detail: "Bad request"}}
  end

  def render("500.json", _assigns) do
    %{errors: %{detail: "Internal server error"}}
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.json", assigns
  end
end
