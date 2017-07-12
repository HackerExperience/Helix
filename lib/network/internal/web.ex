defmodule Helix.Network.Internal.Web do

  alias Helix.Network.Internal.Web.Player, as: WebPlayerInternal
  alias Helix.Network.Internal.Web.NPC, as: WebNPCInternal
  alias Helix.Network.Repo

  def get_content({:npc, server_ip, npc}) do
    WebNPCInternal.get_content(server_ip, npc)
  end

  def get_content({:vpc, server_ip}) do
  end

  def set_content({:vpc, server_ip}) do
  end
end
