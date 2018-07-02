defmodule HELL.Ecto.Macros do

  @doc """
  Syntactic-sugar for our way-too-common Query module
  """
  defmacro query(do: block) do
    quote do

      defmodule Query do
        @moduledoc false

        import Ecto.Query

        alias Ecto.Queryable
        alias unquote(__CALLER__.module)

        unquote(block)
      end

    end
  end

  @doc """
  Syntactic-sugar for the less-common Order module
  """
  defmacro order(do: block) do
    quote do

      defmodule Order do
        @moduledoc false

        import Ecto.Query

        alias Ecto.Queryable
        alias unquote(__CALLER__.module)

        unquote(block)
      end

    end
  end

  @doc """
  Generates and then inserts the Helix.ID into the changeset.

  A custom ID module may be specified at `opts`, otherwise __CALLER__.ID shall
  be used.
  """
  defmacro put_pk(changeset, heritage, domain, opts \\ unquote([])) do
    module = get_pk_module(opts, __CALLER__.module)

    gen_pk(changeset, heritage, domain, module)
  end

  defp gen_pk(changeset, heritage, domain, module) do
    quote do

      if unquote(changeset).valid? do
        field = unquote(module).get_field()
        id = unquote(module).generate(unquote(heritage), unquote(domain))

        put_change(unquote(changeset), field, id)
      else
        unquote(changeset)
      end

    end
  end

  defp get_pk_module([id: module], _),
    do: module
  defp get_pk_module([], parent_module),
    do: Module.concat(parent_module, :ID)
end
