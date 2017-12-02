# credo:disable-for-this-file
defmodule HELL.DevTools do

  defmodule Atoms do
    @moduledoc """
    Lists all atoms defined on the VM at a given time.

    Use `search_exact` for exact search, and `search_similar` in order to
    query subsets of atoms. Parameters for `search_*` must be a binary (string)
    to make sure the queried atom is not registered during the request.

    `IO.inspect` hard-coded in order to ensure the output list is not truncated.

    Based on this answer: https://stackoverflow.com/a/34883331/1454986
    """

    def display_all do
      all_atoms()
      |> IO.inspect(limit: :infinity)
    end

    @doc """
    Must be a binary otherwise the queried atom is registered before
    `all_atoms/1` is called, making the search useless.
    """
    def search_exact(query) when is_binary(query) do
      all_atoms()
      |> Enum.find(fn atom -> to_string(atom) == query end)
    end

    @doc """
    Must be a binary otherwise the queried atom is registered before
    `all_atoms/1` is called, making the search useless.
    """
    def search_similar(query) when is_binary(query) do
      all_atoms()
      |> Enum.filter(fn atom -> to_string(atom) =~ query end)
      |> IO.inspect(limit: :infinity)
    end

    defp atom_by_number(n),
      do: :erlang.binary_to_term(<<131, 75, n :: size(24)>>)

    defp all_atoms,
      do: atoms_starting_at(0)

    defp atoms_starting_at(n) do
      try do
        [atom_by_number(n)] ++ atoms_starting_at(n + 1)
      rescue
        _ ->
          []
      end
    end
  end

  defmodule ETS do
    @moduledoc """
    ETS-related helper functions.
    """

    def dump_table(table) do
      table
      |> :ets.match_object(:'$1')
      |> IO.inspect()
    end
  end
end
