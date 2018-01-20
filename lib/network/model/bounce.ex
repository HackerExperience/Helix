defmodule Helix.Network.Model.Bounce do

  use Ecto.Schema
  use HELL.ID, field: :bounce_id, meta: [0x0000, 0x0001, 0x0002]

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Network
  alias __MODULE__

  @type t ::
    %__MODULE__{
      bounce_id: id,
      entity_id: Entity.id,
      name: name,
      links: [link]
    }

  @type name :: String.t
  @type link :: {Server.id, Network.id, Network.ip}

  @type entry :: Bounce.Entry.t
  @type sorted :: Bounce.Sorted.t

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type creation_params ::
    %{
      bounce_id: id,
      entity_id: Entity.id,
      name: name
    }

  @creation_fields [:bounce_id, :entity_id, :name]
  @required_fields [:bounce_id, :entity_id, :name]

  @primary_key false
  schema "bounces" do
    field :bounce_id, ID,
      primary_key: true
    field :entity_id, Entity.ID
    field :name, :string

    has_many :entries, Bounce.Entry,
      foreign_key: :bounce_id,
      references: :bounce_id

    has_one :sorted, Bounce.Sorted,
      foreign_key: :bounce_id,
      references: :bounce_id

    field :links, {:array, :map},
      virtual: true,
      default: nil
  end

  @spec create(Entity.id, name, [link]) ::
    [changeset | Bounce.Entry.changeset]
  def create(entity_id, name, links) do
    id = ID.generate()

    sorted = Bounce.Sorted.create(id, links)
    bounce =
      create_bounce(%{bounce_id: id, entity_id: entity_id, name: name}, sorted)
    entries = Bounce.Entry.create(id, links)

    [bounce] ++ entries
  end

  @spec add_entry(Bounce.idt, link) ::
    Bounce.Entry.changeset
  def add_entry(bounce = %Bounce{}, link),
    do: add_entry(bounce.bounce_id, link)
  def add_entry(bounce_id = %Bounce.ID{}, link = {_, _, _}),
    do: Bounce.Entry.create(bounce_id, link)

  @spec format(t) ::
    t | term
  def format(bounce = %Bounce{}) do
    links = Bounce.Sorted.get_links(bounce.sorted)

    bounce
    |> Map.put(:links, links)

    # See `File.format/1` for context
    |> Ecto.put_meta(state: :loaded)
  end

  @spec create_bounce(creation_params, Bounce.Sorted.changeset) ::
    changeset
  defp create_bounce(params, sorted) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
    |> put_assoc(:sorted, sorted)
  end

  query do

    @spec by_bounce(Queryable.t, Bounce.id) ::
      Queryable.t
    def by_bounce(query \\ Bounce, bounce_id),
      do: where(query, [b], b.bounce_id == ^bounce_id)

    @spec join_sorted(Queryable.t) ::
      Queryable.t
    def join_sorted(query) do
      query
      |> join(:left, [b], bs in assoc(b, :sorted))
      |> preload_sorted()
    end

    @spec preload_sorted(Queryable.t) ::
      Queryable.t
    defp preload_sorted(query),
      do: preload(query, [..., bs], [sorted: bs])
  end
end
