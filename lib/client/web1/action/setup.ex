defmodule Helix.Client.Web1.Action.Setup do

  alias Helix.Entity.Model.Entity
  alias Helix.Client.Web1.Internal.Setup, as: SetupInternal
  alias Helix.Client.Web1.Model.Setup
  alias Helix.Client.Web1.Query.Setup, as: SetupQuery

  @typep result ::
    {:ok, Setup.t}
    | {:error, :internal}

  @doc """
  Saves the list of Setup pages `entity_id` went through.
  """
  @spec add_pages(Entity.id, [Setup.page]) ::
    result
  def add_pages(entity_id, pages) do
    case SetupQuery.fetch(entity_id) do
      setup = %{} ->
        setup
        |> SetupInternal.add_pages(pages)
        |> handle_result()

      nil ->
        entity_id
        |> SetupInternal.create(pages)
        |> handle_result
    end
  end

  @spec handle_result(SetupInternal.repo_result) ::
    result
  defp handle_result({:ok, setup}),
    do: {:ok, setup}
  defp handle_result({:error, _}),
    do: {:error, :internal}
end
