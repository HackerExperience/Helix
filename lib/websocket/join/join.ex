defmodule Helix.Websocket.Join do
  @moduledoc """
  WebsocketJoin is a generic data type that represents an external request
  asking to join a Channel. It is handled by the `Joinable` protocol.
  """

  alias Helix.Websocket.Utils, as: WebsocketUtils

  @type t(struct) :: %{
    __struct__: struct,
    unsafe: map,
    params: map,
    meta: map,
    type: nil | :local | :remote,
    topic: String.t
  }

  defmacro join(name, do: block) do
    quote do

      defmodule unquote(name) do
        @moduledoc false

        import Helix.Websocket.Flow

        @type t :: Helix.Websocket.Join.t(__MODULE__)

        @enforce_keys [:topic, :unsafe, :type]
        defstruct [:topic, :unsafe, :type, params: %{}, meta: %{}]

        @spec new(term, term, term) ::
          t
        def new(topic, params \\ %{}, join_type \\ nil) do
          %__MODULE__{
            unsafe: params,
            topic: topic,
            type: join_type
          }
        end

        defimpl Helix.Websocket.Joinable do
          @moduledoc false

          unquote(block)

          # Fallbacks to WebsocketUtils' general purpose error code translator.
          defp get_error(error),
            do: WebsocketUtils.get_error(error)
        end
      end

    end
  end
end
