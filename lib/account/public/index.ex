defmodule Helix.Account.Public.Index do

  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Model.Server

  @type index ::
    %{
      mainframe: Server.id
    }

  @type rendered_index ::
    %{
      mainframe: String.t
    }

  @spec index(Entity.id) ::
    index
  def index(entity_id) do
      mainframe =
        entity_id
        |> EntityQuery.fetch()
        |> EntityQuery.get_servers()
        |> List.first()

      %{
        mainframe: mainframe
      }
  end

  @spec render_index(index) ::
    rendered_index
  def render_index(index) do
      %{
        mainframe: to_string(index.mainframe)
      }
  end
end
