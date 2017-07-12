defmodule Helix.Network.Internal.Web.NPC do

  alias Helix.Network.Model.Web.NPC, as: WebNPC
  alias Helix.Network.Repo
  alias Helix.Universe.NPC.Model.NPC

  @spec get_content(HELL.IPv4, NPC.t) :: map()
  def get_content(ip, npc) do
    case get_cache(ip) do
      {:hit, content} ->
        content
      :miss ->
        content = derive_content(npc)
        set_cache(npc.npc_id, ip, content)
        content
    end
  end

  @spec get_cache(HELL.IPv4) ::
    {:hit, map()}
    | :miss
  defp get_cache(ip) do
    cache = ip
      |> WebNPC.Query.by_ip()
      |> Repo.one

    case cache do
      nil ->
        :miss
      web_npc ->
        {:hit, web_npc.content}
    end
  end

  @spec set_cache(HELL.PK, HELL.IPv4, map()) ::
    {:ok, WebNPC.t}
    | {:error, Ecto.Changeset.t}
  defp set_cache(npc_id, npc_ip, content) do
    %{ip: npc_ip, npc_id: npc_id, content: content}
    |> WebNPC.create_changeset()
    |> Repo.insert
  end

  @spec derive_content(NPC.t) :: map()
  defp derive_content(npc) do
    case npc.npc_type do
      :download_center ->
        %{a: "b"}
      _ ->
        %{}
    end
  end

end
