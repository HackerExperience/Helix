defmodule Helix.Story.Step do
  @moduledoc """
  TODO
  """

  alias HELL.Constant
  alias Helix.Event

  @type t(struct) :: %{
    __struct__: struct,
    event: Event.t,
    step: Constant.t,
    meta: map
  }

  @spec new(String.t, Event.t) ::
    t(term)
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
    step_name :: Constant.t
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
        @enforce_keys [:event]
        defstruct [:step, :event, meta: %{}]
      end

    new =
      quote do
        @spec new(Helix.Event.t) :: t
        def new(event) do
          %__MODULE__{
            step: @step_name,
            event: event
          }
        end
      end

    [step_name, type, struct, new]
  end
end
