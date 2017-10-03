defmodule Helix.Log.Model.Log.LogCreatedEvent do
  alias Helix.Server.Model.Server

  @type t :: %__MODULE__{server_id: Server.id}

  @enforce_keys [:server_id]
  defstruct [:server_id]

  defimpl Helix.Event.Notificable do

    @event "log_created"

    def generate_payload(_event, _socket) do
      data = %{}

      return = %{
        data: data,
        event: @event
      }

      {:ok, return}
    end

    def whom_to_notify(event),
      do: %{server: event.server_id}
  end
end

defmodule Helix.Log.Model.Log.LogModifiedEvent do
  alias Helix.Server.Model.Server

  @type t :: %__MODULE__{server_id: Server.id}

  @enforce_keys [:server_id]
  defstruct [:server_id]

  defimpl Helix.Event.Notificable do

    @event "log_modified"

    def generate_payload(_event, _socket) do
      data = %{}

      return = %{
        data: data,
        event: @event
      }

      {:ok, return}
    end

    def whom_to_notify(event),
      do: %{server: event.server_id}
  end
end

defmodule Helix.Log.Model.Log.LogDeletedEvent do
  alias Helix.Server.Model.Server

  @type t :: %__MODULE__{server_id: Server.id}

  @enforce_keys [:server_id]
  defstruct [:server_id]

  defimpl Helix.Event.Notificable do

    @event "log_deleted"

    def generate_payload(_event, _socket) do
      data = %{}

      return = %{
        data: data,
        event: @event
      }

      {:ok, return}
    end

    def whom_to_notify(event),
      do: %{server: event.server_id}
  end
end
