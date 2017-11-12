defmodule Helix.Client.Web1.InternalTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Model.Entity
  alias Helix.Client.Web1.Internal, as: Web1Internal

  alias Helix.Test.Client.Web1.Setup, as: Web1Setup

  describe "create_setup/2" do
    test "entry is inserted on the DB" do
      entity_id = Entity.ID.generate()
      pages = [:welcome]

      assert {:ok, setup} = Web1Internal.create_setup(entity_id, pages)

      assert setup.entity_id == entity_id
      assert setup.pages == pages
    end

    test "rejects invalid page" do
      assert {:error, changeset} =
        Web1Internal.create_setup(Entity.ID.generate(), [:welcome, :bad])

      refute changeset.valid?
      assert :pages in Keyword.keys(changeset.errors)
    end
  end

  describe "fetch_setup/1" do
    test "returns the entry" do
      {setup, _} = Web1Setup.setup()

      assert setup == Web1Internal.fetch_setup(setup.entity_id)
    end
  end

  describe "get_setup_pages/1" do
    test "returns only the pages" do
      {setup, _} = Web1Setup.setup()

      pages = Web1Internal.get_setup_pages(setup.entity_id)

      assert pages == setup.pages
    end
  end

  describe "add_setup_pages" do
    test "appends new pages without duplicates" do
      {setup, _} = Web1Setup.setup(pages: [:welcome])

      {:ok, entry} = Web1Internal.add_setup_pages(setup, [:welcome, :server])

      # Inserted `:server` and did not duplicate `:welcome`
      assert entry.pages == setup.pages ++ [:server]
    end
  end
end
