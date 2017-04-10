defmodule Helix.Hardware.Websocket.Routes do

  alias HELF.Router

  @routes %{
  }

  def register_routes do
    Enum.each(@routes, fn {topic, params} ->
      Router.register(topic, params.broker, params.atoms)
    end)
  end
end
