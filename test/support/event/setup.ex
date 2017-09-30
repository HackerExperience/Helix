defmodule Helix.Test.Event.Setup do

  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Connection
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server

  alias Helix.Network.Model.Connection.ConnectionClosedEvent
  alias Helix.Process.Model.Process.ProcessCreatedEvent
  alias Helix.Software.Model.Software.Cracker.Bruteforce.ConclusionEvent,
    as: BruteforceConclusionEvent
  alias Helix.Software.Model.Software.Cracker.Overflow.ConclusionEvent,
    as: OverflowConclusionEvent
  # alias Helix.Story.Event.StepProceeded, as: StoryStepProceededEvent
  alias Helix.Universe.Bank.Model.BankTokenAcquiredEvent
  alias Helix.Universe.Bank.Model.BankAccount.LoginEvent,
    as: BankAccountLoginEvent
  alias Helix.Universe.Bank.Model.BankAccount.PasswordRevealedEvent,
    as: BankAccountPasswordRevealedEvent

  alias HELL.TestHelper.Random
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Server.Setup, as: ServerSetup

  @internet NetworkHelper.internet_id()

  ##############################################################################
  # Process events
  ##############################################################################

  @doc """
  Accepts:

  - (gateway :: Server.ID, target :: Server.ID, gateway_entity :: Entity.ID \
    target_entity_id :: Entity.ID), in which case a fake process with random ID
    is generated
  """
  def process_created(gateway_id, target_id, gateway_entity, target_entity) do
    # Generates a random process on the given server(s)
    process_opts = [gateway_id: gateway_id, target_id: target_id]
    {process, _} = ProcessSetup.fake_process(process_opts)

    %ProcessCreatedEvent{
      process: process,
      gateway_id: gateway_id,
      target_id: target_id,
      gateway_entity_id: gateway_entity,
      target_entity_id: target_entity,
      gateway_ip: Random.ipv4(),
      target_ip: Random.ipv4()
    }
  end

  @doc """
  Opts:
    - gateway_id: Specify the gateway id.
    - target_id: Specify the target id.
    - gateway_entity_id: Specify the gateway entity id.
    - target_entity_id: Specify the target entity id.

  Note the generated process is fake (does not exist on DB).
  """
  def process_created(type, opts \\ [])
  def process_created(:single_server, opts) do
    gateway_id = Access.get(opts, :gateway_id, Server.ID.generate())
    gateway_entity = Access.get(opts, :gateway_entity_id, Entity.ID.generate())

    process_created(gateway_id, gateway_id, gateway_entity, gateway_entity)
  end
  def process_created(:multi_server, opts) do
    gateway_id = Access.get(opts, :gateway_id, Server.ID.generate())
    gateway_entity = Access.get(opts, :gateway_entity_id, Entity.ID.generate())

    target_id = Access.get(opts, :target_id, Server.ID.generate())
    target_entity = Access.get(opts, :target_entity_id, Entity.ID.generate())

    process_created(gateway_id, target_id, gateway_entity, target_entity)
  end

  @doc """
  Accepts: Process.t, (Connection.t, Server.id)
  """
  def overflow_conclusion(process = %Process{}) do
    %OverflowConclusionEvent{
      gateway_id: process.gateway_id,
      target_process_id: process.process_id,
      target_connection_id: nil
    }
  end
  def overflow_conclusion(connection = %Connection{}, gateway_id) do
    %OverflowConclusionEvent{
      gateway_id: gateway_id,
      target_process_id: nil,
      target_connection_id: connection.connection_id
    }
  end

  def bruteforce_conclusion(process = %Process{}) do
    %BruteforceConclusionEvent{
      source_entity_id: process.source_entity_id,
      network_id: process.network_id,
      target_server_id: process.target_server_id,
      target_server_ip: process.process_data.target_server_ip,
    }
  end

  def bruteforce_conclusion do
    %BruteforceConclusionEvent{
      source_entity_id: EntitySetup.id(),
      network_id: @internet,
      target_server_id: ServerSetup.id(),
      target_server_ip: Random.ipv4()
    }
  end

  ##############################################################################
  # Network events
  ##############################################################################

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

  ##############################################################################
  # Universe.Bank events
  ##############################################################################

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
