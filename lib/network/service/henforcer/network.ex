defmodule Helix.Network.Service.Henforcer.Network do

  alias Helix.Hardware.Controller.Component
  alias Helix.Hardware.Controller.Motherboard
  alias Helix.Server.Controller.Server

  @spec node_connected?(HELL.PK.t, HELL.PK.t) ::
    boolean
  def node_connected?(server, network) do
    # FIXME: This looks awful
    # FIXME: Test (needs network factory and some patience)
    with \
      %{motherboard_id: motherboard} <- Server.fetch(server),
      component = %{} <- Component.fetch(motherboard),
      motherboard = %{} <- Motherboard.fetch!(component),
      %{^network => _} <- Motherboard.resources(motherboard)
    do
      true
    else
      _ ->
        false
    end
  end
end
