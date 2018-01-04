defmodule Helix.Test.Entity.Setup do

  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery

  alias Helix.Test.Account.Setup, as: AccountSetup

  def entity!(opts \\ []) do
    {entity, _} = entity(opts)
    entity
  end

  @doc """
  Opts:
  - type: account | npc (TODO). Defaults to generating an account entity.
  """
  def entity(opts \\ [])

  def entity(from_account: account) do
    {:ok, entity, _} = EntityAction.create_from_specialization(account)

    {entity, %{}}
  end

  def entity(opts) do
    if opts[:type] do
      raise "todo"
    else
      {:ok, entity, _} =
        AccountSetup.account!()
        |> EntityAction.create_from_specialization()

      {entity, %{}}
    end
  end

  @doc """
  Helper to create_or_fetch entities in a single command. Specially important
  given the `get_entity_id` prone to change/removal.
  """
  def create_or_fetch(nil),
    do: entity!()
  def create_or_fetch(entity_id) do
    entity_id
    |> EntityQuery.get_entity_id()
    |> EntityQuery.fetch()
  end

  def id,
    do: Entity.ID.generate()
end
