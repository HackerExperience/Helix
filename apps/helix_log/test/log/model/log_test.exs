defmodule Helix.Log.Model.LogTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Log.Repo
  alias Helix.Log.Model.Log

  describe "log creation" do
    @tag :integration
    test "creates a revision" do
      params = %{
        server_id: Random.pk(),
        entity_id: Random.pk(),
        message: """
          - I'll now dial an incorrect number
          - Hello. Yes, this is dog
        """
      }

      log =
        params
        |> Log.create_changeset()
        |> Repo.insert!()
        |> Repo.preload(:revisions)

      assert [revision] = log.revisions
      assert params.message == log.message
      assert log.message == revision.message
      assert log.entity_id == revision.entity_id
      refute log.crypto_version
      refute revision.forge_version
    end

    @tag :unit
    test "requires entity_id and server_id" do
      log = Log.create_changeset(%{})

      assert :entity_id in Keyword.keys(log.errors)
      assert :server_id in Keyword.keys(log.errors)
    end

    @tag :integration
    test "can be forged" do
      params = %{
        server_id: Random.pk(),
        entity_id: Random.pk(),
        message: "All your base are belong to us",
        forge_version: 12
      }

      revisions =
        params
        |> Log.create_changeset()
        |> Repo.insert!()
        |> Repo.preload(:revisions)
        |> Map.fetch!(:revisions)

      assert Enum.all?(revisions, &(is_integer(&1.forge_version)))
    end
  end
end