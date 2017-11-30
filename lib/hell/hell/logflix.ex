import Helix.Websocket.Channel

channel HELL.Logflix do
  @moduledoc """
  Watch live streaming of logs... for free!!11!
  """

  @doc false
  def join(_, _, socket),
    do: {:ok, socket}
end
