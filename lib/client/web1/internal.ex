defmodule Helix.Client.Web1.Internal do

  alias Helix.Client.Repo
  alias Helix.Client.Web1.Model.Setup

  def add_setup_pages(setup, pages) do
    setup
    |> Setup.add_pages(pages)
    |> update()
  end

  def get_setup_pages(entity_id) do
    entity_id
    |> Setup.Query.by_entity()
    |> Setup.Select.pages()
    |> Repo.all()
  end

  defp update(changeset) do
    changeset
    |> Repo.update()
  end
end
