defmodule Helix.Entity.Event.Handler.Database do

  alias Helix.Entity.Action.Database, as: DatabaseAction
  alias Helix.Entity.Query.Entity, as: EntityQuery

  alias Helix.Server.Event.Server.Password.Acquired,
    as: ServerPasswordAcquiredEvent
  alias Helix.Universe.Bank.Event.Bank.Account.Password.Revealed,
    as: BankAccountPasswordRevealedEvent
  alias Helix.Universe.Bank.Event.Bank.Account.Login,
    as: BankAccountLoginEvent
  alias Helix.Universe.Bank.Event.Bank.Account.Token.Acquired,
    as: BankAccountTokenAcquiredEvent

  @doc """
  Handler called when a BruteforceProcess has finished and the target server
  password has been acquired.

  This handler goal is to update the attacker's database with the recently
  obtained password.
  """
  def server_password_acquired(event = %ServerPasswordAcquiredEvent{}) do
    entity = EntityQuery.fetch(event.entity_id)

    DatabaseAction.update_server_password(
      entity,
      event.network_id,
      event.server_ip,
      event.server_id,
      event.password
    )
  end

  @doc """
  Handler called when a BankPassword is revealed. This usually happens when an
  attacker, in possession of the corresponding BankToken, converts the token
  into a password. The conversion is a process of type `bank_reveal_password`.

  Note that this handler is only called after the `bank_reveal_password`
  process has finished and successfully revealed the password. Hence, this
  handler's goal is to store the newly discovered password into the Database.
  """
  def bank_password_revealed(event = %BankAccountPasswordRevealedEvent{}) do
    DatabaseAction.update_bank_password(
      event.entity_id,
      event.account,
      event.account.password
    )
  end

  @doc """
  Handler called when a BankToken is successfully acquired, after an Overflow
  attack. Its goal is simple: store the new token on the Hacked Database.
  """
  def bank_token_acquired(event = %BankAccountTokenAcquiredEvent{}) do
    DatabaseAction.update_bank_token(
      event.entity_id,
      event.account,
      event.token.token_id
    )
  end

  @doc """
  Handler called after a bank account login happens. Its main goal is to make
  sure the Hacked Database is updated to reflect that account information.
  Note that currently there are two methods for login: using password or token.
  """
  def bank_account_login(event = %BankAccountLoginEvent{}) do
    DatabaseAction.update_bank_login(
      event.entity_id,
      event.account,
      event.token_id
    )
  end
end
