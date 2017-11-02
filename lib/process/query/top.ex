defmodule Helix.Process.Query.TOP do

  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

  def load_top_resources(server_id = %Server.ID{}) do
    server_id
    |> ServerQuery.fetch()
    |> load_top_resources()
  end

  def load_top_resources(server = %Server{}) do
    resources =
      server.motherboard_id
      |> MotherboardQuery.fetch()
      |> MotherboardQuery.resources()

    {server_dlk, server_ulk} =
      Enum.reduce(
        resources.net,
        {%{}, %{}},
        fn {network, %{downlink: dlk, uplink: ulk}}, {acc_dlk, acc_ulk} ->

          acc_dlk =
            %{}
            |> Map.put(network, dlk)
            |> Map.merge(acc_dlk)

          acc_ulk =
            %{}
            |> Map.put(network, ulk)
            |> Map.merge(acc_ulk)

          {acc_dlk, acc_ulk}
        end)

    %{
      cpu: resources.cpu,
      ram: resources.ram,
      dlk: server_dlk,
      ulk: server_ulk
    }
  end
end
