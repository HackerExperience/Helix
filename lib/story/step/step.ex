defmodule Helix.Story.Step do
  @moduledoc """
  TODO
  """

  alias HELL.Constant
  alias Helix.Event
  alias Helix.Entity.Model.Entity

  @type email_id :: String.t
  @type reply_id :: String.t

  @type email ::
    %{
      id: email_id,
      replies: [reply_id],
      locked: [reply_id]
    }

  @type emails ::
    %{
      email_id => email
    }

  @type meta :: map

  @type step_name :: Constant.t

  @type t(struct) :: %{
    __struct__: struct,
    event: Event.t,
    step: step_name,
    meta: meta,
    entity_id: Entity.id
  }

  @spec new(String.t, Event.t) ::
    t(struct)
  @doc """
  Given the raw step name fetched from the Database (string, on the format
  `mission_name@step_name`), figures out the corresponding Elixir module and
  calls the `new` function, which will return a valid Step struct.
  """
  def new(raw_step, event) do
    module_str =
      raw_step
      |> String.split("@")
      |> Enum.map(&Macro.camelize/1)
      |> Enum.join(".")

    "Elixir.Helix.Story.Mission." <>  module_str
    |> String.to_atom()
    |> apply(:new, [event])
  end

  @spec get_step_name(elixir_module :: Constant.t) ::
    step_name
  @doc """
  The module name format is `:Elixir.Helix.Some.Thing.MissionName.StepName`.

  We process it to return the step name, which is `:mission_name@step_name`.
  """
  def get_step_name(module) do
    module
    |> Atom.to_string()
    |> String.split(".")
    |> Enum.take(-2)
    |> Enum.map(&Macro.underscore/1)
    |> Enum.join("@")
    |> String.to_atom()
  end

  @spec get_entity(Event.t) ::
    Entity.id
  @doc """
  Given an event, figure out which entity is responsible for it.
  """
  def get_entity(%_{source_entity_id: entity_id}),
    do: entity_id

  defmacro register do
    step_name =
      quote do
        @step_name Helix.Story.Step.get_step_name(__MODULE__)
      end

    type =
      quote do
        @type t :: Helix.Story.Step.t(__MODULE__)
      end

    struct =
      quote do
        @enforce_keys [:step, :event, :entity_id]
        defstruct [:step, :event, :entity_id, meta: %{}]
      end

    new =
      quote do
        @spec new(Helix.Event.t) :: t
        def new(event) do
          %__MODULE__{
            step: @step_name,
            event: event,
            entity_id: Helix.Story.Step.get_entity(event)
          }
        end
      end

    [step_name, type, struct, new]
  end
end
