defmodule Helix.Event.Dispatcher.Helix do
  @moduledoc false

  use HELF.Event

  alias Helix.Account
  alias Helix.Entity
  alias Helix.Network
  alias Helix.Process
  alias Helix.Software
  alias Helix.Universe

  alias Helix.Log.Event.Handler, as: LogHandler
  alias Helix.Software.Event, as: SoftwareEvent
  alias Helix.Software.Event.Handler, as: SoftwareHandler

  ##############################################################################
  # Account events
  ##############################################################################
  event Account.Model.Account.AccountCreatedEvent,
    Account.Event.Account,
    :account_create

  ##############################################################################
  # Network events
  ##############################################################################
  event Network.Model.Connection.ConnectionClosedEvent,
    Network.Event.Tunnel,
    :connection_closed
  event Network.Model.Connection.ConnectionClosedEvent,
    Process.Event.TOP,
    :connection_closed

  event Network.Model.Connection.ConnectionStartedEvent,
    LogHandler.Log,
    :connection_started

  ##############################################################################
  # Server events
  ##############################################################################
  event Helix.Server.Model.Server.PasswordAcquiredEvent,
    Entity.Event.Database,
    :server_password_acquired

  ##############################################################################
  # Software events
  ##############################################################################
  event Software.Model.Software.Cracker.Bruteforce.ConclusionEvent,
    SoftwareHandler.Cracker,
    :bruteforce_conclusion

  event Software.Model.Software.Cracker.Overflow.ConclusionEvent,
    SoftwareHandler.Cracker,
    :overflow_conclusion

  event Software.Model.SoftwareType.Decryptor.ProcessConclusionEvent,
    SoftwareHandler.Decryptor,
    :complete

  event Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent,
    SoftwareHandler.Encryptor,
    :complete

  event SoftwareEvent.File.Transfer.Processed,
    SoftwareHandler.File.Transfer,
    :complete

  event SoftwareEvent.File.Downloaded,
    LogHandler.Log,
    :file_downloaded

  event Software.Model.SoftwareType.Firewall.FirewallStartedEvent,
    Process.Event.Cracker,
    :firewall_started

  event Software.Model.SoftwareType.Firewall.FirewallStoppedEvent,
    Process.Event.Cracker,
    :firewall_stopped

  event Software.Model.SoftwareType.LogForge.Create.ConclusionEvent,
    LogHandler.Log,
    :log_forge_conclusion

  event Software.Model.SoftwareType.LogForge.Edit.ConclusionEvent,
    LogHandler.Log,
    :log_forge_conclusion

  ##############################################################################
  # Universe events
  ##############################################################################

  event Universe.Bank.Model.BankTransfer.BankTransferCompletedEvent,
    Universe.Bank.Event.BankTransfer,
    :transfer_completed
  event Universe.Bank.Model.BankTransfer.BankTransferCompletedEvent,
    Network.Event.Connection,
    :bank_transfer_completed

  event Universe.Bank.Model.BankTransfer.BankTransferAbortedEvent,
    Universe.Bank.Event.BankTransfer,
    :transfer_aborted
  event Universe.Bank.Model.BankTransfer.BankTransferAbortedEvent,
    SoftwareHandler.Cracker,
    :bank_transfer_aborted

  event Universe.Bank.Model.BankTokenAcquiredEvent,
    Entity.Event.Database,
    :bank_token_acquired

  event Universe.Bank.Model.BankAccount.RevealPassword.ConclusionEvent,
    Universe.Bank.Event.BankAccount,
    :password_reveal_conclusion

  event Universe.Bank.Model.BankAccount.PasswordRevealedEvent,
    Entity.Event.Database,
    :bank_password_revealed

  event Universe.Bank.Model.BankAccount.LoginEvent,
    Entity.Event.Database,
    :bank_account_login
end
