defmodule Helix.Client.Web1.Model.Setup do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Entity.Model.Entity

  @type t ::
    %__MODULE__{
      entity_id: Entity.id,
      pages: [page]
    }

  @type creation_params ::
    %{
      entity_id: Entity.id,
      pages: [page]
    }

  @type page ::
    :welcome
    | :server

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @pages [:welcome, :server]

  @creation_fields [:entity_id, :pages]
  @required_fields [:entity_id, :pages]

  @primary_key false
  schema "web1_setup" do
    field :entity_id, Entity.ID,
      primary_key: true

    field :pages, {:array, Constant},
      default: []
  end

  @spec create_changeset(creation_params) ::
    changeset
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
    |> validate_pages()
  end

  @spec add_pages(t, [page]) ::
    changeset
  def add_pages(setup = %__MODULE__{}, pages) do
    new_pages =
      setup.pages
      |> Kernel.++(pages)
      |> Enum.uniq()

    setup
    |> change()
    |> put_change(:pages, new_pages)
    |> validate_pages()
    # if Enum.all?(new_pages, &(&1 in @pages)) do
  end

  @spec validate_pages(changeset) ::
    changeset
  defp validate_pages(changeset) do
    valid? =
      changeset
      |> get_field(:pages)
      |> Enum.reduce(true, fn page, acc ->
        page in @pages && acc
      end)

    if valid? do
      changeset
    else
      add_error(changeset, :pages, "invalid page")
    end
  end

  @spec valid_pages ::
    [page]
  @doc """
  Returns a list of all valid pages. Useful for verification and stuff.
  """
  def valid_pages,
    do: @pages

  defmodule Query do

    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Client.Web1.Model.Setup

    @spec by_entity(Queryable.t, Entity.id) ::
      Queryable.t
    def by_entity(query \\ Setup, entity_id),
      do: where(query, [s], s.entity_id == ^entity_id)
  end

  defmodule Select do

    import Ecto.Query

    alias Ecto.Queryable

    @spec pages(Queryable.t) ::
      Queryable.t
    def pages(query),
      do: select(query, [s], [s.pages])
  end
end
