defmodule HELL.ID do

  defmacro __using__(params) do
    model = __CALLER__.module
    field = Keyword.fetch!(params, :field)
    id_root = Keyword.get(params, :root, model)

    quote do

      @type id :: __MODULE__.ID.t
      @type idt :: id | %__MODULE__{unquote(field) => id}
      @type idtb :: idt | String.t

      @primary_key false

      defmodule ID do
        @behaviour Ecto.Type

        @type t ::
          %__MODULE__{}
          | %{:__struct__ => atom, root: unquote(id_root), id: tuple}

        defstruct [id: nil, root: unquote(id_root)]

        @field unquote(field)

        @doc false
        def type,
          do: :inet

        @doc false
        def cast(id = %__MODULE__{}),
          do: {:ok, id}

        # HACK: use __struct__ to avoid mutual compilation dependency.
        # Extracts id from the input record as long as it is the model that
        # defines this ID
        def cast(%{
          :__struct__ => unquote(model),
          unquote(field) => id = %__MODULE__{}})
        do
          {:ok, id}
        end

        def cast(%Postgrex.INET{address: id}),
          do: {:ok, %__MODULE__{id: id}}

        def cast(%_{root: unquote(id_root), id: id}) when tuple_size(id) == 8,
          do: {:ok, %__MODULE__{id: id}}

        def cast(id = {_, _, _, _, _, _, _, _}),
          do: {:ok, %__MODULE__{id: id}}

        def cast(string) when is_binary(string) do
          case HELL.IPv6.binary_to_address_tuple(string) do
            {:ok, id} ->
              {:ok, %__MODULE__{id: id}}
            {:error, _} ->
              :error
          end
        end

        def cast(_),
          do: :error

        @doc false
        def cast!(term) do
          {:ok, id} = cast(term)
          id
        end

        @doc false
        def load(%Postgrex.INET{address: id}),
          do: {:ok, %__MODULE__{id: id}}
        def load(_),
          do: :error

        @doc false
        def dump(%__MODULE__{id: id}),
          do: {:ok, %Postgrex.INET{address: id}}
        def dump(_),
          do: :error

        @doc false
        def generate(domain) when is_tuple(domain) or is_atom(domain),
          do: generate(%{}, domain)
        def generate(heritage, domain),
          do: %__MODULE__{id: Helix.ID.generate(heritage, domain)}

        @doc false
        def get_field,
          do: @field

        defimpl String.Chars do
          defdelegate to_string(struct),
            to: HELL.ID
        end

        defimpl Poison.Encoder do
          def encode(struct, _),
            do: "\"" <> HELL.ID.to_string(struct) <> "\""
        end

      end
    end
  end

  @doc false
  def to_string(%_{id: id, root: _}) when tuple_size(id) == 8 do
    id
    |> :inet.ntoa()
    |> List.to_string()
  end
end
