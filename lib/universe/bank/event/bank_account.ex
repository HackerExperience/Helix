defmodule Helix.Universe.Bank.Event.BankAccount do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Universe.Bank.Model.BankAccount.RevealPassword.ConclusionEvent,
    as: RevealPasswordConclusionEvent

  @doc """
  Handles the conclusion of a PasswordReveal process, described at
  `BankAccountFlow`. Note that actually *displaying* the password to the user
  only happens with the BankAccountPasswordRevealedEvent, since the conclusion
  of the `PasswordReveal` process does not imply that the password has been
  revealed (since the given input may be invalid).
  """
  def password_reveal_conclusion(event = %RevealPasswordConclusionEvent{}) do
    flowing do
      with \
        account = %{} <-
          BankQuery.fetch_account(event.atm_id, event.account_number),
        revealed_by = %{} <- EntityQuery.fetch_by_server(event.gateway_id),
        {:ok, _password, events} <-
          BankAction.reveal_password(account, event.token_id, revealed_by),
        on_success(fn -> Event.emit(events) end)
      do
        :ok
      end
    end
  end
end
