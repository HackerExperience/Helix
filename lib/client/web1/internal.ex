defmodule Helix.Client.Web1.Internal do

  alias Helix.Client.Repo
  alias Helix.Client.Web1.Model.Setup

  def get_setup_pages(entity_id) do
    entity_id
    |> Setup.Query.by_entity()
    |> Setup.Select.pages()
    |> Repo.all()
  end
end
