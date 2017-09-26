defprotocol Helix.Story.Model.Steppable do

  alias Helix.Event
  alias Helix.Story.Model.Step

  @type generic_step :: Step.t(struct)

  @spec setup(current_step :: generic_step, previous_step :: generic_step) ::
    {:ok, generic_step, [Event.t]}
  def setup(step, previous_step)

  @spec handle_event(generic_step, Event.t, Step.meta) ::
    {:complete | :fail | :noop, generic_step, [Event.t]}
  def handle_event(step, event, meta)

  @spec complete(generic_step) ::
    {:ok | :error, generic_step, [Event.t]}
  def complete(step)

  @spec fail(generic_step) ::
    {:ok, generic_step, [Event.t]}
  def fail(step)

  @spec next_step(generic_step) ::
    Step.step_name
  def next_step(step)

  @spec get_contact(generic_step) ::
    Step.contact
  def get_contact(step)

  @spec format_meta(generic_step) ::
    Step.meta
  def format_meta(step)

  @spec get_replies(generic_step, Step.email_id) ::
    [Step.reply_id]
  def get_replies(step, email_id)
end
