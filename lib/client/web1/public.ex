defmodule Helix.Client.Web1.Public do

  alias Helix.Entity.Model.Entity
  alias Helix.Client.Web1.Action, as: Web1Action
  alias Helix.Client.Web1.Model.Setup
  alias Helix.Client.Web1.Query, as: Web1Query

  @type bootstrap ::
    %{
      setup: %{
        pages: [Setup.page]
      }
    }

  @type rendered_bootstrap ::
    %{
      setup: %{
        pages: [String.t]
      }
    }

  @spec bootstrap(Entity.id) ::
    bootstrap
  def bootstrap(entity_id) do
    %{
      setup: %{
        pages: Web1Query.get_setup_pages(entity_id)
      }
    }
  end

  @spec render_bootstrap(bootstrap) ::
    rendered_bootstrap
  def render_bootstrap(bootstrap) do
    %{
      setup: %{
        pages: Enum.map(bootstrap.setup.pages, &to_string/1)
      }
    }
  end

  defdelegate add_setup_pages(entity_id, pages),
    to: Web1Action
end
