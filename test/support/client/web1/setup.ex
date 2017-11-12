defmodule Helix.Test.Client.Web1.Setup do

  alias Helix.Entity.Model.Entity
  alias Helix.Client.Web1.Model.Setup
  alias Helix.Client.Repo, as: ClientRepo

  alias Helix.Test.Client.Web1.Helper, as: Web1Helper

  @doc """
  See doc on `fake_setup/1`
  """
  def setup(opts \\ []) do
    {changeset, related} = fake_setup(opts)
    {:ok, inserted} = ClientRepo.insert(changeset)
    {inserted, related}
  end

  @doc """
  Opts:
  - entity_id: Specify the entity_id. Fake one is generated by default.
  - pages: List of pages to be inserted. Select random pages by default.

  Related:
  - Setup.creation_params
  """
  def fake_setup(opts \\ []) do

    entity_id = Keyword.get(opts, :entity_id, Entity.ID.generate())
    pages = Keyword.get(opts, :pages, Web1Helper.random_pages())

    params =
      %{
        entity_id: entity_id,
        pages: pages
      }

    changeset = Setup.create_changeset(params)

    related = %{params: params}

    {changeset, related}
  end
end

defmodule Helix.Test.Client.Web1.Helper do

  def random_pages do
    # Guaranteed to be random
    [:welcome]
  end

end
