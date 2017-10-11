defmodule Helix.Universe.Bank.Event.Handler.Bank.Account do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Event.RevealPassword.Processed,
    as: RevealPasswordProcessedEvent

  @doc """
  Handles the conclusion of a PasswordReveal process, described at
  `BankAccountFlow`. Note that actually *displaying* the password to the user
  only happens with the BankAccountPasswordRevealedEvent, since the conclusion
  of the `PasswordReveal` process does not imply that the password has been
  revealed (since the given input may be invalid).

  Emits: BankAccountPasswordRevealedEvent
  """
  def password_reveal_processed(event = %RevealPasswordProcessedEvent{}) do
    flowing do
      with \
        revealed_by = %{} <- EntityQuery.fetch_by_server(event.gateway_id),
        {:ok, _password, events} <-
          BankAction.reveal_password(
            event.account,
            event.token_id,
            revealed_by.entity_id
          ),
        on_success(fn -> Event.emit(events) end)
      do
        :ok
      end
    end
  end
end
