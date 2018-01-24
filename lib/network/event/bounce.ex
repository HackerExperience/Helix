defmodule Helix.Network.Event.Bounce do

  import Helix.Event

  event Created do
    @moduledoc """
    `BounceCreatedEvent` is fired right after the player has created a new
    bounce.

    Notice that the bounce creation is completely OFFLINE, it does not imply
    that the newly created bounce is in use, or will be in use. A bounce may be
    created explicitly at the BounceManager, or implicitly (see #379).
    """

    alias Helix.Network.Model.Bounce

    event_struct [:bounce]

    @type t ::
      %__MODULE__{
        bounce: Bounce.t
      }

    @spec new(Bounce.t) ::
      t
    def new(bounce = %Bounce{}) do
      %__MODULE__{
        bounce: bounce
      }
    end

    notify do
      @moduledoc """
      Notifies the client that a new bounce was created, so the client-side data
      may be updated.
      """

      alias HELL.ClientUtils

      @event :bounce_created

      def generate_payload(event, _socket) do
        links =
          event.bounce.links
          |> Enum.map(fn {_, network_id, ip} ->
            {network_id, ip}
          end)
          |> Enum.map(&ClientUtils.to_nip/1)

        data =
          %{
            bounce_id: to_string(event.bounce.bounce_id),
            name: event.bounce.name,
            links: links
          }

        {:ok, data}
      end

      def whom_to_notify(event),
        do: %{account: event.bounce.entity_id}
    end
  end

  event CreateFailed do
    @moduledoc """
    `BounceCreateFailedEvent` is fired when the user attempted to create a
    bounce but it failed for whatever `reason`.
    """

    alias Helix.Entity.Model.Entity

    event_struct [:entity_id, :reason]

    @type t ::
      %__MODULE__{
        entity_id: Entity.id,
        reason: term
      }

    @spec new(Entity.id, term) ::
      t
    def new(entity_id = %Entity.ID{}, reason) do
      %__MODULE__{
        entity_id: entity_id,
        reason: reason
      }
    end

    notify do
      @moduledoc """
      Notifies the client that the bounce creation attempt has failed, so the
      client who made the request can notify the failure to the player.
      """

      @event :bounce_create_failed

      def generate_payload(event, _socket) do
        data = %{reason: to_string(event.reason)}

        {:ok, data}
      end

      def whom_to_notify(event),
        do: %{account: event.entity_id}
    end
  end

  event Updated do
    @moduledoc """
    `BounceUpdatedEvent` is fired right after the player has updated an existing
    bounce.

    Notice that updating a bounce does not mean ~at all~ that existing tunnels
    will have a different path. It just means that the player's Bounce inventory
    has changed, and future connections will use the new links.
    """

    alias Helix.Network.Model.Bounce

    event_struct [:bounce]

    @type t ::
      %__MODULE__{
        bounce: Bounce.t
      }

    @spec new(Bounce.t) ::
      t
    def new(bounce = %Bounce{}) do
      %__MODULE__{
        bounce: bounce
      }
    end

    notify do
      @moduledoc """
      Notifies the client that the bounce was updated.
      """

      alias HELL.ClientUtils

      @event :bounce_updated

      def generate_payload(event, _socket) do
        links =
          event.bounce.links
          |> Enum.map(fn {_, network_id, ip} ->
            {network_id, ip}
          end)
          |> Enum.map(&ClientUtils.to_nip/1)

        data =
          %{
            bounce_id: to_string(event.bounce.bounce_id),
            name: event.bounce.name,
            links: links
          }

        {:ok, data}
      end

      def whom_to_notify(event),
        do: %{account: event.bounce.entity_id}
    end
  end

  event UpdateFailed do
    @moduledoc """
    `BounceUpdateFailedEvent` is fired when the player attempted to update an
    existing bounce but it failed for some `reason`.
    """

    alias Helix.Entity.Model.Entity

    event_struct [:entity_id, :reason]

    @type t ::
      %__MODULE__{
        entity_id: Entity.id,
        reason: term
      }

    @spec new(Entity.id, term) ::
      t
    def new(entity_id = %Entity.ID{}, reason) do
      %__MODULE__{
        entity_id: entity_id,
        reason: reason
      }
    end

    notify do
      @moduledoc """
      Notifies the client that the bounce update attempt has failed, so the
      client who made the request can notify the failure to the player.
      """

      @event :bounce_update_failed

      def generate_payload(event, _socket) do
        data = %{reason: to_string(event.reason)}

        {:ok, data}
      end

      def whom_to_notify(event),
        do: %{account: event.entity_id}
    end
  end
end
