defprotocol Helix.Story.Steppable do

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Story.Step

  @type generic_step :: Step.t(struct)

  @spec setup(Entity.id, generic_step) ::
    term
  def setup(entity_id, previous_step)

  @spec handle_event(generic_step, Event.t, Step.meta) ::
    {:complete, generic_step}
    | {:fail, generic_step}
    | {:noop, generic_step}
  def handle_event(step, event, meta)

  @spec complete(generic_step) ::
    {:ok, generic_step}
    | {:error, generic_step}
  def complete(step)

  @spec fail(generic_step) ::
    {:ok, generic_step}
  def fail(step)

  @spec next_step(generic_step) ::
    Step.step_name
  def next_step(step)

end
