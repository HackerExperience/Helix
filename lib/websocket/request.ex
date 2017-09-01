defmodule Helix.Websocket.Request do
  @moduledoc """
  `Request` is a generic data type that represents any Channel request that is
  handled by `Requestable`.

  A module that wants to process channel requests should:

  - Register itself as a request (`Request.register()`)
  - Implement the Requestable protocol

  For usage example, see `lib/server/websocket/server/requests/bruteforce.ex`
  """

  @type t(struct) :: %{
    __struct__: struct,
    unsafe: map,
    params: map,
    meta: map
  }

  defmacro register do
    type =
      quote do
        @type t :: Helix.Websocket.Request.t(__MODULE__)
      end

    struct =
      quote do
        @enforce_keys [:unsafe]
        defstruct [:unsafe, params: %{}, meta: %{}]
      end

    new =
      quote do
        @spec new(term) :: t
        def new(params) do
          %__MODULE__{
            unsafe: params
          }
        end
      end

    [type, struct, new]
  end
end
