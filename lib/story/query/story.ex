defmodule Helix.Story.Query.Story do

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Internal.Email, as: EmailInternal
  alias Helix.Story.Internal.Step, as: StepInternal
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Story

  @spec fetch_current_step(Entity.id) ::
    %{
      object: Step.t(struct),
      entry: Story.Step.t
    }
    | nil
  @doc """
  Returns the current step of the player, both the Story.Step entry and the Step
  struct, which we are calling `object`.

  The returned metadata is using Helix internal data structures.
  """
  defdelegate fetch_current_step(entity_id),
    to: StepInternal

  @spec get_emails(Entity.id) ::
    [Story.Email.t]
  @doc """
  Returns all emails from all contacts that Entity has ever interacted with.
  """
  defdelegate get_emails(entity_id),
    to: EmailInternal
end
