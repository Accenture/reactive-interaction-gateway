defmodule RigInboundGateway.Metadata do
  @moduledoc """
  Utils to extract metadata from JSON and JWT
  """

  use Rig.Config, [:jwt_fields, :indexed_metadata]

  alias Result
  alias RIG.JWT
  alias RIG.Plug.BodyReader

  def extract(json, auth_tokens) do
    {json_metadata_err, json_metadata} = extract_metadata_from_json(json)
    {_, jwt_metadata} = extract_metadata_from_jwt(auth_tokens)

    if json_metadata_err === :error do
      {:error, json_metadata}
    else
      # Merge values from metadata with the values from JWT, prioritizing JWT values
      metadata = Map.merge(json_metadata, jwt_metadata)

      # Check if metadata contains all the indexed fields; if not: send back a bad request
      # This needs to be done here because now the values from the JWT got inserted
      if has_required_indices?(metadata) do
        conf = config()
        indexed_fields = for x <- conf.indexed_metadata, do: {x, metadata[x]}

        {:ok, {metadata, indexed_fields}}
      else
        message = """
        Metadata doesn't contain indexed fields.
        """
        {:error, message}
      end
    end
  end

  def extract(conn) do
    with {:ok, body, _conn} <- BodyReader.read_full_body(conn) do
      extract(body, Map.get(conn.assigns, :auth_tokens, []))
    else
      error ->
        message = """
        Expected JSON encoded body.

        Technical info:
        #{inspect(error)}
        """

        {:error, message}
    end
  end

  # ---

  def extract_metadata_from_jwt(auth_tokens) do
    with {:ok, claims} <- auth_tokens
    |> Enum.map(fn
      {"bearer", token} -> JWT.parse_token(token || "")
      _ -> {:ok, %{}}
    end)
    |> Result.list_to_result()
    |> Result.map_err(fn decode_errors -> {:error, decode_errors} end) do
      conf = config()
      jwt_metadata_mapping = conf.jwt_fields

      # Merge the list of claims into a single map
      claims = Enum.reduce(claims, fn x, y ->
        Map.merge(x, y, fn _k, v1, v2 -> v2 ++ v1 end)
      end)

      # Get values from JWT
      {:ok, (for {key, jwt_key} <- jwt_metadata_mapping,
        jwt_val = claims[jwt_key],
        into: %{},
        do: {key, jwt_val})}
    else
      {:error, _} ->
        {:error, %{}}
    end
  end

  # ---

  def extract_metadata_from_json(nil), do: {:error, nil}

  def extract_metadata_from_json(body) do
    with {:ok, json} <- Jason.decode(body),
          {:parse, %{"metadata" => metadata}} <- {:parse, json} do
      {:ok, metadata}
    else
      {:parse, json} ->
        message = """
        Expected field "metadata" is not present.

        Decoded request body:
        #{inspect(json)}
        """

        {:error, message}

      error ->
        message = """
        Expected JSON encoded body.

        Technical info:
        #{inspect(error)}
        """

        {:error, message}
    end
  end

  # ---

  @doc """
  Since RIG can propagate metadata through its network of RIG nodes, these datasets **need** to have all of the required indices
  (as specified in the configuration) for the mapping (index -> RIG instance where the data is actually located at) to work.

  There are no *required* fields in RIG metadata, just required indices. Thus, this method is called `has_required_indices` and not `has_required_fields`.
  """
  defp has_required_indices?(metadata) do
    conf = config()
    metadata_keys = Map.keys(metadata)
    Enum.all?(conf.indexed_metadata, fn x -> Enum.member?(metadata_keys, x) end)
  end
end
