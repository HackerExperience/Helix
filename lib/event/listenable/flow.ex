defmodule Helix.Event.Listenable.Flow do
  @moduledoc """
  An event may implement the `Listenable` protocol, meaning it can identify one
  or more internal IDs that may be of interest of any other service of the game,
  which is listening to an specific event over an element. Yeah, confusing.

  In other words:

  - Any service of the game may listen (subscribe) to events that are happening
  over the specific object ID. For instance, a specific mission may listen to
  `FileDelete` events over a specific file, identified by `file_id`.

  - The `Listenable` protocol, implemented by any event, is how an ID may be
  inferred by an Event. For instance, the `FileDownloadedEvent` knows that
  `file_id` might be an identifier potentially useful to some other service
  using `Core.Listener`. So it implements the `Listenable` protocol, returning
  a list of potentially useful identifiers.

  - Events that do not implement the `Listenable` protocol won't be handled by
  `ListenerHandler`.
  """

  @doc """
  The `listeneable` macro must be used alongside at least one `listen/2`.

  ## Example

  listenable do
    listen(event = %_{valid?: true}) do
      [event.entity_id, event.file_id]
    end
  end
  """
  defmacro listenable(do: block) do
    quote do

      defimpl Helix.Event.Listenable do
        @moduledoc false

        unquote(block)
      end

    end
  end

  @doc """
  Expands the expected methods of the `Listenable` protocol.
  """
  defmacro listen(event, do: block) do

    fallback_block =
      if elem(event, 0) == := do
        quote do
          def get_objects(_),
            do: []
        end
      else
        []
      end

    quote do

      @doc false
      def get_objects(unquote(event)) do
        unquote(block)
      end

      unquote(fallback_block)

    end
  end
end
