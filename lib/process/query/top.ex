defmodule Helix.Process.Query.TOP do

  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Process.Model.Process

  @spec load_top_resources(Server.idt) ::
    Process.Resources.t
  @doc """
  Returns the total TOP resources that the server supports.

  Note that the TOP resources are not a 1-to-1 mapping of the Server resources.

  Differences:
  - Resulting processing power of TOP is CPU.clock + RAM.clock
  """
  def load_top_resources(server = %Server{}) do
    resources =
      server.motherboard_id
      |> MotherboardQuery.fetch()
      |> MotherboardQuery.get_resources()

    # Convert server resource format into TOP resource format
    {server_dlk, server_ulk} =
      Enum.reduce(
        resources.net,
        {%{}, %{}},
        fn {network, %{dlk: dlk, ulk: ulk}}, {acc_dlk, acc_ulk} ->

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
      cpu: resources.cpu.clock + resources.ram.clock,
      ram: resources.ram.size,
      dlk: server_dlk,
      ulk: server_ulk
    }
  end

  def load_top_resources(server_id = %Server.ID{}) do
    server_id
    |> ServerQuery.fetch()
    |> load_top_resources()
  end
end
