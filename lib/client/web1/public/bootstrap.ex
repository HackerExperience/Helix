defmodule Helix.Client.Web1.Public.Bootstrap do

  alias Helix.Entity.Model.Entity
  alias Helix.Client.Web1.Model.Setup
  alias Helix.Client.Web1.Query.Setup, as: SetupQuery

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
        pages: SetupQuery.get_pages(entity_id)
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
end
