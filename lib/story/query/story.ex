defmodule Helix.Story.Query.Story do

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Internal.Email, as: EmailInternal
  alias Helix.Story.Internal.Step, as: StepInternal
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Story

  @spec fetch_step(Entity.id, Step.contact) ::
    StepInternal.step_info
    | nil
  @doc """
  Returns the current step of the player, both the Story.Step entry and the Step
  struct, which we are calling `object`.

  The returned metadata is using Helix internal data structures.
  """
  defdelegate fetch_step(entity_id, contact_id),
    to: StepInternal

  @spec get_steps(Entity.id) ::
    [StepInternal.step_info]
  @doc """
  Returns all steps that `entity_id` is currently at.

  Result is formatted as `step_info`.
  """
  defdelegate get_steps(entity_id),
    to: StepInternal

  @spec fetch_email(Entity.id, Step.contact) ::
    Story.Email.t
    | nil
  @doc """
  Fetches all emails from a given contact.
  """
  defdelegate fetch_email(entity_id, contact_id),
    to: EmailInternal,
    as: :fetch

  @spec get_emails(Entity.id) ::
    [Story.Email.t]
  @doc """
  Returns all emails from all contacts that Entity has ever interacted with.
  """
  defdelegate get_emails(entity_id),
    to: EmailInternal
end
