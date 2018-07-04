defmodule Helix.Client.Web1.Internal.SetupTest do

  use Helix.Test.Case.Integration

  alias Helix.Client.Web1.Internal.Setup, as: SetupInternal

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Client.Web1.Setup, as: Web1Setup

  describe "create/2" do
    test "entry is inserted on the DB" do
      entity_id = EntityHelper.id()
      pages = [:welcome]

      assert {:ok, setup} = SetupInternal.create(entity_id, pages)

      assert setup.entity_id == entity_id
      assert setup.pages == pages
    end

    test "rejects invalid page" do
      assert {:error, changeset} =
        SetupInternal.create(EntityHelper.id(), [:welcome, :bad])

      refute changeset.valid?
      assert :pages in Keyword.keys(changeset.errors)
    end
  end

  describe "fetch/1" do
    test "returns the entry" do
      {setup, _} = Web1Setup.setup()

      assert setup == SetupInternal.fetch(setup.entity_id)
    end
  end

  describe "get_pages/1" do
    test "returns only the pages" do
      {setup, _} = Web1Setup.setup()

      pages = SetupInternal.get_pages(setup.entity_id)

      assert pages == setup.pages
    end
  end

  describe "add_pages" do
    test "appends new pages without duplicates" do
      {setup, _} = Web1Setup.setup(pages: [:welcome])

      {:ok, entry} = SetupInternal.add_pages(setup, [:welcome, :server])

      # Inserted `:server` and did not duplicate `:welcome`
      assert entry.pages == setup.pages ++ [:server]
    end
  end
end
