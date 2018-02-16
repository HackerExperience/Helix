defmodule Helix.Test.Channel.Request.Helper do

  alias HELL.TestHelper.Random
  alias Helix.Test.Channel.Setup, as: ChannelSetup

  @mock_socket ChannelSetup.mock_account_socket()

  def mock_request(module, params, meta \\  %{}) do
    %{
      __struct__: module,
      params: params,
      meta: meta,
      relay: Helix.Websocket.Request.Relay.new(params, @mock_socket)
    }
  end

  @doc """
  Generates a random request ID
  """
  def id,
    do: Random.string(max: 256)
end
