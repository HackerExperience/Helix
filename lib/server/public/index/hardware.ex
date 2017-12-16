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

  @typep access_type :: :local | :remote

  @spec index(Server.t, access_type) ::
    index
  def index(server = %Server{}, :local) do
    %{
      motherboard: MotherboardIndex.index(server)
    }
  end

  def index(%Server{}, :remote) do
    %{
      motherboard: nil
    }
  end

  @spec render_index(index) ::
    rendered_index
  def render_index(%{motherboard: nil}) do
    %{
      motherboard: nil
    }
  end

  def render_index(index) do
    %{
      motherboard: MotherboardIndex.render_index(index.motherboard)
    }
  end
end
