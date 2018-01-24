defmodule Helix.Network.Websocket.Requests.Bounce.Utils do

  alias HELL.IPv4
  alias Helix.Core.Validator
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Network

  @type link ::
    %{network_id: Network.id, ip: Network.ip, password: Server.password}

  @spec cast_links([term]) ::
    {:ok, [link]}
    | :bad_link
  def cast_links(links),
    do: Enum.reduce(links, {:ok, []}, &link_reducer/2)

  @spec merge_links(link, [Server.id]) ::
    [Bounce.link]
  @doc """
  Maps `links` to the internal format used by Helix ([Bounce.link])

  It ditches the password (no longer used) and merges the Server.id, returning
  a tuple (as opposed to the initial map).
  """
  def merge_links(links, servers) do
    links
    |> Enum.zip(servers)
    |> Enum.map(fn {link, server} ->
      {server.server_id, link.network_id, link.ip}
    end)
  end

  defp link_reducer(
    %{"network_id" => u_network_id, "ip" => u_ip, "password" => u_pwd},
    {status, acc})
  do
    with \
      {:ok, network_id} <- Network.ID.cast(u_network_id),
      {:ok, ip} <- IPv4.cast(u_ip),
      {:ok, password} <- Validator.validate_input(u_pwd, :password)
    do
      {status, acc ++ [%{network_id: network_id, ip: ip, password: password}]}
    else
      _ ->
        :bad_link
    end
  end

  defp link_reducer(_, _),
    do: :bad_link
end
