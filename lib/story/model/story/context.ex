defmodule Helix.Story.Model.Story.Context do

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias HELL.MapUtils
  alias Helix.Entity.Model.Entity
  alias Helix.Story.Model.Story

  @type t ::
    %__MODULE__{
      entity_id: Entity.id,
      context: context
    }

  @type value :: term
  @type context :: map
  @type entry :: context
  @type path :: [key]
  @type key :: atom

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type creation_params :: %{entity_id: Entity.id}

  @typep context_id ::
    %{
      __id__: String.t,
      __root__: String.t
    }

  @creation_fields [:entity_id]
  @required_fields [:entity_id]

  @primary_key false
  schema "story_contexts" do
    field :entity_id, Entity.ID,
      primary_key: true

    field :context, :map,
      default: %{}
  end

  @spec create(creation_params) ::
    changeset
  def create(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  @spec merge_context(context, entry) ::
    context
  @doc """
  Merges the current existing context with the new entry requested by the user.

  If a conflict happens, the new entry takes precedence (overwrites the old one)
  """
  def merge_context(context, entry),
    do: MapUtils.naive_deep_merge(context, entry, fn _a, b -> b end)

  @spec update(t, entry) ::
    changeset
  def update(story_context = %Story.Context{}, entry) do
    new_context = merge_context(story_context.context, entry)

    story_context
    |> change()
    |> put_change(:context, new_context)
  end

  @spec format(t) ::
    t
  def format(story_context = %Story.Context{}) do
    formatted_context =
      story_context.context
      |> MapUtils.atomize_keys()
      |> format_ids()

    %{story_context| context: formatted_context}
  end

  @spec format_ids(term) ::
    context
  defp format_ids(%{__id__: id, __root__: root}) do
    root
    |> Kernel.<>(".ID")
    |> String.to_atom()
    |> apply(:cast!, [id])
  end
  defp format_ids(context = %{}) do
    context
    |> Enum.map(fn {k, v} -> {k, format_ids(v)} end)
    |> Enum.into(%{})
  end
  defp format_ids(not_id),
    do: not_id

  @spec store_id(struct) ::
    context_id
  def store_id(id = %_{id: _, root: module}) do
    %{
      __id__: to_string(id),
      __root__: to_string(module)
    }
  end

  query do

    alias Helix.Story.Model.Story

    @spec by_entity(Queryable.t, Entity.id) ::
      Queryable.t
    def by_entity(query \\ Story.Context, entity_id),
      do: where(query, [sc], sc.entity_id == ^entity_id)

    @spec lock_for_update(Queryable.t) ::
      Queryable.t
    def lock_for_update(query),
      do: lock(query, "FOR UPDATE")
  end
end
