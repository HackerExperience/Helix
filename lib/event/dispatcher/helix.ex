defmodule Helix.Event.Dispatcher.Helix do
  @moduledoc false

  use HELF.Event

  alias Helix.Account
  alias Helix.Entity
  alias Helix.Log
  alias Helix.Network
  alias Helix.Process
  alias Helix.Software
  alias Helix.Universe

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
    Log.Event.Log,
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
    Software.Event.Cracker,
    :bruteforce_conclusion

  event Software.Model.Software.Cracker.Overflow.ConclusionEvent,
    Software.Event.Cracker,
    :overflow_conclusion

  event Software.Model.SoftwareType.Decryptor.ProcessConclusionEvent,
    Software.Event.Decryptor,
    :complete

  event Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent,
    Software.Event.Encryptor,
    :complete

  event Software.Model.SoftwareType.FileDownload.ProcessConclusionEvent,
    Software.Event.FileDownload,
    :complete
  event Software.Model.SoftwareType.FileDownload.ProcessConclusionEvent,
    Log.Event.Log,
    :file_download_conclusion

  event Software.Model.SoftwareType.Firewall.FirewallStartedEvent,
    Process.Event.Cracker,
    :firewall_started

  event Software.Model.SoftwareType.Firewall.FirewallStoppedEvent,
    Process.Event.Cracker,
    :firewall_stopped

  event Software.Model.SoftwareType.LogForge.Create.ConclusionEvent,
    Log.Event.Log,
    :log_forge_conclusion

  event Software.Model.SoftwareType.LogForge.Edit.ConclusionEvent,
    Log.Event.Log,
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
    Software.Event.Cracker,
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
