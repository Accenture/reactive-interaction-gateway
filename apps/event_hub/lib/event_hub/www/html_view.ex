defmodule EventHub.WWW.HTMLView do
  layout_path = Path.join(__DIR__, "_layout.html.eex")

  require EEx
  EEx.function_from_file(:def, :render_layout, layout_path, [:content, :assigns], engine: Phoenix.HTML.Engine)

  defmacro __using__(_options) do
    quote do
      file_path = case String.split(__ENV__.file, ~r/\.ex(s)?$/) do
        [path_and_name, ""] ->
          path_and_name <> ".html.eex"
        _ ->
          raise "#{__MODULE__} needs to be used from a `.ex` or `.exs` file"
      end

      require EEx
      EEx.function_from_file(:defp, :render_content, file_path, [:assigns], engine: Phoenix.HTML.Engine)

      def render(response, assigns) do
        {:safe, io_list} = unquote(__MODULE__).render_layout(render_content(assigns), assigns)

        response
        |> Raxx.set_header("content-type", "text/html")
        |> Raxx.set_body("#{io_list}")
      end
    end
  end
end
