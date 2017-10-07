defmodule Helix.Event.Dispatcher do
  @moduledoc """
  This module is a centralized, declarative list of valid events within Helix.

  It defines both the event itself and which handlers are supposed to listen to
  them.

  An event defined by the `event/3` macro will:

  1) Let Helix know it exists
  2) Register its handler module and function.

  We have a special kind of event handler: Global Handlers. Global handlers will
  listen to all events registered within this module. Hence, it may be the case
  that an event exists, is handled globally, but it's not handled specifically
  by one or two handlers, so we can't use `event/3`.

  That's why, in these cases, we must use `event/1` macro. It notifies Helix
  that the event exists and is valid, but it won't have a specific listener
  subscribed to it.

  TL;DR:

  - All events declared here are automatically subscribed to the global handlers
  - Events defined with a custom handler will also be subscribed to that handler
  - Events not declared here will never be listened by any handler.
  - An event may be declared multiple times.

  ---

  With the goal of enhancing documentation, we've started the convention to
  always declare all events, grouped by service, and then declare the ones that
  have custom handlers as well.
  """

  use HELF.Event

  alias Helix.Event.NotificationHandler
  alias Helix.Account
  alias Helix.Entity
  alias Helix.Process
  alias Helix.Software
  alias Helix.Universe

  alias Helix.Log.Event, as: LogEvent
  alias Helix.Log.Event.Handler, as: LogHandler
  alias Helix.Network.Event, as: NetworkEvent
  alias Helix.Network.Event.Handler, as: NetworkHandler
  alias Helix.Software.Event, as: SoftwareEvent
  alias Helix.Software.Event.Handler, as: SoftwareHandler
  alias Helix.Story.Event, as: StoryEvent
  alias Helix.Story.Event.Handler.Story, as: StoryHandler

  ##############################################################################
  # Global handlers
  ##############################################################################

  all_events NotificationHandler, :notification_handler

  all_events LogHandler.Log, :handle_event,
    skip: [LogEvent.Log.Created]

  all_events StoryHandler, :step_handler

  ##############################################################################
  # Account events
  ##############################################################################

  # All
  event Account.Model.Account.AccountCreatedEvent

  # Custom handlers
  event Account.Model.Account.AccountCreatedEvent,
    Account.Event.Account,
    :account_create

  ##############################################################################
  # Network events
  ##############################################################################

  # All
  event NetworkEvent.Connection.Closed
  event NetworkEvent.Connection.Started

  # Custom handlers
  event NetworkEvent.Connection.Closed,
    NetworkHandler.Tunnel,
    :connection_closed
  event NetworkEvent.Connection.Closed,
    Process.Event.TOP,
    :connection_closed

  ##############################################################################
  # Log events
  ##############################################################################

  # All
  event LogEvent.Log.Created
  event LogEvent.Log.Deleted
  event LogEvent.Log.Modified

  ##############################################################################
  # Process events
  ##############################################################################

  # All
  event Process.Model.Process.ProcessCreatedEvent
  event Process.Model.Process.ProcessConclusionEvent

  ##############################################################################
  # Server events
  ##############################################################################

  # All
  event Helix.Server.Model.Server.PasswordAcquiredEvent

  # Custom handlers
  event Helix.Server.Model.Server.PasswordAcquiredEvent,
    Entity.Event.Database,
    :server_password_acquired

  ##############################################################################
  # Software events
  ##############################################################################

  # All
  event SoftwareEvent.File.Downloaded
  event SoftwareEvent.File.DownloadFailed
  event SoftwareEvent.File.Uploaded
  event SoftwareEvent.File.UploadFailed
  event SoftwareEvent.File.Transfer.Processed
  event Software.Model.Software.Cracker.Bruteforce.ConclusionEvent
  event Software.Model.Software.Cracker.Overflow.ConclusionEvent
  event Software.Model.SoftwareType.Decryptor.ProcessConclusionEvent
  event Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent
  event Software.Model.SoftwareType.Firewall.FirewallStartedEvent
  event Software.Model.SoftwareType.Firewall.FirewallStoppedEvent
  event Software.Model.SoftwareType.LogForge.Create.ConclusionEvent
  event Software.Model.SoftwareType.LogForge.Edit.ConclusionEvent

  # Custom handlers
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

  # All
  event StoryEvent.Email.Sent
  event StoryEvent.Reply.Sent
  event StoryEvent.Step.Proceeded

  ##############################################################################
  # Universe events
  ##############################################################################

  # All
  event Universe.Bank.Model.BankTransfer.BankTransferCompletedEvent
  event Universe.Bank.Model.BankTransfer.BankTransferAbortedEvent
  event Universe.Bank.Model.BankTokenAcquiredEvent
  event Universe.Bank.Model.BankAccount.RevealPassword.ConclusionEvent
  event Universe.Bank.Model.BankAccount.PasswordRevealedEvent
  event Universe.Bank.Model.BankAccount.LoginEvent

  # Custom handlers
  event Universe.Bank.Model.BankTransfer.BankTransferCompletedEvent,
    Universe.Bank.Event.BankTransfer,
    :transfer_completed
  event Universe.Bank.Model.BankTransfer.BankTransferCompletedEvent,
    NetworkHandler.Connection,
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
