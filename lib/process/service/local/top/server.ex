defmodule Helix.Process.Service.Local.TOP.Server do
  @moduledoc false

  # This is the default adapter for the TOP. It will proxy requests from API and
  # persist data

  use GenServer

  alias Helix.Process.Controller.TableOfProcesses.ServerResources
  alias Helix.Process.Model.Process
  alias Helix.Process.Service.Local.TOP.Domain
  alias Helix.Process.Repo

  require Logger

  @type server_id :: HELL.PK.t
  @type process_id :: HELL.PK.t

  @enforce_keys [:gateway, :domain]
  defstruct [:gateway, :domain]

  @spec start_link(server_id) ::
    GenServer.on_start
  def start_link(gateway) do
    GenServer.start_link(__MODULE__, [gateway])
  end

  @spec priority(pid, process_id, 0..5) ::
    :ok
  def priority(pid, process, priority) when priority in 0..5 do
    GenServer.cast(pid, {:priority, process, priority})
  end

  @spec pause(pid, process_id) ::
    :ok
  def pause(pid, process) do
    GenServer.cast(pid, {:pause, process})
  end

  @spec resume(pid, process_id) ::
    :ok
  def resume(pid, process) do
    GenServer.cast(pid, {:resume, process})
  end

  @spec kill(pid, process_id) ::
    :ok
  def kill(pid, process) do
    GenServer.cast(pid, {:kill, process})
  end

  @doc false
  def init([gateway]) do
    with \
      {:ok, resources} <- get_resources(gateway),
      {:ok, processes} <- get_processes(gateway)
    do
      domain = Domain.start_link(gateway, processes, resources)

      state = %__MODULE__{
        gateway: gateway,
        domain: domain
      }

      {:ok, state}
    else
      reason ->
        {:stop, reason}
    end
  end

  @spec get_resources(server_id) ::
    {:ok, ServerResources.t}
    | {:error, atom}
  defp get_resources(gateway) do
    # FIXME
    alias Helix.Hardware.Controller.Component
    alias Helix.Hardware.Controller.Motherboard
    alias Helix.Server.Controller.Server

    with \
      %{motherboard_id: motherboard} <- Server.fetch(gateway),
      true <- not is_nil(motherboard) || :server_not_assembled,
      component = %{} <- Component.fetch(motherboard),
      motherboard = %{} <- Motherboard.fetch!(component),
      resources = %{} <- Motherboard.resources(motherboard)
    do
      resources = ServerResources.cast(resources)
      {:ok, resources}
    else
      reason when is_atom(reason) ->
        {:error, reason}
      _ ->
        {:error, :internal}
    end
  end

  @spec get_processes(server_id) ::
    {:ok, [Process.t]}
  defp get_processes(gateway) do
    processes =
      Process
      |> Process.Query.from_server(gateway)
      |> Repo.all()

    {:ok, processes}
  end
end
