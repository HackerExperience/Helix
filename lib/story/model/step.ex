defmodule Helix.Story.Model.Step do
  @moduledoc """
  `Step` is a generic model for all steps, using the Steppable protocol as
  wrapper.

  For the most part, you probably want to read the Steppable documentation at
  `lib/story/model/steppable.ex`
  """

  import HELL.Macros

  alias HELL.Constant
  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Story.Model.Steppable

  @type email_id :: String.t
  @type reply_id :: String.t

  @type email ::
    %{
      id: email_id,
      replies: [reply_id],
      locked: [reply_id]
    }

  @type email_meta :: map

  @type emails ::
    %{
      email_id => email
    }

  @type meta :: map

  @type step_name :: Constant.t

  @type contact :: Constant.t

  @type t(step_type) :: %{
    __struct__: step_type,
    event: Event.t | nil,
    name: step_name,
    meta: meta,
    entity_id: Entity.id
  }

  @spec new(t(struct), Event.t) ::
    t(struct)
  @doc """
  Returns a new step struct with the given event assigned to it.
  """
  def new(%{entity_id: entity_id, name: step_name, meta: meta}, event) do
    step_name
    |> get_module()
    |> apply(:new, [entity_id, meta, event])
  end

  @spec fetch(step_name, Entity.id, meta) ::
    t(struct)
  @doc """
  Given a step raw name (string), return its struct, assigning the correct
  entity and meta to it.
  """
  def fetch(step_name, entity_id, meta) do
    step_name
    |> get_module()
    |> apply(:new, [entity_id, meta])
  end

  @spec get_name(step_module :: Constant.t) ::
    step_name
  @doc """
  The module name format is `:Elixir.Helix.Some.Thing.MissionName.StepName`.

  We process it to return the step name, which is `:mission_name@step_name`.
  """
  def get_name(module) do
    module
    |> Atom.to_string()
    |> String.split(".")
    |> Enum.take(-2)
    |> Enum.map(&Macro.underscore/1)
    |> Enum.join("@")
    |> String.to_atom()
  end

  @spec get_contact(t(struct)) ::
    contact
  @doc """
  Returns the Step contact id.
  """
  def get_contact(step),
    do: Steppable.get_contact(step)

  @spec get_replies(t(struct), email_id) ::
    [reply_id]
  @doc """
  Returns the unlocked replies of the given email.
  """
  def get_replies(step, email),
    do: Steppable.get_replies(step, email)

  @spec get_next_step(t(struct)) ::
    step_name
  @doc """
  Returns the next step name.
  """
  def get_next_step(step),
    do: Steppable.next_step(step)

  @spec format_meta(t(struct)) ::
    meta
  @doc """
  Formats the step metadata to Helix internal data structures.
  """
  def format_meta(step),
    do: Steppable.format_meta(step)

  @spec get_module(step_name) ::
    step_module :: Constant.t
  docp """
  Returns the Elixir module (atom) to be used by `new/2` and `fetch/3`
  """
  defp get_module(step_name) do
    module_str =
      step_name
      |> Atom.to_string()
      |> String.split("@")
      |> Enum.map(&Macro.camelize/1)
      |> Enum.join(".")

    "Elixir.Helix.Story.Mission." <>  module_str
    |> String.to_atom()
  end

  @spec get_entity(Event.t) ::
    Entity.id
    | false
  @doc """
  Given an event, figure out which entity is responsible for it.

  If no entity_id is found, returns `false`, since an event lacking an
  identifiable entity cannot not be filtered by Steppable.
  """
  def get_entity(%_{entity_id: entity_id}),
    do: entity_id
  def get_entity(%_{source_entity_id: entity_id}),
      do: entity_id
  def get_entity(_),
    do: false

  defmacro register do

    alias Helix.Entity.Model.Entity
    alias Helix.Story.Model.Step

    type =
      quote do
        @type t :: Step.t(__MODULE__)
      end

    struct =
      quote do
        @enforce_keys [:name, :event, :entity_id]
        defstruct [:name, :event, :entity_id, meta: %{}]
      end

    new =
      quote do

        @spec new(Entity.id, Step.meta) :: t
        def new(entity_id, meta) do
          %__MODULE__{
            name: Step.get_name(__MODULE__),
            entity_id: entity_id,
            event: nil,
            meta: meta
          }
        end

        @spec new(Entity.id, Step.meta, Helix.Event.t) :: t
        def new(entity_id, meta, event) do
          %__MODULE__{
            name: Step.get_name(__MODULE__),
            event: event,
            entity_id: entity_id,
            meta: meta
          }
        end
      end

    [type, struct, new]
  end
end
