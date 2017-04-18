defmodule Helix.Process.Service.Local.TOP.Server do
  @moduledoc false

  # This is the default adapter for the TOP. It will proxy requests from API and
  # persist data

  use GenServer

  alias Helix.Event
  alias Helix.Process.Controller.TableOfProcesses.ServerResources
  alias Helix.Process.Model.Process
  alias Helix.Process.Service.Local.TOP.Domain
  alias Helix.Process.Repo

  require Logger

  @type server_id :: HELL.PK.t
  @type process_id :: HELL.PK.t
  @type process :: Process.t

  @enforce_keys [:gateway, :domain]
  defstruct [:gateway, :domain]

  @spec start_link(server_id) ::
    GenServer.on_start
  def start_link(gateway) do
    GenServer.start_link(__MODULE__, [gateway])
  end

  @spec priority(pid, process, 0..5) ::
    :ok
  def priority(pid, process, priority) when priority in 0..5 do
    GenServer.cast(pid, {:priority, process, priority})
  end

  @spec pause(pid, process) ::
    :ok
  def pause(pid, process) do
    GenServer.cast(pid, {:pause, process})
  end

  @spec resume(pid, process) ::
    :ok
  def resume(pid, process) do
    GenServer.cast(pid, {:resume, process})
  end

  @spec kill(pid, process) ::
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

  @doc false
  def handle_cast({:priority, process, priority}, state) do
    if belongs_to_the_server?(process, state) do
      Domain.priority(state.domain, process.process_id, priority)
    end

    {:noreply, state}
  end

  def handle_cast({:pause, process}, state) do
    if belongs_to_the_server?(process, state) do
      Domain.pause(state.domain, process.process_id)
    end

    {:noreply, state}
  end

  def handle_cast({:resume, process}, state) do
    if belongs_to_the_server?(process, state) do
      Domain.resume(state.domain, process.process_id)
    end

    {:noreply, state}
  end

  def handle_cast({:kill, process}, state) do
    if belongs_to_the_server?(process, state) do
      Domain.kill(state.domain, process.process_id)
    end

    {:noreply, state}
  end

  @doc false
  def handle_info({:top, :instructions, instructions}, state) do
    # If the brick hits the fan, it's better to just crash and try again
    {:ok, _} = Repo.transaction fn ->
      Enum.each(instructions, &execute_repo_instruction/1)
    end

    Enum.each(instructions, &execute_post_instruction/1)

    {:noreply, state}
  end

  defp execute_repo_instruction({:delete, record}),
    do: Repo.delete!(record)
  defp execute_repo_instruction({:update, record}),
    do: Repo.update!(record)
  defp execute_repo_instruction({:create, record}),
    do: Repo.insert!(record)
  defp execute_repo_instruction(_),
    do: :ok

  defp execute_post_instruction({:event, event}),
    do: Event.emit(event)
  defp execute_post_instruction(_),
    do: :ok

  defp belongs_to_the_server?(%Process{gateway_id: g}, %{gateway: g}),
    do: true
  defp belongs_to_the_server?(%Process{}, %{}),
    do: false

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
