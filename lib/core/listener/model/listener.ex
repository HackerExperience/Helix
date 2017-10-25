defmodule Helix.Core.Listener.Model.Listener do

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Macros

  alias Ecto.Changeset

  @type t :: term
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

  def hash_event(event),
    do: :crypto.hash(:md5, event)

  defmodule Query do

    import Ecto.Query

    alias Helix.Core.Listener.Model.Listener

    def by_listener(query \\ Listener, listener_id),
      do: where(query, [l], l.listener_id == ^listener_id)

    def by_object_and_event(query \\ Listener, object_id, event) do
      query
      |> where([l], l.object_id == ^object_id)
      |> by_event(event)
    end

    defp by_event(query, event),
      do: where(query, [l], l.event == ^event)
  end

  defmodule Select do

    import Ecto.Query

    def callback(query) do
      select(query, [l], [l.callback, l.meta])
    end
  end
end
