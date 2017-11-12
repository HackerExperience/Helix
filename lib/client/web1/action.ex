defmodule Helix.Client.Web1.Action do

  alias Helix.Entity.Model.Entity
  alias Helix.Client.Web1.Internal, as: Web1Internal
  alias Helix.Client.Web1.Model.Setup
  alias Helix.Client.Web1.Query, as: Web1Query

  @typep setup_result ::
    {:ok, Setup.t}
    | {:error, :internal}

  @doc """
  Saves the list of Setup pages `entity_id` went through.
  """
  @spec add_setup_pages(Entity.id, [Setup.page]) ::
    setup_result
  def add_setup_pages(entity_id, pages) do
    case Web1Query.fetch_setup(entity_id) do
      setup = %{} ->
        setup
        |> Web1Internal.add_setup_pages(pages)
        |> handle_setup_result()

      nil ->
        entity_id
        |> Web1Internal.create_setup(pages)
        |> handle_setup_result
    end
  end

  @spec handle_setup_result(Web1Internal.repo_result) ::
    setup_result
  defp handle_setup_result({:ok, setup}),
    do: {:ok, setup}
  defp handle_setup_result({:error, _}),
    do: {:error, :internal}
end
