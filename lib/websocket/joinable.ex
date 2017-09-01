defprotocol Helix.Websocket.Joinable do
  @moduledoc """
  The Joinable protocol is similar to `Requestable`, in the sense that both
  implement a data flow for handling external (incoming) requests from the
  client side. However, as the name suggests, `Joinable` is focused on handling
  Join requests.

  The Join flow is defined as:

  1 - Check parameters of the request (`check_params/2`)
  2 - Check permissions of the request (`check_permissions/2`)
  3 - Join/subscribe to the channel, assigning required data (`join/3`)

  # Return conventions

  Both `check_params/2` and `check_permissions/2` should return, in case of
  success, {:ok, JoinRequest.t}. All other returns are handled as errors.

  `join/3` must return what Phoenix's join/3 is expected to return, i.e.:

  - {:ok, Socket.t}
  - {:ok, reply :: map, Socket.t}
  - {:error, reply :: map}

  Note that when `join/3` is called, we can safely assumed that that request is
  valid, since its permissions and params were already validated.
  """

  @doc """
  Method meant to validate the given params in a request. The original params
  are stored on the `unsafe` entry of the Request.t struct.

  May fill the entry `meta` on Request.t in order to relay useful information
  for the next flow steps.

  # Return

  On return, it must fill the `param` entry of the request, which shall be used
  later on the Requestable flow.
  """
  def check_params(request, socket)

  def check_permissions(request, socket)

  def join(request, socket, assign)

end
