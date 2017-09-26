defmodule Helix.Story.Model.Step do
  @moduledoc """
  TODO
  """

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
  Given the raw step name fetched from the Database (string, on the format
  `mission_name@step_name`), figures out the corresponding Elixir module and
  calls the `new` function, which will return a valid Step struct.
  """
  def new(%{entity_id: entity_id, name: step_name, meta: meta}, event) do
    step_name
    |> get_module()
    |> apply(:new, [entity_id, meta, event])
  end

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
  def get_contact(step),
    do: Steppable.get_contact(step)

  @spec get_replies(t(struct), email_id) ::
    [reply_id]
  def get_replies(step, email),
    do: Steppable.get_replies(step, email)

  @spec get_next_step(t(struct)) ::
    step_name
  def get_next_step(step),
    do: Steppable.next_step(step)

  @spec get_module(step_name) ::
    step_module :: Constant.t
  def get_module(step_name) do
    module_str =
      step_name
      |> Atom.to_string()
      |> String.split("@")
      |> Enum.map(&Macro.camelize/1)
      |> Enum.join(".")

    "Elixir.Helix.Story.Model.Mission." <>  module_str
    |> String.to_atom()
  end

  @spec get_entity(Event.t) ::
    Entity.id
  @doc """
  Given an event, figure out which entity is responsible for it.
  """
  def get_entity(%_{entity_id: entity_id}),
    do: entity_id
  def get_entity(%_{source_entity_id: entity_id}),
    do: entity_id

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
