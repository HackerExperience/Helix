defmodule Helix.Story.Model.StoryEmailTest do

  use ExUnit.Case, async: true

  import Ecto.Changeset
  import HELL.MacroHelpers

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Model.StoryEmail

  alias HELL.TestHelper.Random
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "create_changeset/1" do
    test "changeset is created as expected with valid input" do
      params = %{
        entity_id: Entity.ID.generate(),
        contact_id: Random.atom()
      }

      changeset = StoryEmail.create_changeset(params)
      assert changeset.valid?

      story_email = apply_changes(changeset)
      assert story_email.entity_id == params.entity_id
      assert story_email.contact_id == params.contact_id
      assert story_email.emails == []
    end

    test "refuses to create changeset if invalid data is given" do
      params = %{
        entity_id: Entity.ID.generate(),
        contact_id: Random.atom()
      }

      params1 = Map.delete(params, :entity_id)
      params2 = Map.delete(params, :contact_id)
      params3 = %{params| contact_id: "invalid_contact"}

      cs1 = StoryEmail.create_changeset(params1)
      cs2 = StoryEmail.create_changeset(params2)
      cs3 = StoryEmail.create_changeset(params3)

      refute cs1.valid?
      refute cs2.valid?
      refute cs3.valid?
    end
  end

  describe "create_email/3" do
    test "creates an email object when input is valid" do
      email_id = "email_id"
      meta = %{}
      sender = Enum.random([:player, :contact])

      email = StoryEmail.create_email(email_id, meta, sender)

      assert email.id == email_id
      assert email.meta == meta
      assert email.sender == sender
      assert email.timestamp
    end

    test "raises if invalid sender is given" do
      assert_raise RuntimeError, fn ->
        StoryEmail.create_email("id", %{}, Random.atom())
      end
    end
  end

  describe "format/1" do
    test "recovers internal Helix format" do
      {entry, _} = StorySetup.fake_story_email(email_total: 3)

      new_emails = mess_up_email_format(entry.emails)

      formatted = StoryEmail.format(%{entry| emails: new_emails})

      Enum.each(formatted.emails, fn email ->
        assert email.id
        assert email.meta
        assert email.sender
        assert email.timestamp
      end)
    end

    test "sorts the email by timestamp, asc" do
      {entry, _} = StorySetup.fake_story_email(email_total: 5)

      # Ensure email order is messed up
      shuffled_emails =
        entry.emails
        |> Enum.shuffle()
        |> mess_up_email_format()

      formatted = StoryEmail.format(%{entry| emails: shuffled_emails})

      sorted_emails = Enum.sort(entry.emails, &(&2.timestamp >= &1.timestamp))

      assert formatted.emails == sorted_emails
    end

    docp """
    We've just generated this data, and it never went through the database,
    so it is in the expected format! We'll mock the DB behaviour and mess
    up our email entries
    """
    defp mess_up_email_format(emails) do
      Enum.map(emails, fn email ->
        %{
          "id" => email.id,
          "meta" => email.meta,
          "sender" => Atom.to_string(email.sender),
          "timestamp" => DateTime.to_string(email.timestamp)
        }
      end)
    end
  end
end
