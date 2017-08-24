defmodule Helix.Entity.Event.Database do

  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Entity.Action.Database, as: DatabaseAction

  alias Helix.Software.Model.Software.Cracker.Bruteforce.ConclusionEvent,
    as: CrackerBruteforceConclusionEvent
  alias Helix.Universe.Bank.Model.BankAccount.PasswordRevealedEvent,
    as: BankAccountPasswordRevealedEvent
  alias Helix.Universe.Bank.Model.BankAccount.LoginEvent,
    as: BankAccountLoginEvent
  alias Helix.Universe.Bank.Model.BankTokenAcquiredEvent

  def cracker_conclusion(_event = %CrackerBruteforceConclusionEvent{}) do
    # entity = EntityQuery.fetch(event.entity_id)
    # server = ServerQuery.fetch(event.server_id)
    # server_ip = ServerQuery.get_ip(event.server_id, event.network_id)

    # create_entry = fn ->
    #   DatabaseAction.add_server(
    #     entity,
    #     event.network_id,
    #     event.server_ip,
    #     server,
    #     event.server_type)
    # end

    # # Review: Why is it updating everyone's password?
    # set_password = fn ->
    #   entity
    #   |> DatabaseQuery.get_server_entries(server)
    #   |> Enum.each(&DatabaseAction.update(&1, %{password: server.password}))
    # end

    # if to_string(server_ip) == to_string(event.server_ip) do
    #   Repo.transaction fn ->
    #     {:ok, _} = create_entry.()
    #     :ok = set_password.()
    #   end
    # end
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
    account = BankQuery.fetch_account(event.atm_id, event.account_number)

    DatabaseAction.update_bank_password(
      event.entity_id,
      account,
      event.password)
  end

  @doc """
  Handler called when a BankToken is successfully acquired, after an Overflow
  attack. Its goal is simple: store the new token on the Hacked Database.
  """
  def bank_token_acquired(event = %BankTokenAcquiredEvent{}) do
    account = BankQuery.fetch_account(event.atm_id, event.account_number)

    DatabaseAction.update_bank_token(event.entity_id, account, event.token_id)
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
      event.token_id)
  end
end
