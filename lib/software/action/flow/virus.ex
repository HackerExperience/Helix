defmodule Helix.Software.Action.Flow.Virus do

  alias Helix.Event
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Virus

  alias Helix.Software.Process.Virus.Collect, as: VirusCollectProcess

  @internet_id NetworkQuery.internet().network_id

  @type viruses :: [{File.t, Server.t}]

  @spec start_collect(
    Server.t, viruses, Tunnel.bounce_id, Virus.payment_info, Event.relay)
  ::
    [Process.t]
    | no_return
  @doc """
  Starts the process of collecting money off of active viruses.

  For each virus, a new process and connection will be created, and once each
  one gets completed, the collect will be performed.

  Emits: ProcessCreatedEvent
  """
  def start_collect(gateway, viruses, bounce_id, {bank_acc, wallet}, relay) do
    Enum.reduce(viruses, [], fn {virus, target}, acc ->

      params =
        %{
          wallet: wallet,
          bank_account: bank_acc
        }

      meta =
        %{
          virus: virus,
          network_id: @internet_id,
          bounce: bounce_id
        }

      {:ok, process} =
        VirusCollectProcess.execute(gateway, target, params, meta, relay)

      acc ++ [process]
    end)
  end
end
