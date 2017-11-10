defmodule Helix.Websocket.Request.Relay do
  @moduledoc """
  `RequestRelay` is a struct intended to be relayed all the way from the Request
  to the Public to the ActionFlow, so it can be used by `Helix.Event` to
  identify the `request_id` and create a meaningful stacktrace.
  """

  defstruct [:request_id]

  @type t :: t_of_type(binary)

  @type t_of_type(type) ::
  %__MODULE__{
    request_id: type
  }

  @spec new(map) ::
  t
  | t_of_type(nil)
  def new(%{"request_id" => request_id}) when is_binary(request_id) do
    %__MODULE__{
      request_id: request_id
    }
  end
  def new(_),
    do: %__MODULE__{}
end
