defmodule Helix.Test.Event.Setup do

  alias Helix.Network.Model.Connection
  alias Helix.Process.Model.Process

  alias Helix.Network.Model.Connection.ConnectionClosedEvent
  alias Helix.Software.Model.SoftwareType.Cracker.Overflow.ConclusionEvent,
    as: OverflowConclusionEvent
  alias Helix.Universe.Bank.Model.BankTokenAcquiredEvent
  alias Helix.Universe.Bank.Model.BankAccount.LoginEvent,
    as: BankAccountLoginEvent
  alias Helix.Universe.Bank.Model.BankAccount.PasswordRevealedEvent,
    as: BankAccountPasswordRevealedEvent

  alias Helix.Test.Network.Helper, as: NetworkHelper

  @internet NetworkHelper.internet_id()

  @doc """
  Accepts: Connection.t

  - network_id: Defaults to the internet
  - reason: Defaults to `:normal`
  """
  def connection_closed(conn = %Connection{}, opts \\ []) do
    network_id = Access.get(opts, :network_id, @internet)
    reason = Access.get(opts, :reason, :normal)

    %ConnectionClosedEvent{
      connection_id: conn.connection_id,
      network_id: network_id,
      tunnel_id: conn.tunnel_id,
      meta: conn.meta,
      reason: reason,
      connection_type: conn.connection_type
    }
  end

  @doc """
  Accepts: Process.t
  """
  def overflow_conclusion(process = %Process{}) do
    %OverflowConclusionEvent{
      gateway_id: process.gateway_id,
      target_process_id: process.process_id
    }
  end

  @doc """
  Accepts: (Token.id, BankAccount.t, Entity.id)
  """
  def bank_token_acquired(token_id, acc, entity_id) do
    %BankTokenAcquiredEvent{
      entity_id: entity_id,
      token_id: token_id,
      atm_id: acc.atm_id,
      account_number: acc.account_number
    }
  end

  @doc """
  Accepts: (BankAccount.t, Entity.id)
  - password: Set event password. If not set, use the same one on the account
  """
  def bank_account_password_revealed(account, entity_id, opts \\ []) do
    password = Access.get(opts, :password, account.password)
    %BankAccountPasswordRevealedEvent{
      entity_id: entity_id,
      account_number: account.account_number,
      atm_id: account.atm_id,
      password: password
    }
  end

  @doc """
  Accepts: (BankAccount.t, Entity.id)
  """
  def bank_account_login(account, entity_id, token_id \\ nil) do
    %BankAccountLoginEvent{
      entity_id: entity_id,
      account: account,
      token_id: token_id
    }
  end
end
