defmodule Helix.Server.Henforcer.Server do

  import Helix.Henforcer

  alias Helix.Hardware.Query.Component, as: ComponentQuery
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Software.Model.File
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

  def has_enough_space?(_server_id = %Server.ID{}, _file = %File{}) do
    # TODO #279
    {:ok, %{}}
  end

  @type server_exists_relay :: %{server: Server.t}
  @type server_exists_relay_partial :: %{}
  @type server_exists_error ::
    {false, {:server, :not_found}, server_exists_relay_partial}

  @spec server_exists?(Server.idt) ::
    {true, server_exists_relay}
    | server_exists_error
  @doc """
  Ensures the requested server exists on the database.
  """
  def server_exists?(server = %Server{}),
    do: server_exists?(server.server_id)
  def server_exists?(server_id = %Server.ID{}) do
    with server = %Server{} <- ServerQuery.fetch(server_id) do
      {true, relay(%{server: server})}
    else
      _ ->
        reply_error({:server, :not_found})
    end
  end

  @spec server_assembled?(Server.id) ::
    boolean
  def server_assembled?(server) do
    with \
      server = %Server{} <- ServerQuery.fetch(server)
    do
      not is_nil(server.motherboard_id)
    else
      _ ->
        false
    end
  end

  @spec functioning?(Server.id) ::
    boolean
  @doc """
  Checks if a server has what is needed to provide minimum functionality

  This will check that:
  - The server has a motherboard assembled
  - The motherboard has a HDD assembled
  - The motherboard has a CPU assembled
  - The motherboard has a RAM assembled
  """
  def functioning?(server) do
    # TODO: Move below to cache
    with \
      server = %Server{} <- ServerQuery.fetch(server),
      motherboard when not is_nil(motherboard) <- server.motherboard_id,
      motherboard = %{} <- ComponentQuery.fetch(motherboard),
      motherboard = %{} <- MotherboardQuery.fetch(motherboard),
      slots = [_|_] <- MotherboardQuery.get_slots(motherboard),
      hdds = [_|_] <- Enum.filter(slots, &(&1.link_component_type == :hdd)),
      true <- Enum.any?(hdds, &(not is_nil(&1.link_component_id))),
      rams = [_|_] <- Enum.filter(slots, &(&1.link_component_type == :ram)),
      true <- Enum.any?(rams, &(not is_nil(&1.link_component_id))),
      cpus = [_|_] <- Enum.filter(slots, &(&1.link_component_type == :cpu)),
      true <- Enum.any?(cpus, &(not is_nil(&1.link_component_id)))
    do
      true
    else
      _ ->
        false
    end
  end
end
