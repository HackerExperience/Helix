defmodule Helix.Websocket.Join do
  @moduledoc """
  WebsocketJoin is a generic data type that represents an external request
  asking to join a Channel. It is handled by the `Joinable` protocol.
  """

  alias HELL.Constant

  @type t(struct) :: %{
    __struct__: struct,
    unsafe: map,
    params: map,
    meta: map,
    type: Constant.t,
    topic: String.t
  }

  defmacro register do
    type =
      quote do
      @type t :: Helix.Websocket.Join.t(__MODULE__)
    end

    struct =
      quote do
      @enforce_keys [:topic, :unsafe, :type]
      defstruct [:topic, :unsafe, :type, params: %{}, meta: %{}]
    end

    new =
      quote do
      @spec new(term, term, term) :: t
      def new(topic, params \\ %{}, join_type \\ :default) do
        %__MODULE__{
          unsafe: params,
          topic: topic,
          type: join_type
        }
      end
    end

    [type, struct, new]
  end
end
