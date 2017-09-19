defmodule Helix.Story.Query.Story do

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Internal.Step, as: StepInternal
  alias Helix.Story.Model.Step

  @spec fetch_current_step(Entity.id) ::
    Spec.t(struct)
    | nil
  def fetch_current_step(entity_id) do
    with %{name: name, meta: meta} <- current_step_data(entity_id) do
      Step.fetch(name, entity_id, meta)
    end
  end

  @spec current_step_data(Entity.id) ::
    %{name: Step.step_name, meta: Step.meta}
    | nil
  def current_step_data(entity_id) do
    with step = %{} <- StepInternal.current_step_data(entity_id) do
      %{name: step.step_name, meta: step.meta}
    end
  end

  def get_emails(entity_id) do
    EmailInternal.get_emails(entity_id)
  end
end
