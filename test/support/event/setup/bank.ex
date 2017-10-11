defmodule Helix.Test.Event.Setup.Bank do

  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias Helix.Universe.Bank.Event.Bank.Account.Login,
    as: BankAccountLoginEvent
  alias Helix.Universe.Bank.Event.Bank.Account.Password.Revealed,
    as: BankAccountPasswordRevealedEvent
  alias Helix.Universe.Bank.Event.Bank.Account.Token.Acquired,
    as: BankAccountTokenAcquiredEvent

  @doc """
  Accepts: (Token.id, BankAccount.t, Entity.id)
  """
  def token_acquired(token_id, acc, entity_id) do
    token_id
    |> BankQuery.fetch_token()
    |> token_acquired(acc, entity_id, token_id)
  end

  defp token_acquired(token = %BankToken{}, acc, entity_id, _),
    do: BankAccountTokenAcquiredEvent.new(acc, token, entity_id)

  # fake BankAccount/BankToken being tested
  defp token_acquired(nil, acc, entity_id, token_id) do
    %BankAccountTokenAcquiredEvent{
      entity_id: entity_id,
      account: acc,
      token: %{token_id: token_id}
    }
  end

  @doc """
  Accepts: (BankAccount.t, Entity.id)
  - password: Set event password. If not set, use the same one on the account
  """
  def password_revealed(account, entity_id, opts \\ []) do
    password = Keyword.get(opts, :password, account.password)

    event = BankAccountPasswordRevealedEvent.new(account, entity_id)

    # Inject the user-requested password. "noop" if no change was requested.
    account = %{event.account| password: password}

    %{event| account: account}
  end

  @doc """
  Accepts: (BankAccount.t, Entity.id)
  """
  def login(account, entity_id, token_id \\ nil),
    do: BankAccountLoginEvent.new(account, entity_id, token_id)
end
