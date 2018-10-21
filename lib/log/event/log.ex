defmodule Helix.Log.Event.Log do

  import Helix.Event

  event Created do
    @moduledoc """
    LogCreatedEvent is fired when a brand new log entry is added to the server.

    The newly created log may be either natural (automatically created by the
    game) or artificial (explicitly created by the player through LogForge
    mechanics). Either way, the receiving end of the event (Client) DOES NOT
    know whether the log is natural or artificial.
    """

    alias Helix.Log.Model.Log

    @type t ::
      %__MODULE__{
        log: Log.t
      }

    event_struct [:log]

    @spec new(Log.t) ::
      t
    def new(log = %Log{}) do
      %__MODULE__{
        log: log
      }
    end

    publish do

      alias Helix.Log.Public.Index, as: LogIndex

      @event :log_created

      def generate_payload(event, _socket) do
        data = LogIndex.render_log(event.log)

        {:ok, data}
      end

      def whom_to_publish(event),
        do: %{server: event.log.server_id}
    end

    notification do
      @moduledoc """
      When the created log is artificial a notification is sent to the player.
      """

      @class :server
      @code :log_created

      def whom_to_notify(%_{log: log}) do
        if Log.is_artificial?(log) do
          %{account_id: log.revision.entity_id, server_id: log.server_id}
        else
          :no_one
        end
      end
    end
  end

  event Revised do
    @moduledoc """
    `LogRevisedEvent` is fired when an existing log had a revision added to it.

    The revision may be stacked up on a natural or artificial log - the log
    origin is transparent to the Client.
    """

    alias Helix.Log.Model.Log

    event_struct [:log]

    @type t ::
      %__MODULE__{
        log: Log.t
      }

    @spec new(Log.t) ::
      t
    def new(log = %Log{}) do
      %__MODULE__{
        log: log
      }
    end

    publish do

      alias Helix.Log.Public.Index, as: LogIndex

      @event :log_revised

      def generate_payload(event, _socket) do
        data = LogIndex.render_log(event.log)

        {:ok, data}
      end

      def whom_to_publish(event),
        do: %{server: event.log.server_id}
    end

    notification do
      @moduledoc """
      When the created log is artificial a notification is sent to the player.
      """

      @class :server
      @code :log_revised

      def whom_to_notify(%_{log: log}),
        do: %{account_id: log.revision.entity_id, server_id: log.server_id}
    end
  end

  event Recovered do
    @moduledoc """
    LogRecoveredEvent is fired when a forged log has a revision popped out of
    its stack, and a new revision is discovered.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Log.Model.Log

    @type t ::
    %__MODULE__{
      log: Log.t,
      entity_id: Entity.id
    }

    event_struct [:log, :entity_id]

    @spec new(Log.t, Entity.id) ::
      t
    def new(log = %Log{}, entity_id) do
      %__MODULE__{
        log: log,
        entity_id: entity_id
      }
    end

    publish do

      alias Helix.Log.Public.Index, as: LogIndex

      @event :log_recovered

      def generate_payload(event, _socket) do
        data = LogIndex.render_log(event.log)

        {:ok, data}
      end

      def whom_to_publish(event),
        do: %{server: event.log.server_id}
    end

    notification do
      @moduledoc """
      Notify the user when the process finishes and the log got recovered.
      """

      @class :server
      @code :log_recovered

      def whom_to_notify(event),
        do: %{account_id: event.entity_id, server_id: event.log.server_id}
    end
  end

  event Destroyed do
    @moduledoc """
    LogDestroyedEvent is fired when a forged log is recovered beyond its
    original revision, leading to the log deletion.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Log.Model.Log

    @type t ::
      %__MODULE__{
        log: Log.t,
        entity_id: Entity.id
      }

    event_struct [:log, :entity_id]

    @spec new(Log.t, Entity.id) ::
      t
    def new(log = %Log{}, entity_id) do
      %__MODULE__{
        log: log,
        entity_id: entity_id
      }
    end

    publish do

      @event :log_destroyed

      def generate_payload(event, _socket) do
        data = %{
          log_id: to_string(event.log.log_id)
        }

        {:ok, data}
      end

      def whom_to_publish(event),
        do: %{server: event.log.server_id}
    end

    notification do
      @moduledoc """
      Notify the user when the process finishes and the artificial log is
      destroyed.
      """

      @class :server
      @code :log_destroyed

      def whom_to_notify(event),
        do: %{account_id: event.entity_id, server_id: event.log.server_id}
    end
  end
end
