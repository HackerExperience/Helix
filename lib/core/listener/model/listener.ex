defmodule Helix.Core.Listener.Model.Listener do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.HETypes

  @type t :: %__MODULE__{
    listener_id: id,
    object_id: object_id,
    event: event,
    callback: callback,
    meta: meta
  }

  @typedoc """
  `info` is the format returned by Listener to the Query and EventHandler
  modules. It contains the minimum required information in order to call the
  registered callback.
  """
  @type info ::
    %{
      module: String.t,
      method: String.t,
      meta: meta
    }

  @type id :: HETypes.uuid

  @typedoc """
  The object being tracked. Within the context of Listener, it's always a
  string. The object id can be anything - Log.id, File.id, Server.id, or even
  non-ids, say, Network.nip (concatenated Network.id + Network.ip).
  """
  @type object_id :: String.t

  @typedoc """
  Listener stores the event as a MD5 hash, in order to make search more
  efficient (specially because all events start with `Elixir.Helix`). The role
  of hashing an event, or even converting it to a string, is internal to the
  Listener service, and users of the Listener API should not care about this
  implementation detail.
  """
  @type event :: String.t
  @type hashed_event :: String.t

  @typedoc """
  On the database, the callback method is stored as a string array of size two
  (2-tuple). The first element represents the module, and the second, the method
  that should be called once that specific `event` happens to the `object_id`.
  """
  @type callback :: [String.t]

  @typedoc """
  The `callback_tuple` type is the callback representation used internally by
  Helix, before it's been persisted in the DB.
  """
  @type callback_tuple :: {module :: String.t, method :: String.t}

  @typedoc """
  `meta` is an additional parameter, defined at "listen-time", which will be
  relayed to the callback once the Listener is triggered.
  """
  @type meta :: map

  @type changeset :: %Changeset{data: %__MODULE__{}}
  @type creation_params :: term

  @creation_fields [:object_id, :event, :callback, :meta]
  @required_fields [:object_id, :event, :callback]

  @primary_key false
  @ecto_autogenerate {:listener_id, {Ecto.UUID, :generate, []}}
  schema "listeners" do
    field :listener_id, Ecto.UUID,
      primary_key: true
    field :object_id, :string
    field :event, Ecto.UUID
    field :callback, {:array, :string}
    field :meta, :map
  end

  @spec create_changeset(creation_params) ::
    changeset
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  @spec hash_event(event) ::
    hashed_event
  def hash_event(event),
    do: :crypto.hash(:md5, event)

  @spec format([term]) ::
    info
  def format([[module, method], meta]) do
    %{
      module: module,
      method: method,
      meta: meta
    }
  end

  defmodule Query do

    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Core.Listener.Model.Listener

    @spec by_listener(Queryable.t, Listener.id) ::
      Queryable.t
    def by_listener(query \\ Listener, listener_id),
      do: where(query, [l], l.listener_id == ^listener_id)

    @spec by_object_and_event(
      Queryable.t, Listener.object_id, Listener.hashed_event
    ) ::
      Queryable.t
    def by_object_and_event(query \\ Listener, object_id, event) do
      query
      |> where([l], l.object_id == ^object_id)
      |> by_event(event)
    end

    @spec by_event(Queryable.t, Listener.hashed_event) ::
      Queryable.t
    defp by_event(query, event),
      do: where(query, [l], l.event == ^event)
  end

  defmodule Select do

    import Ecto.Query

    alias Ecto.Queryable

    @spec callback(Queryable.t) ::
      Queryable.t
    def callback(query) do
      select(query, [l], [l.callback, l.meta])
    end
  end
end
