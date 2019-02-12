defmodule Result do
  @moduledoc """
  Tools for working with result tuples.

  Influenced by the Rust Option/Result implementation.
  """

  @type value :: any
  @type error :: any
  @type ok(value_type) :: {:ok, value_type}
  @type ok :: ok(any)
  @type err(error_type) :: {:error, error_type}
  @type err :: err(any)
  @type t(value_type, error_type) :: ok(value_type) | err(error_type)
  @type t :: t(any, any)

  # ---

  @doc """
  Turns a value into a result that contains that value.

  If the value is already a result, it is returned unchanged.

  ## Examples

      iex> Result.ok(:a)
      {:ok, :a}
      iex> Result.ok(Result.ok(:a))
      {:ok, :a}

  """
  @spec ok(value | ok) :: ok
  def ok(value_or_ok_result)

  def ok({:ok, _} = ok), do: ok
  def ok(value), do: {:ok, value}

  # ---

  @doc """
  Turns an error into a result that contains that error.

  If the error is already a result, it is returned unchanged.

  ## Examples

      iex> Result.err(:a)
      {:error, :a}
      iex> Result.err(Result.err(:a))
      {:error, :a}

  """
  @spec err(error | err) :: err
  def err(error_or_err_result)

  def err({:error, _} = err), do: err
  def err(error), do: {:error, error}

  # ---

  @doc """
  Returns true if a result has a contained value and false otherwise.

  ## Examples

      iex> Enum.filter([ok: 1, error: 2, ok: 3], &Result.ok?/1)
      [ok: 1, ok: 3]

      iex> Enum.split_with([ok: 1, error: 2, ok: 3], &Result.ok?/1)
      {[ok: 1, ok: 3], [error: 2]}

  """
  @spec ok?(t) :: boolean
  def ok?(result)

  def ok?({:ok, _}), do: true
  def ok?({:error, _}), do: false

  # ---

  @doc """
  Returns false if a result has a contained value and true otherwise.

  ## Examples

      iex> Enum.filter([ok: 1, error: 2, ok: 3], &Result.err?/1)
      [error: 2]

  """
  @spec err?(t) :: boolean
  def err?(result), do: not ok?(result)

  # ---

  @doc """
  Maps a Result to another Result by applying a function to a contained value, leaving
  non-ok tuples untouched.

  Note that the given function is expected to return a value. See `Result.and_then/2`
  if you want to pass a function that returns a result.

  ## Examples

      iex> {:ok, :a} |> Result.map(fn :a -> :b end)
      {:ok, :b}
      iex> {:error, :a} |> Result.map(fn :a -> :b end)
      {:error, :a}

  """
  @spec map(t, (value -> value)) :: t
  def map(result, value_to_value_fn)

  def map({:ok, value}, fun), do: {:ok, fun.(value)}
  def map({:error, _} = err, _), do: err

  # ---

  @doc """
  Maps a Result to another Result by applying a function to a contained error, leaving
  ok tuples untouched.

  This function can be used to compose the results of two functions, where the map
  function returns an error.

  ## Examples

      iex> {:error, :a} |> Result.map_err(fn :a -> :b end)
      {:error, :b}
      iex> {:ok, :a} |> Result.map_err(fn :a -> :b end)
      {:ok, :a}

  """
  @spec map_err(t, (error -> error)) :: t
  def map_err(result, error_to_error_fn)

  def map_err({:error, error}, fun), do: {:error, fun.(error)}
  def map_err({:ok, _} = ok, _), do: ok

  # ---

  @doc """
  Maps a Result to another Result by applying a function to a contained value, leaving
  non-ok tuples untouched.

  Note that the given function is expected to return a result. See `Result.map/2` if
  you want to pass a function that returns a value.

  ## Examples

      iex> {:ok, :a} |> Result.and_then(fn :a -> {:ok, :b} end)
      {:ok, :b}
      iex> {:ok, :a} |> Result.and_then(fn :a -> {:error, :b} end)
      {:error, :b}
      iex> {:error, :a} |> Result.and_then(fn :a -> {:ok, :b} end)
      {:error, :a}

  """
  @spec and_then(t, (value -> t)) :: t
  def and_then(result, value_to_result_fn)

  def and_then({:ok, value}, fun), do: fun.(value)
  def and_then({:error, _} = err, _), do: err

  # ---

  @doc """
  Maps a Result to another Result by applying a function to a contained value, leaving
  ok tuples untouched.

  Note that the given function is expected to return a result. See `Result.map_err/2`
  if you want to pass a function that returns a value.

  ## Examples

      iex> {:ok, :a} |> Result.or_else(fn :a -> {:ok, :b} end)
      {:ok, :a}
      iex> {:error, :a} |> Result.or_else(fn :a -> {:ok, :b} end)
      {:ok, :b}
      iex> {:error, :a} |> Result.or_else(fn :a -> {:error, :b} end)
      {:error, :b}

  """
  @spec or_else(t, (error -> t)) :: t
  def or_else(result, error_to_result_fn)

  def or_else({:ok, _} = ok, _), do: ok
  def or_else({:error, error}, fun), do: fun.(error)

  # ---

  @doc """
  Returns the contained value or throw an error.
  """
  @spec unwrap(ok, expectation :: String.t() | nil) :: value
  def unwrap(ok_result, expectation \\ nil)

  def unwrap({:ok, value}, _), do: value

  def unwrap({:error, _} = err, nil),
    do: raise(ArgumentError, "Not a value result: #{inspect(err)}")

  def unwrap({:error, _} = err, expectation),
    do: raise(ArgumentError, ~s(Expected "#{expectation}": #{inspect(err)}))

  # ---

  @doc """
  Returns the contained value or a default.
  """
  @spec unwrap_or(t, default :: value) :: value
  def unwrap_or(result, default_value)

  def unwrap_or({:ok, value}, _), do: value
  def unwrap_or({:error, _}, default), do: default

  # ---

  @doc """
  Returns the contained error or throw an error.
  """
  @spec unwrap_err(err) :: error
  def unwrap_err(err_result)

  def unwrap_err({:error, error}), do: error
  def unwrap_err({:ok, _} = ok), do: raise(ArgumentError, "Not an error result: #{inspect(ok)}")

  # ---

  @doc """
  Returns the contained error or a default.
  """
  @spec unwrap_err_or(t, default :: value | error) :: value | error
  def unwrap_err_or(result, default_value)

  def unwrap_err_or({:error, error}, _), do: error
  def unwrap_err_or({:ok, _}, default), do: default

  # ---

  @doc """
  Unwraps ok-results and rejects error-results.

  ## Examples

      iex> [ok: :a, ok: :b, error: :c] |> Result.filter_and_unwrap()
      [:a, :b]

  """
  @spec filter_and_unwrap([t]) :: [value]
  def filter_and_unwrap(results) when is_list(results) do
    results
    |> Enum.filter(&ok?/1)
    |> Enum.map(&unwrap/1)
  end

  # ---

  @doc """
  Unwraps error-results and rejects ok-results.

  ## Examples

      iex> [ok: :a, ok: :b, error: :c] |> Result.filter_and_unwrap_err()
      [:c]

  """
  @spec filter_and_unwrap_err([t]) :: [error]
  def filter_and_unwrap_err(results) when is_list(results) do
    results
    |> Enum.filter(&err?/1)
    |> Enum.map(&unwrap_err/1)
  end
end
