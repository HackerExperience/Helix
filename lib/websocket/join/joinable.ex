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

  alias Phoenix.Socket

  @type request :: struct

  @spec check_params(request, Socket.t) ::
    {:ok, request}
    | {:error, %{message: String.t}}
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

  @spec check_permissions(request, Socket.t) ::
    {:ok, request}
    | {:error, %{message: String.t}}
  @doc """
  Decides whether to accept or deny access to the Channel.

  # Return

  In case of success, return {:ok, JoinRequest.t}, which will be keep the flow
  alive, calling `join/3` later on. Any error return will stop the flow and
  reject the join request.
  """
  def check_permissions(request, socket)

  @spec join(request, Socket.t, assign_function :: term) ::
    {:ok, Socket.t}
    | {:ok, reply :: map, Socket.t}
    | {:error, reply :: map}
  @doc """
  Joins the channel, assigning whatever needs to be assigned to the socket, and
  causing any side-effects that should be caused (either by direct action or
  events).

  The assign param must be passed as a pointer/reference to the original
  function because it is an implementation of the Channel behavior. As such,
  should be called as `assign.(socket, :foo, :bar)`

  # Return

  `join/3` must return what Phoenix's join/3 is expected to return, i.e.:

  - {:ok, Socket.t}
  - {:ok, reply :: map, Socket.t}
  - {:error, reply :: map}
  """
  def join(request, socket, assign)

  def log_error(request, socket, reason)
end
