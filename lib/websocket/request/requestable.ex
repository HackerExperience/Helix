defprotocol Helix.Websocket.Requestable do
  @moduledoc """
  # Requestable Protocol

  The Requestable protocol is a standard structure meant to define the flow of a
  Channel request, which is defined as:

  1 - Check parameters of the request (`check_params/2`)
  2 - Check permissions of the request (`check_permissions/2`)
  3 - Handle the request (`handle_request/2`)
  4 - Render the output and reply to the client (`reply/2`)

  # Return Convention

  `check_params/2`, `check_permissions/2` and `handle_request/2` should always
  return {:ok, Request.t} in case of success. All other results are handled as
  errors.

  If the error returned by the methods above is in the format
  `{error: %{message: msg}}`, then this error is relayed` to the client. For all
  other cases, an "helix_internal" error is issued, as we understand that an
  unhandled event happened.

  `reply/2`, due to its nature, have a different return. It is the return of
  Phoenix's `handle_in` callback, so it should be any of

  - {:reply, {:ok, %{}}, socket}
  - {:reply, :ok, socket}
  - {:noreply, socket}
  - {:stop, reason, socket}
  - {:stop, reason, %{}, socket}

  # Advantages

  By adopting the Requestable protocol, we can inspect a request's lifetime in
  a clear and linear structure. It also eases testing, in case it's desired to
  test a specific part of the flow, or the entire flow without having to set up
  an actual Channel socket.
  """

  alias Helix.Websocket
  alias Helix.Websocket.Request

  @spec check_params(Request.t(term), Websocket.t) ::
    {:ok, Request.t(term)}
    | {:error, term}
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

  @spec check_permissions(Request.t(term), Websocket.t) ::
    {:ok, Request.t(term)}
    | {:error, term}
  @doc """
  Method focused on validating and verifying the user has the permissions to
  perform that action.

  Should never rely on `unsafe`.

  May fill the entry `meta` on Request.t in order to relay useful information
  for the next flow steps.

  # Return

  Must return {:ok, Request.t} in case of success.
  """
  def check_permissions(request, socket)

  @spec handle_request(Request.t(term), Websocket.t) ::
    {:ok, Request.t(term)}
    | {:error, term}
  @doc """
  Method responsible for actual processing of the event, routing it to the
  corresponding Public.

  Should never rely on `unsafe`.

  May fill the entry `meta` on Request.t in order to relay useful information to
  `reply/2`.

  # Return

  Must return {:ok, Request.t} in case of success.
  """
  def handle_request(request, socket)

  @spec reply(Request.t(term), Websocket.t) ::
    {:ok, reply :: map}
    | {:error, reply :: map}
    | {:stop, reason :: term}
    | :noreply
  @doc """
  Final step of the flow, which is only reached when all previous steps were
  successful.

  It's responsible for rendering the expected output, casting to JSON friendly
  format or filtering unwanted output.

  Note that `reply/2` is always called within the context of the user requesting
  an action, so the response:

  - only goes to one user/channel
  - only goes to the user who *performed* the action

  Because of this, filtering/censoring data here is a lot less important/common
  than, say, filtering output on Requestable, which is broadcasted to all users
  listening to a specific Channel.

  # Return

  `reply/2` is supposed to *render* the output to the client. The flow of the
  whole Requestable protocol is controlled at Websocket.Socket, which will reply
  to the request according to the return of `reply/2`.

  If `reply/2` returns a `{:ok, data :: map}` tuple, it is indicating that the
  response should reach the user. On the other hand, if it returns a `:noreply`
  atom, well, the user will get no reply.

  A return of `{:error, data ::  map}` will send the rendered data to the client
  with an error code.

  This can further be extended to include all possible Channel responses, namely
  missing the `{:stop, reason}` response.
  """
  def reply(request, socket)
end
