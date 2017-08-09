defmodule Helix.Universe.NPC.Internal.Web do

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Universe.NPC.Model.NPC

  @type npc_content :: %{
    :title => String.t,
    optional(:custom) => map
  }

  @spec generate_content(NPC.t, Network.id, IPv4.t) ::
    npc_content
    | nil
  def generate_content(_npc = %NPC{npc_type: :download_center}, _net, _ip) do
    common = common("Download Center")
    custom = %{}

    Map.merge(common, custom)
  end
  def generate_content(_, _, _) do
    nil
  end

  defp common(title) do
    %{
      title: title
    }
  end
end
