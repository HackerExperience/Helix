defmodule HELL.ID do

  defmacro __using__(params) do
    model = __CALLER__.module

    field = Keyword.fetch!(params, :field)
    meta =
      params
      |> Keyword.get(:meta, [])
      |> List.wrap()
      |> pad()

    id_root = Keyword.get(params, :root, model)

    autogenerate = Keyword.get(params, :autogenerate, true)

    quote do
      defmodule ID do
        @behaviour Ecto.Type

        @type t ::
          %__MODULE__{}
          | %{:__struct__ => atom, root: unquote(id_root), id: tuple}

        defstruct [
          id: nil,
          root: unquote(id_root)
        ]

        @doc false
        def type,
          do: :inet

        def cast(id = %__MODULE__{}) do
          {:ok, id}
        end

        # HACK: use __struct__ to avoid mutual compilation dependency.
        # Extracts id from the input record as long as it is the model that
        # defines this ID
        def cast(%{
          :__struct__ => unquote(model),
          unquote(field) => id = %__MODULE__{}})
        do
          {:ok, id}
        end

        def cast(%Postgrex.INET{address: id}) do
          {:ok, %__MODULE__{id: id}}
        end

        def cast(%_{root: unquote(id_root), id: id}) when tuple_size(id) == 8 do
          {:ok, %__MODULE__{id: id}}
        end

        def cast(string) when is_binary(string) do
          case HELL.IPv6.binary_to_address_tuple(string) do
            {:ok, id} ->
              {:ok, %__MODULE__{id: id}}
            {:error, _} ->
              :error
          end
        end

        def cast(_) do
          :error
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

        def generate do
          %__MODULE__{id: HELL.IPv6.generate_address_tuple(unquote(meta))}
        end

        defimpl String.Chars do
          defdelegate to_string(struct),
            to: HELL.ID
        end

        defimpl Poison.Encoder do
          def encode(struct, _),
            do: HELL.ID.to_string(struct)
        end
      end

      # Inject the PK module as the PK autogenerator for the module
      alias __MODULE__.ID

      @type id :: ID.t
      @type idt :: id | %__MODULE__{unquote(field) => id}
      @type idtb :: idt | String.t

      @primary_key false

      if unquote(autogenerate) do
        @ecto_autogenerate {unquote(field), {ID, :generate, []}}
      end
    end
  end

  @doc false
  def pad([]),
    do: [0, 0, 0]
  def pad([x]),
    do: [x, 0, 0]
  def pad([x, y]),
    do: [x, y, 0]
  def pad(list = [_, _, _]),
    do: list

  @doc false
  def to_string(%_{id: id, root: _}) when tuple_size(id) == 8 do
    id
    |> :inet.ntoa()
    |> List.to_string()
  end
end
