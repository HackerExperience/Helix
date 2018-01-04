defmodule Helix.Story.Model.Story.Step do
  @moduledoc """
  Story.Step is a persistent representation of the Player's current step.

  It's only a helper to be used alongside Step, but a necessary one in order to
  save state, like all emails that have been sent, or the allowed replies a
  player may sent (including unlocked ones).

  The `meta` field is the same one from Step meta. Since it's stored as JSONB,
  it may lose internal Helix data structure representation, in which case
  Steppable.format should be called in order to translate the record back to
  Helix format.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Entity.Model.Entity
  alias Helix.Story.Model.Step

  @type t :: %__MODULE__{
    entity_id: Entity.id,
    step_name: Step.step_name,
    meta: Step.meta,
    emails_sent: [Step.email_id],
    allowed_replies: [Step.reply_id]
  }

  @type creation_params :: %{
    :entity_id => Entity.idtb,
    :step_name => Step.step_name,
    :meta => Step.meta,
    optional(:allowed_replies) => [Step.reply_id],
    optional(:emails_sent) => [Step.email_id]
  }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @creation_fields ~w/entity_id step_name meta emails_sent allowed_replies/a
  @required_fields ~w/entity_id step_name meta/a

  @primary_key false
  schema "story_steps" do
    field :entity_id, Entity.ID,
      primary_key: true
    field :step_name, Constant,
      primary_key: true

    field :meta, :map
    field :emails_sent, {:array, :string},
      default: []
    field :allowed_replies, {:array, :string},
      default: []
  end

  @spec create_changeset(creation_params) ::
    changeset
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  @spec replace_meta(t, Step.meta) ::
    changeset
  @doc """
  Overwrites the metadata field. Useful when a generated ID has changed, for
  example.
  """
  def replace_meta(entry, meta) when is_map(meta) do
    entry
    |> Changeset.change()
    |> put_change(:meta, meta)
  end

  @spec unlock_reply(t, Step.reply_id) ::
    changeset
  @doc """
  Unlocks a reply, i.e. it adds the reply to the `allowed_replies` list,
  allowing the user to use it as a reply. Useful when a Step reply depends
  upon an external action/event made by the player.
  """
  def unlock_reply(entry, reply_id) do
    entry
    |> Changeset.change()
    |> do_unlock(reply_id)
  end

  @spec lock_reply(t, Step.reply_id) ::
    changeset
  @doc """
  Opposite of `unlock_reply`, i.e. it removes a reply from the list of allowed
  replies. Called automatically after each reply sent by the user, avoiding
  him from sending the same reply multiple times.

  If a Step wants to support repeated replies by the user, it must explicitly
  unlock the reply after it has been sent.
  """
  def lock_reply(entry, reply_id) do
    entry
    |> Changeset.change()
    |> do_lock(reply_id)
  end

  @spec append_email(t, Step.email_id, [Step.email_id]) ::
    changeset
  @doc """
  Marks the given `email_id` as sent, saving alongside it a list of possible
  replies.
  """
  def append_email(entry, email_id, allowed_replies) do
    entry
    |> Changeset.change()
    |> do_append(email_id)
    |> put_change(:allowed_replies, allowed_replies)
  end

  @spec get_current_email(t) ::
    last_email :: Step.email_id
    | nil
  @doc """
  Returns the current email, which is the last email on the `emails_sent` list
  """
  def get_current_email(entry),
    do: List.last(entry.emails_sent)

  @spec can_send_reply?(t, Step.reply_id) ::
    boolean
  @doc """
  Verifies whether the player can send the given reply_id. There are two cases
  the player may not be allowed to reply:
  1 - When the reply_id does not exist for that email.
  2 - When the reply_id is not listed on `allowed_replies`. Usually, the
    reply_id is locked by default and the player did not performed the event
    needed in order to unlock it.
  """
  def can_send_reply?(entry, reply_id),
    do: Enum.member?(get_allowed_replies(entry), reply_id)

  @spec get_allowed_replies(t) ::
    [Step.reply_id]
  @doc """
  Returns all allowed replies by the player
  """
  def get_allowed_replies(entry),
    do: entry.allowed_replies

  @spec do_unlock(changeset, Step.reply_id) ::
    changeset
  defp do_unlock(changeset, reply_id) do
    previously_unlocked = get_field(changeset, :allowed_replies, [])

    new_replies =
      previously_unlocked
      |> Kernel.++([reply_id])
      |> Enum.uniq()

    changeset
    |> put_change(:allowed_replies, new_replies)
  end

  @spec do_lock(changeset, Step.reply_id) ::
    changeset
  defp do_lock(changeset, reply_id) do
    previously_unlocked = get_field(changeset, :allowed_replies, [])
    new_replies = List.delete(previously_unlocked, reply_id)

    changeset
    |> put_change(:allowed_replies, new_replies)
  end

  @spec do_append(changeset, Step.email_id) ::
    changeset
  defp do_append(changeset, email_id) do
    previously_sent = get_field(changeset, :emails_sent, [])

    changeset
    |> put_change(:emails_sent, previously_sent ++ [email_id])
  end

  query do

    alias Helix.Entity.Model.Entity
    alias Helix.Story.Model.Step
    alias Helix.Story.Model.Story

    @spec by_entity(Queryable.t, Entity.idtb) ::
      Queryable.t
    def by_entity(query \\ Story.Step, entity_id),
      do: where(query, [s], s.entity_id == ^entity_id)

    @spec by_step(Queryable.t, Step.step_name) ::
      Queryable.t
    def by_step(query, step_name),
      do: where(query, [s], s.step_name == ^step_name)
  end
end
