defmodule Helix.Client.Web1.Internal do

  alias Helix.Entity.Model.Entity
  alias Helix.Client.Repo
  alias Helix.Client.Web1.Model.Setup

  @type repo_result ::
    {:ok, Setup.t}
    | {:error, Setup.changeset}

  @spec fetch_setup(Entity.id) ::
    Setup.t
    | nil
  @doc false
  def fetch_setup(entity_id) do
    entity_id
    |> Setup.Query.by_entity()
    |> Repo.one()
  end

  @spec create_setup(Entity.id, [Setup.page]) ::
    repo_result
  @doc """
  Inserts a new Setup entry corresponding to the `entity_id` and the initial
  `pages` passed as arguments.
  """
  def create_setup(entity_id, pages) do
    %{
      entity_id: entity_id,
      pages: pages
    }
    |> Setup.create_changeset()
    |> Repo.insert()
  end

  @spec add_setup_pages(Setup.t, [Setup.page]) ::
    repo_result
  @doc """
  Appends the new pages into the Setup.t entry.

  Will remove any repeated entries.
  """
  def add_setup_pages(setup, pages) do
    setup
    |> Setup.add_pages(pages)
    |> Repo.update()
  end

  @spec get_setup_pages(Entity.id) ::
    [Setup.page]
  @doc """
  Returns all pages that the `entity` has already interacted with on the setup
  """
  def get_setup_pages(entity_id) do
    pages =
      entity_id
      |> Setup.Query.by_entity()
      |> Setup.Select.pages()
      |> Repo.one()

    # `Repo.one` with `select` returns a list of a list of pages
    if pages do
      pages |> List.first()
    else
      []
    end
  end
end
