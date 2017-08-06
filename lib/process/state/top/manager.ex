defmodule Helix.Process.State.TOP.Manager do
  @moduledoc false

  alias Helix.Server.Model.Server
  alias Helix.Process.State.TOP.Supervisor, as: TOPSupervisor

  # TODO: Replace this with a distributed alternative. Maybe using PubSub

  @doc false
  def start_link do
    Registry.start_link(:unique, __MODULE__)
  end

  @spec prepare_top(Server.id) ::
    Supervisor.on_start_child
  @doc """
  Fetches or starts a TOP process for `gateway`
  """
  def prepare_top(gateway) do
    pid = get(gateway)

    if pid do
      {:ok, pid}
    else
      TOPSupervisor.start_top(gateway)
    end
  end

  @spec get(Server.id) ::
    pid
    | nil
  @doc """
  Fetches the pid of the process running the TOP for the specified `gateway`
  """
  def get(gateway) do
    case Registry.lookup(__MODULE__, gateway) do
      [{pid, _}] ->
        pid
      [] ->
        nil
    end
  end

  @doc false
  def register(gateway),
    do: Registry.register(__MODULE__, gateway, [])
end
