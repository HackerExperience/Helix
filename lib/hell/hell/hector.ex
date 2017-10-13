defmodule Hector do
  @moduledoc """
  Hector is a helper to:

  1) Execute raw sql queries on a Repo;
  2) While safely concatenating the values to the query
  3) With Ecto's own type casting
  4) With a sane interface

  It was born as a result of https://stackoverflow.com/q/46651888/1454986.

  **Disclaimer**: Hector provides safety measures to easily verify and cast your
  types, but as usual make sure you know what you are doing. Naively passing
  uncasted or unverified parameters to your query can make you vulnerable to
  SQL injection. The default Hector caster, used when no other caster is
  specified, does not check against invalid or potentially dangerous characters.

  # Building a SQL query

  The following command

  ```
  Hector.query "SELECT * FROM foo WHERE bar = ##1", ["baz"]
  ```

  will result into the concatenated query

  ```
  SELECT * FROM foo WHERE bar = 'baz'
  ```

  That's the core of the Hector query creation. Now to the fun part:

  ### Casting custom types

  Suppose you use a custom Ecto type, QUID. You are handling an external input.

  ```
  # Custom callback which will be called when casting any types defined on `sql`
  caster = fn type, value ->
    case type do
      :uuid ->
        # Attempts to cast value. If it's successful, returns the string that
        # should be concatenated. In case of failure, the Hector.query creation
        # will fail.
        with {:ok, _} <- UUID.cast(value) do
          {:ok, value}
        end

      _ ->
        # For all other types, fallback to the std caster from Hector
        Hector.std_caster(type, value)
    end
  end

  # We are specifying that the first param has type `:uuid`, which should be
  # handled by `caster`
  sql = "SELECT * FROM foo WHERE bar = ##1::uuid"

  # Returns {:ok, query :: String.t} if all casts were successful, and
  # {:error, reason :: term} if any verification failed, where `reason` is the
  # value returned on `caster`
  query = Hector.query(sql, [uuid], caster)
  ```

  ### Multiple parameters

  You can use multiple parameters on a query. Something like:

  ```
  sql = "SELECT * FROM foo WHERE a = ##1 AND b = ##2 LIMIT ##3"

  Hector.query(sql, ["arg1", "arg2", 100])

  # Returning "SELECT * FROM foo WHERE a = 'arg1' AND b = 'arg2' LIMIT 100"
  ```

  ### Repeated parameters

  You can[1] specify multiple repeated parameters, like:

  ```
  sql = "SELECT * FROM foo WHERE (a = ##1 AND b = ##2) OR (a = ##2 OR b = ##1)"

  Hector.query(sql, ["a", "b"])

  # Returning:
  # "SELECT * FROM foo WHERE (a = 'a' AND b = 'b') OR (a = 'b' AND b = 'a')" 
  ```

  [1] - Actually you can't. This is TODO.

  # Fetching & loading data from the database

  Once you have the query string, your next goal is to actually fetch the
  corresponding data. That's when you use `Hector.get/3` or `Hector.get!/3`.

  There are three variants of `get`, each one with a diferent loader. Loader is
  the process of shaping the raw result into something that makes sense.

  ### Variant 1: No loader / Map loader

  The first type of Loader is no loader, in which case the rows fetched are
  simply matched against the corresponding columns, returning a map.

  So on the example:

  ```
  query = Hector.query "SELECT id, password FROM foo WHERE bar = ##1", ["baz"]
  {:ok, entry} = Hector.get(Repo, query, load: false)

  # Where entry is a **list** of returned rows, each with the following format:
  # %{
  #   id: 1,
  #   password: "supers3cr3t"
  # }
  ```

  ### Variant 2: Simple loader.

  The next variant attempts to load the returned row(s) into the given module
  (which must be an Ecto.Schema). It will ignore any missing/unwanted fields.

  ```
  query = Hector.query "SELECT id, password FROM foo WHERE bar = ##1", ["baz"]
  {:ok, entry} = Hector.get(Repo, query, load: User)

  # Resulting in:
  # %User{id: %ID{number: 1}, password: "supers3cr3t}
  ```

  ### Variant 3: Custom loader.

  Finally, you can specify a custom loader, which is a two-arity function that
  receives the repo and a 2-tuple with columns and rows. Since it's a custom
  loader, any modification to the data can be defined.

  Example:

  ```
  # Custom loader is loading the data into User, as well as preloading the
  # corresponding `settings`, and applying the `User.format/0` function.
  custom_loader = fn repo, {columns, rows} ->
    rows
    |> Enum.map(fn row ->
      user = apply(repo, :load, [User, {columns, row}])

      repo
      |> apply(:preload, [user, :settings])
      |> User.format()
    end)
  end

  query = Hector.query "SELECT id, password FROM foo WHERE bar = ##1", ["baz"]
  {:ok, entry} = Hector.get(Repo, query, custom_loader)

  # Resulting in:
  # %User{id: %ID{number: 1}, password: "s3cr3t", setting: #Ecto.Association}
  ```

  ---

  For more examples, see tests at `test/hell/hector_test.exs`.

  Hector is currently part of HELL. It will be released as a separate library
  once I find the time to make hector tests use models and helpers that are not
  dependent of Helix.
  """

  # Simple result map
  def get(repo, query, load: false) do
    case Ecto.Adapters.SQL.query(repo, query) do
      {:ok, result} ->
        {:ok, simple_mapper(result)}

      error = {:error, _} ->
        error
    end
  end

  # Simple loader
  def get(repo, query, load: module) do
    case Ecto.Adapters.SQL.query(repo, query) do
      {:ok, result} ->
        {:ok, simple_loader(repo, module, result)}

      error = {:error, _} ->
        error
    end
  end

  # Custom loader
  def get(repo, query, custom_loader) when is_function(custom_loader) do
    case Ecto.Adapters.SQL.query(repo, query) do
      {:ok, result} ->
        columns = atomize_columns(result.columns)

        {:ok, custom_loader.(repo, {columns, result.rows})}

      error = {:error, _} ->
        error
    end
  end

  def get!(repo, query, load: false) do
    {:ok, result} = get(repo, query, load: false)
    result
  end

  def get!(repo, query, load: module) do
    {:ok, result} = get(repo, query, load: module)
    result
  end

  def get!(repo, query, custom_loader) when is_function(custom_loader) do
    {:ok, result} = get(repo, query, custom_loader)
    result
  end

  defp format_str(sql) do
    sql
    |> String.replace("\n", " ")  # Remove newlines
    |> remove_extra_spaces()
  end

  defp remove_extra_spaces(sql) do
    if String.contains?(sql, "  ") do
      sql
      |> String.replace("  ", " ")
      |> remove_extra_spaces()
    else
      sql
    end
  end

  @spec query(String.t, [term], term) ::
    {:ok, query :: String.t}
    | {:error, reason :: term}
  @doc """
  Generates the sql query, casting and concatenating the given params. If no
  custom `caster` is giver, Hector uses `std_caster/2`, which is potentially
  insecure.
  """
  def query(sql, params, caster \\ &std_caster/2) do
    {first, splits} =
      sql
      |> format_str()
      |> String.split("##")
      |> List.pop_at(0)

    # This whole function could be made a lot less uglier, but it works for now
    result =
      Enum.reduce_while(splits, {:ok, ""}, fn chunk, {_status, sql} ->
        {index, type, rest} = get_query_data(chunk)

        param = get_param(params, index)

        cont = fn value ->
          sql =
            if rest == :norest do
              sql <> sql_concat(value)
            else
              sql <> sql_concat(value) <> List.to_string(rest)
            end

          {:cont, {:ok, sql}}
        end

        case caster.(type, param) do
          # `caster` returned a string, so it's supposedly valid
          value when is_binary(value) ->
            cont.(value)

          # `caster` returned `{:ok, String.t}`, so it's supposedly valid.
          {:ok, value} when is_binary(value) ->
            cont.(value)

          # `caster` returned `{:error, reason :: term}`, so something's wrong.
          error = {:error, _} ->
            {:halt, error}
        end
      end)

    case result do
      {:ok, rest} ->
        {:ok, first <> rest}

      error = {:error, _} ->
        error
    end
  end

  def query!(sql, params, caster \\ &std_caster/2) do
    {:ok, query} = query(sql, params, caster)
    query
  end

  @doc """
  Hector default caster. It simply, naively and blindly ensures the given
  value is a string. This does not protect you against potential attacks. Read
  the disclaimer on the moduledoc. Make sure you know what you are doing.
  """
  def std_caster(_type, value),
    do: to_string(value)

  defp atomize_columns(columns),
    do: Enum.map(columns, &(String.to_atom(&1)))

  # Maps the returned rows into the columns. See moduledoc.
  defp simple_mapper(result = %Postgrex.Result{}) do
    columns = atomize_columns(result.columns)

    Enum.map(result.rows, fn row ->
      columns
      |> Enum.zip(row)
      |> Enum.into(%{})
    end)
  end

  # Loads the returned rows into the given module, using Repo.load/2
  defp simple_loader(repo, module, result = %Postgrex.Result{}) do
    columns = atomize_columns(result.columns)

    Enum.map(result.rows, fn row ->
      if :erlang.function_exported(module, :hector_loader, 2) do
        apply(module, :hector_loader, [repo, {columns, row}])
      else
        apply(repo, :load, [module, {columns, row}])
      end
    end)
  end

  defp get_param(params, index),
    do: Enum.at(params, index - 1)

  defp sql_concat(value),
    do: "'" <> value <> "'"

  defp get_query_data(chunk) do
    chunk = String.to_charlist(chunk)
    {index, rest} = List.pop_at(chunk, 0)

    index = List.to_integer([index])

    if length(rest) > 0 do

      next_type = Enum.find_index(rest, &(&1 == List.first(':')))

      if next_type == 0 do
        '::' ++ type_rest = rest

        {type, rest} = get_type(type_rest)

        {index, List.to_atom(type), rest}
      else
        {index, :notype, rest}
      end

    else
      {index, :notype, :norest}
    end
  end

  defp get_type(type) do
    next_parens = Enum.find_index(type, &(&1 == List.first(')')))
    next_space = Enum.find_index(type, &(&1 == List.first(' ')))

    next_split =
      if is_integer(next_parens) and is_integer(next_space) do
        Enum.min([next_parens] ++ [next_space])
      else
        cond do
          next_parens ->
            next_parens
          next_space ->
            next_space
          true ->
            :norest
        end
      end

    case next_split do
      :norest ->
        {type, :norest}
      split_index ->
        Enum.split(type, split_index)
    end
  end
end
