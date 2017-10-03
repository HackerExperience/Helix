defmodule Helix.Story.Model.StoryEmail do
  @moduledoc """
  StoryEmail is a persistent storage on the Database holding information about
  all Storyline Emails exchanged by the Player and the story Contacts.

  It assumes that one contact may exchange multiple messages, hence a list of
  emails is used for each contact.

  These emails may have been sent either by the contact, or by the player. As
  such, each one has a `sender` field, which may be one of `:contact` or
  `:player`.

  An email may have metadata, for the case where IDs or IPs must be saved along
  with it.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Entity.Model.Entity
  alias Helix.Story.Model.Step

  @type sender :: :contact | :player

  @type t :: %__MODULE__{
    entity_id: Entity.id,
    contact_id: Step.contact,
    emails: [email]
  }

  @type email :: %{
    timestamp: DateTime.t,
    id: Step.email_id,
    sender: sender,
    meta: Step.meta
  }

  @type creation_params :: %{
    entity_id: Entity.idtb,
    contact_id: Step.contact
  }

  @type email_creation_params :: %{
    id: Step.email_id,
    meta: Step.meta,
    sender: sender
  }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @creation_fields ~w/entity_id contact_id/a

  @primary_key false
  schema "story_emails" do
    field :entity_id, Entity.ID,
      primary_key: true
    field :contact_id, Constant,
      primary_key: true
    field :emails, {:array, :map},
      default: []
  end

  @spec create_changeset(creation_params) ::
    changeset
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> generic_validations()
  end

  @spec create_email(Step.email_id, Step.email_meta, sender) ::
    email
  def create_email(id, meta, sender) do
    if sender != :player and sender != :contact,
      do: raise "invalid sender #{inspect sender}"

    %{
      id: id,
      meta: meta,
      sender: sender,
      timestamp: DateTime.utc_now()
    }
  end

  @spec format(t) ::
    t
  @doc """
  Formats the email metadata, making sure it's a valid Elixir map. It also sorts
  all emails from newest to oldest.
  """
  def format(entry) do
    formatted_emails =
      entry.emails
      |> Enum.map(&format_email/1)
      |> Enum.sort(&(&2.timestamp >= &1.timestamp))

    %{entry| emails: formatted_emails}
  end

  @spec format_email(%{String.t => String.t | map}) ::
    email
  defp format_email(email) do
    {:ok, timestamp, _} = DateTime.from_iso8601(email["timestamp"])

    %{
      id: email["id"],
      meta: email["meta"],
      sender: String.to_existing_atom(email["sender"]),
      timestamp: timestamp
    }
  end

  @spec generic_validations(changeset) ::
    changeset
  defp generic_validations(changeset) do
    changeset
    |> validate_required(@creation_fields)
  end

  defmodule Query do

    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Entity.Model.Entity
    alias Helix.Story.Model.Step
    alias Helix.Story.Model.StoryEmail

    @spec by_entity(Queryable.t, Entity.idtb) ::
      Queryable.t
    def by_entity(query \\ StoryEmail, entity_id),
      do: where(query, [s], s.entity_id == ^entity_id)

    @spec by_contact(Queryable.t, Step.contact) ::
      Queryable.t
    def by_contact(query, contact_id),
      do: where(query, [s], s.contact_id == ^contact_id)

    @spec append_email(Queryable.t, StoryEmail.email) ::
      Queryable.t
    def append_email(query, email),
      do: update(query, [s], [push: [emails: ^email]])
  end
end
