defmodule Helix.Story.Public.Index do

  alias HELL.ClientUtils
  alias HELL.HETypes
  alias Helix.Entity.Model.Entity
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Story
  alias Helix.Story.Query.Story, as: StoryQuery

  @type index ::
    %{
      Step.contact => step_entry
    }

  @type rendered_index ::
    %{
      String.t => rendered_step_entry
    }

  @typep step_entry ::
    %{
      emails: [email],
      replies: [Step.reply_id],
      name: Step.name,
      meta: Step.meta
    }

  @typep rendered_step_entry ::
    %{
      emails: [rendered_email],
      replies: [String.t],
      name: String.t,
      meta: map
    }

  @typep email ::
    %{
      id: Step.email_id,
      meta: Step.email_meta,
      sender: Story.Email.sender,
      timestamp: DateTime.t
    }

  @typep rendered_email ::
    %{
      id: String.t,
      meta: map,
      sender: String.t,
      timestamp: HETypes.client_timestamp
    }

  @spec index(Entity.id) ::
    index
  def index(entity_id) do
    steps = StoryQuery.get_steps(entity_id)
    emails = StoryQuery.get_emails(entity_id)

    steps
    |> Enum.reduce(%{}, fn %{entry: story_step}, acc ->
      idx =
        %{
          emails: index_emails(emails, story_step),
          replies: story_step.allowed_replies,
          name: story_step.step_name,
          meta: story_step.meta
        }

      acc
      |> Map.put(story_step.contact_id, idx)
    end)
  end

  @spec index(index) ::
    rendered_index
  def render_index(index) do
    index
    |> Enum.reduce(%{}, fn {contact_id, entry}, acc ->
      data =
        %{
          emails: render_emails(entry.emails),
          replies: entry.replies,
          name: to_string(entry.name),
          meta: entry.meta
        }

      acc
      |> Map.put(contact_id, data)
    end)
  end

  @spec index_emails([Story.Email.t], Story.Step.t) ::
    [email]
  defp index_emails(emails, story_step) do
    emails
    |> Enum.filter(&(&1.contact_id == story_step.contact_id))
    |> Enum.map(fn story_email ->
      emails(story_email.emails)
    end)
    |> List.flatten()
  end

  @spec emails([Story.Email.email]) ::
    [email]
  defp emails(emails),
    do: Enum.map(emails, &email/1)

  @spec render_emails([email]) ::
    [rendered_email]
  defp render_emails(emails),
    do: Enum.map(emails, &render_email/1)

  @spec email(Story.Email.email) ::
    email
  defp email(data) do
    %{
      id: data.id,
      meta: data.meta,
      sender: data.sender,
      timestamp: data.timestamp
    }
  end

  @spec render_email(email) ::
    rendered_email
  defp render_email(email) do
    %{
      id: email.id,
      meta: email.meta,
      sender: to_string(email.sender),
      timestamp: ClientUtils.to_timestamp(email.timestamp)
    }
  end
end
