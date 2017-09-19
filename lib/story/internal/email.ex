defmodule Helix.Story.Internal.Email do

  alias Helix.Story.Model.Step
  alias Helix.Story.Model.StoryEmail
  alias Helix.Story.Repo

  @type entry_email_repo_return ::
    {:ok, StoryEmail.t}
    | {:error, StoryEmail.changeset}

  @spec fetch(Entity.id, Step.contact) ::
    StoryEmail.t
    | nil
  def fetch(entity_id, contact_id) do
    entity_id
    |> StoryEmail.Query.by_entity()
    |> StoryEmail.Query.by_contact(contact_id)
    |> Repo.one()
  end

  @spec get_emails(Entity.id) ::
    [StoryEmail.t]
  def get_emails(entity_id) do
    entity_id
    |> StoryEmail.Query.by_entity()
    |> Repo.all()
  end

  @spec add_contact(Entity.id, Step.contact) ::
    entry_email_repo_return
  def add_contact(entity_id, contact_id) do
    %{
      entity_id: entity_id,
      contact_id: contact_id
    }
    |> StoryEmail.create_changeset()
    |> Repo.insert()
  end

  @spec send_email(Step.t(struct), Step.email_id, Step.email_meta) ::
    entry_email_repo_return
  def send_email(step, email_id, meta),
    do: generic_send(step, email_id, :contact, meta)

  @spec send_reply(Step.t(struct), Step.reply_id) ::
    entry_email_repo_return
  def send_reply(step, reply_id),
    do: generic_send(step, reply_id, :player)

  @spec generic_send(term, id :: String.t, StoryEmail.sender, meta :: map) ::
    entry_email_repo_return
  defp generic_send(step, id, sender, meta \\ %{}) do
    email = create_email(id, sender, meta)
    contact_id = Step.get_contact(step)

    ensure_exists(step.entity_id, contact_id)
    append_email(step.entity_id, contact_id, email)
  end

  @spec ensure_exists(Entity.id, Step.contact) ::
    :ok
  defp ensure_exists(entity_id, contact_id) do
    case fetch(entity_id, contact_id) do
      %StoryEmail{} ->
        :ok
      _ ->
        {:ok, _} = add_contact(entity_id, contact_id)
    end
  end

  @spec create_email(Step.email_id, StoryEmail.sender, Step.meta) ::
    entry_email_repo_return
  def create_email(id, sender, meta),
    do: StoryEmail.create_email(id, meta, sender)

  @spec append_email(Entity.id, Step.contact, StoryEmail.email) ::
    {integer, nil | [term]}
    | no_return
  def append_email(entity_id, contact_id, email) do
    entity_id
    |> StoryEmail.Query.by_entity()
    |> StoryEmail.Query.by_contact(contact_id)
    |> StoryEmail.Query.append_email(email)
    |> Repo.update_all([])
  end
end
