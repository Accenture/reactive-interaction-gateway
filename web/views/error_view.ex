defmodule Gateway.ErrorView do
  use Gateway.Web, :view

  def render("400.json", assigns) do
    %{reason: reason} = assigns
    %{errors: %{message: "#{reason.exception.message}"}}
  end

  def render("404.json", assigns) do
    %{reason: reason} = assigns
    %{errors: %{message: "#{reason.exception.message}"}}
  end

  def render("500.json", assigns) do
    %{reason: reason} = assigns
    %{errors: %{message: "#{reason.exception.message}"}}
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.json", assigns
  end
end
