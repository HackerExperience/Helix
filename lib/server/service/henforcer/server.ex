defmodule Helix.Server.Service.Henforcer.Server do

  alias Helix.Server.Model.Server
  alias Helix.Server.Controller.Server, as: Controller

  @spec server_exists?(HELL.PK.t) ::
    boolean
  def server_exists?(server) do
    # TODO: Use a count(server_id) to waste less resources
    !!Controller.fetch(server)
  end

  @spec server_assembled?(HELL.PK.t) ::
    boolean
  def server_assembled?(server) do
    with \
      server = %Server{} <- Controller.fetch(server)
    do
      not is_nil(server.motherboard_id)
    else
      _ ->
        false
    end
  end
end
