defmodule Helix.Client.Web1.Model.Setup do

  use Ecto.Schema

  alias Helix.Entity.Model.Entity

  @primary_key false
  schema "web1_setup" do
    field :entity_id, Entity.ID,
      primary_key: true

    field :pages, {:array, :string},
      default: []
  end

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
