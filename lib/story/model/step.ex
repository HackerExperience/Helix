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
  alias Helix.Story.Model.Story

  @type t ::
    %{
      __struct__: atom,
      event: Event.t | nil,
      name: step_name,
      meta: meta,
      entity_id: Entity.id,
      manager: Story.Manager.t,
      contact: contact | nil
    }

  @type email_id :: String.t
  @type reply_id :: String.t

  @type message ::
    %{
      id: email_id,
      replies: [reply_id],
      locked: [reply_id]
    }

  @type emails :: %{email_id => message}
  @type replies :: %{reply_id => message}

  @type email_meta :: map

  @type meta :: map
  @type name :: step_name
  @type step_name :: Constant.t
  @type contact :: Constant.t
  @type contact_id :: contact

  @typedoc """
  The `callback_action` type lists all possible actions that may be applied to
  a step. Notably, one of them must be returned by `Steppable.handle_event/3`,
  but it's also used in other contexts, including on `StepActionRequestedEvent`.

  The action will be interpreted and applied at the StoryHandler.

  Note that `:restart` also includes metadata (`reason` and `checkpoint`).
  """
  @type callback_action ::
    :complete
    | {:complete, send_opts}
    | {:restart, reason :: atom, checkpoint :: email_id}
    | {:send_email, email_id, email_meta, send_opts}
    | {:send_reply, reply_id, send_opts}
    | :noop

  @type send_opts :: list

  @spec new(t, Event.t) ::
    t
  @doc """
  Returns a new step struct with the given event assigned to it.
  """
  def new(step, event) do
    step.name
    |> get_module()
    |> apply(:new, [step.entity_id, step.meta, step.manager, event])
  end

  @spec fetch(step_name, Entity.id, meta, Story.Manager.t) ::
    t
  @doc """
  Given a step raw name (string), return its struct, assigning the correct
  entity and meta to it.
  """
  def fetch(step_name, entity_id, meta, manager) do
    step_name
    |> get_module()
    |> apply(:new, [entity_id, meta, manager])
  end

  @spec first(Entity.id, Story.Manager.t) ::
    t
  @doc """
  Creates the first step (used after player account is created and verified)
  """
  def first(entity_id, manager),
    do: fetch(first_step_name(), entity_id, %{}, manager)

  @spec first_step_name() ::
    atom
  @doc """
  Returns the name of the first mission
  """
  def first_step_name,
    do: :tutorial@setup_pc

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

  @spec get_contact(t) ::
    contact
  @doc """
  Returns the Step contact id.
  """
  def get_contact(step),
    do: Steppable.get_contact(step)

  @spec get_emails(t) ::
    emails
  @doc """
  Returns a list of all available emails
  """
  def get_emails(step),
    do: Steppable.get_emails(step)

  @spec email_exists?(t, email_id) ::
    boolean
  @doc """
  Checks whether the given `email_id` exists
  """
  def email_exists?(step, email_id) do
    step
    |> get_emails()
    |> Enum.any?(fn {id, _} -> id == email_id end)
  end

  @spec get_replies_of(t, email_id) ::
    [reply_id]
  @doc """
  Returns the unlocked replies of the given email.
  """
  def get_replies_of(step, email),
    do: Steppable.get_replies_of(step, email)

  @spec get_next_step(t) ::
    step_name
  @doc """
  Returns the next step name.
  """
  def get_next_step(step),
    do: Steppable.next_step(step)

  @spec format_meta(t) ::
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
    alias Helix.Story.Model.Story

    type =
      quote do
        @type t :: Step.t
      end

    struct =
      quote do
        @enforce_keys [:name, :contact, :event, :entity_id, :manager]
        defstruct [:name, :contact, :event, :entity_id, :manager, meta: %{}]
      end

    new =
      quote do

        @spec new(Entity.id, Step.meta, Story.Manager.t) :: t
        def new(entity_id, meta, manager) do
          step =
            %__MODULE__{
              name: Step.get_name(__MODULE__),
              entity_id: entity_id,
              event: nil,
              meta: meta,
              manager: manager,
              contact: :placeholder
            }

          %{step| contact: Step.get_contact(step)}
        end

        @spec new(Entity.id, Step.meta, Story.Manager.t, Helix.Event.t) :: t
        def new(entity_id, meta, manager, event) do
          step =
            %__MODULE__{
              name: Step.get_name(__MODULE__),
              event: event,
              entity_id: entity_id,
              meta: meta,
              manager: manager,
              contact: :placeholder
            }

          %{step| contact: Step.get_contact(step)}
        end
      end

    [type, struct, new]
  end
end
