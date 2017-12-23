defmodule Helix.Test.Event.Setup.Server do

  alias Helix.Server.Model.Server

  alias Helix.Server.Event.Motherboard.Updated, as: MotherboardUpdatedEvent

  alias Helix.Test.Server.Setup, as: ServerSetup

  def motherboard_updated(server = %Server{}),
    do: MotherboardUpdatedEvent.new(server)
  def motherboard_updated do
    {server, _} = ServerSetup.server()
    motherboard_updated(server)
  end
end
