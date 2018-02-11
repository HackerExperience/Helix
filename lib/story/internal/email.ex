defmodule Helix.Story.Internal.Email do

  import HELL.Macros

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Story
  alias Helix.Story.Repo

  @type entry_email_repo_return ::
    {:ok, Story.Email.t}
    | {:error, Story.Email.changeset}

  @typep fetch_result ::
    Story.Email.t
    | nil

  @spec fetch(Step.t) :: fetch_result
  @spec fetch(Entity.id, Step.contact) :: fetch_result
  @doc """
  Fetches the (entity, contact) entry, formatting it as required
  """
  def fetch(%_{entity_id: entity_id, contact: contact_id}),
    do: fetch(entity_id, contact_id)
  def fetch(entity_id, contact_id) do
    entry =
      entity_id
      |> Story.Email.Query.by_entity()
      |> Story.Email.Query.by_contact(contact_id)
      |> Repo.one()

    if entry do
      format(entry)
    end
  end

  @spec get_emails(Entity.id) ::
    [Story.Email.t]
  @doc """
  Returns all emails from all contacts that Entity has ever interacted with.
  """
  def get_emails(entity_id) do
    entity_id
    |> Story.Email.Query.by_entity()
    |> Repo.all()
    |> Enum.map(&format/1)
  end

  @spec send_email(Step.t, Step.email_id, Step.email_meta) ::
    {:ok, Story.Email.t, Story.Email.email}
    | :internal_error
  @doc """
  Sends an email from the contact to the player.
  """
  def send_email(step, email_id, meta),
    do: generic_send(step, email_id, :contact, meta)

  @spec send_reply(Step.t, Step.reply_id) ::
    {:ok, Story.Email.t, Story.Email.email}
    | :internal_error
  @doc """
  Sends a reply from the player to the contact.
  """
  def send_reply(step, reply_id),
    do: generic_send(step, reply_id, :player)

  def rollback_email(step, email_id, meta) do
    step
    |> fetch()
    |> Story.Email.rollback_email(email_id, meta)
    |> update()
  end

  @spec generic_send(term, id :: String.t, Story.Email.sender, meta :: map) ::
    {:ok, Story.Email.t, Story.Email.email}
    | :internal_error
  defp generic_send(step, id, sender, meta \\ %{}) do
    email = create_email(id, sender, meta)
    contact_id = Step.get_contact(step)

    ensure_exists(step.entity_id, contact_id)
    case append_email(step.entity_id, contact_id, email) do
      {1, [story_email]} ->
        entry = format(story_email)
        {:ok, entry, List.last(entry.emails)}
      _ ->
        :internal_error
    end
  end

  @spec ensure_exists(Entity.id, Step.contact) ::
    :ok
  docp """
  If the email being sent is the very first one, i.e. it's the first interaction
  from the player with the contact, then the contact is created.
  """
  defp ensure_exists(entity_id, contact_id) do
    case fetch(entity_id, contact_id) do
      %Story.Email{} ->
        :ok
      _ ->
        {:ok, _} = add_contact(entity_id, contact_id)
    end
  end

  @spec add_contact(Entity.id, Step.contact) ::
    entry_email_repo_return
  docp """
  Creates that new contact for the player
  """
  defp add_contact(entity_id, contact_id) do
    %{
      entity_id: entity_id,
      contact_id: contact_id
    }
    |> Story.Email.create_changeset()
    |> Repo.insert()
  end

  @spec append_email(Entity.id, Step.contact, Story.Email.email) ::
    {integer, nil | [term]}
    | no_return
  docp """
  Appends the email to the previously sent emails, effectively saving it as sent
  """
  defp append_email(entity_id, contact_id, email) do
    entity_id
    |> Story.Email.Query.by_entity()
    |> Story.Email.Query.by_contact(contact_id)
    |> Story.Email.Query.append_email(email)
    |> Repo.update_all([], returning: true)
  end

  @spec update(Story.Email.changeset) ::
    entry_email_repo_return
  defp update(changeset),
    do: Repo.update(changeset)

  @spec format(Story.Email.t) ::
    Story.Email.t
  docp """
  Formats the entry, converting the email metadata back to Elixir maps, and
  sorting all emails from oldest to newest
  """
  defp format(entry),
    do: Story.Email.format(entry)

  @spec create_email(Step.email_id, Story.Email.sender, Step.meta) ::
    Story.Email.email
  defp create_email(id, sender, meta),
    do: Story.Email.create_email(id, meta, sender)
end
