defmodule Helix.Server.Public.Index.Hardware do

  alias Helix.Server.Model.Server
  alias Helix.Server.Public.Index.Motherboard, as: MotherboardIndex

  @type index ::
    %{
      motherboard: MotherboardIndex.index | nil
    }

  @type rendered_index ::
    %{
      motherboard: MotherboardIndex.rendered_index | nil
    }

  @spec index(Server.t) ::
    index
  def index(server = %Server{}) do
    %{
      motherboard: MotherboardIndex.index(server)
    }
  end

  @spec render_index(index) ::
    rendered_index
  def render_index(index) do
    %{
      motherboard: MotherboardIndex.render_index(index.motherboard)
    }
  end
end
