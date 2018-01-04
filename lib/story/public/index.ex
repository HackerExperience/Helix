defmodule Helix.Story.Public.Index do

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Story
  alias Helix.Story.Query.Story, as: StoryQuery

  @type index ::
    %{
      email: [email_entry]
    }

  @type rendered_index ::
    %{
      email: [rendered_email_entry]
    }

  @typep email_entry ::
    %{
      contact_id: Step.contact,
      messages: [message]
    }

  @typep rendered_email_entry ::
    %{
      contact_id: String.t,
      messages: [rendered_message]
    }

  @typep message ::
    %{
      id: Step.email_id,
      meta: Step.email_meta,
      sender: Story.Email.sender,
      timestamp: DateTime.t
    }

  @typep rendered_message ::
    %{
      id: String.t,
      meta: map,
      sender: String.t,
      timestamp: String.t
    }

  @spec index(Entity.id) ::
    index
  def index(entity_id) do
    email =
      entity_id
      |> StoryQuery.get_emails()
      |> Enum.map(fn story_email ->
          %{
            contact_id: story_email.contact_id,
            messages: messages(story_email.emails),
            replies: []  # TODO
          }
        end)

    %{
      email: email
    }
  end

  @spec index(index) ::
    rendered_index
  def render_index(index) do
    rendered_email =
      Enum.map(index.email, fn entry ->
        %{
          contact_id: to_string(entry.contact_id),
          messages: render_messages(entry.messages)
        }
      end)

    %{
      email: rendered_email
    }
  end

  @spec messages([Story.Email.email]) ::
    [rendered_message]
  def messages(messages),
    do: Enum.map(messages, &message/1)

  @spec render_messages([message]) ::
    [rendered_message]
  def render_messages(messages),
    do: Enum.map(messages, &render_message/1)

  @spec message(Story.Email.email) ::
    message
  def message(data) do
    %{
      id: data.id,
      meta: data.meta,
      sender: data.sender,
      timestamp: data.timestamp
    }
  end

  @spec render_message(message) ::
    rendered_message
  def render_message(message) do
    %{
      id: message.id,
      meta: message.meta,
      sender: to_string(message.sender),
      timestamp: to_string(message.timestamp)
    }
  end
end
