defmodule Helix.Test.Event.Setup.Server do

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server

  alias Helix.Server.Event.Motherboard.Updated, as: MotherboardUpdatedEvent
  alias Helix.Server.Event.Server.Joined, as: ServerJoinedEvent
  alias Helix.Server.Event.Server.Password.Acquired,
    as: ServerPasswordAcquiredEvent

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  @internet_id NetworkHelper.internet_id()

  def joined(server = %Server{}, entity = %Entity{}, type),
    do: ServerJoinedEvent.new(server, entity, type)
  def joined(:local) do
    {server, %{entity: entity}} = ServerSetup.server()
    joined(server, entity, :local)
  end
  def joined(:remote) do
    {entity, _} = EntitySetup.entity()
    {server, _} = ServerSetup.server()
    joined(server, entity, :remote)
  end

  def password_acquired(entity_id = %Entity.ID{}, server = %Server{}) do
    ServerPasswordAcquiredEvent.new(
      entity_id,
      server.server_id,
      @internet_id,
      ServerHelper.get_ip(server),
      server.password
    )
  end

  def motherboard_updated(server = %Server{}),
    do: MotherboardUpdatedEvent.new(server)
  def motherboard_updated do
    {server, _} = ServerSetup.server()
    motherboard_updated(server)
  end
end
