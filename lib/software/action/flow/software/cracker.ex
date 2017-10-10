defmodule Helix.Software.Action.Flow.Software.Cracker do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Model.Connection
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Software.Cracker.Bruteforce, as: CrackerBruteforce

  @type params :: CrackerBruteforce.create_params

  @type meta :: %{
    bounces: [Server.id]
  }

  @type on_execute_error ::
    ProcessAction.on_create_error
    | {:error, CrackerBruteforce.changeset}

  @spec execute(File.t_of_type(:cracker), Server.id, params, meta) ::
    {:ok, Process.t}
    | on_execute_error
  @doc """
  Executes the cracker for the Bruteforce module
  """
  def execute(file, server_id, params, meta) do
    flowing do
      with \
        {:ok, data, firewall} <- prepare(file, params),
        {:ok, connection, events} <-
           start_connection(params, server_id, meta.bounces),
        on_success(fn -> Event.emit(events) end),
        on_fail(fn -> TunnelAction.close_connection(connection) end),
        {:ok, process_params} =
           process_params(file, connection, data, server_id, firewall),
        {:ok, process, events} <- ProcessAction.create(process_params),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, process}
      end
    end
  end

  defp start_connection(cracker, server_id, bounces) do
    TunnelAction.connect(
      NetworkQuery.fetch(cracker.network_id),
      server_id,
      cracker.target_server_id,
      bounces,
      :cracker_bruteforce
    )
  end

  @spec prepare(File.t_of_type(:cracker), params) ::
    {:ok, CrackerBruteforce.t, non_neg_integer}
    | {:error, CrackerBruteforce.changeset}
  defp prepare(file, params) do
    target_firewall = fn server_id ->
      ProcessQuery.get_running_processes_of_type_on_server(
        server_id,
        "firewall_passive")
    end

    create_changeset = fn ->
      file
      |> CrackerBruteforce.create(params)
    end

    with {:ok, cracker} <- create_changeset.() do
      case target_firewall.(cracker.target_server_id) do
        [] ->
          {:ok, cracker, 0}
        [%{process_data: %{version: v}}] ->
          {:ok, cracker, v}
      end
    end
  end

  @spec process_params(
    File.t_of_type(:cracker),
    Connection.t,
    CrackerBruteforce.t,
    Server.id,
    firewall :: non_neg_integer)
  ::
    {:ok, ProcessAction.base_params}
  defp process_params(file, connection, cracker, server_id, firewall) do
    params = %{
      gateway_id: server_id,
      target_server_id: cracker.target_server_id,
      network_id: cracker.network_id,
      objective: CrackerBruteforce.objective(cracker, firewall),
      process_data: cracker,
      process_type: "cracker_bruteforce",
      file_id: file.file_id,
      connection_id: connection.connection_id
    }

    {:ok, params}
  end
end
