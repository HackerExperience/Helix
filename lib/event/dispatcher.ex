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

  alias Helix.Event.PublicationHandler

  alias Helix.Core.Listener.Event.Handler.Listener, as: ListenerHandler
  alias Helix.Account.Event, as: AccountEvent
  alias Helix.Account.Event.Handler, as: AccountHandler
  alias Helix.Client.Event, as: ClientEvent
  alias Helix.Entity.Event, as: EntityEvent
  alias Helix.Entity.Event.Handler, as: EntityHandler
  alias Helix.Log.Event, as: LogEvent
  alias Helix.Log.Event.Handler, as: LogHandler
  alias Helix.Network.Event, as: NetworkEvent
  alias Helix.Network.Event.Handler, as: NetworkHandler
  alias Helix.Notification.Event, as: NotificationEvent
  alias Helix.Notification.Event.Handler, as: NotificationHandler
  alias Helix.Process.Event, as: ProcessEvent
  alias Helix.Process.Event.Handler, as: ProcessHandler
  alias Helix.Server.Event, as: ServerEvent
  alias Helix.Software.Event, as: SoftwareEvent
  alias Helix.Software.Event.Handler, as: SoftwareHandler
  alias Helix.Story.Event, as: StoryEvent
  alias Helix.Story.Event.Handler, as: StoryHandler
  alias Helix.Universe.Bank.Event, as: BankEvent
  alias Helix.Universe.Bank.Event.Handler, as: BankHandler

  ##############################################################################
  # Global handlers
  ##############################################################################

  all_events ListenerHandler, :listener_handler

  all_events LogHandler.Log, :handle_event,
    skip: [LogEvent.Log.Created]

  all_events NotificationHandler.Notification, :notification_handler

  all_events PublicationHandler, :publication_handler

  ##############################################################################
  # Account events
  ##############################################################################

  # All
  event AccountEvent.Account.Created
  event AccountEvent.Account.Verified

  # Custom handlers
  event AccountEvent.Account.Verified,
    AccountHandler.Account,
    :account_created

  ##############################################################################
  # Client events
  ##############################################################################

  # All
  event ClientEvent.Action.Performed

  # Custom handlers
  event ClientEvent.Action.Performed,
    StoryHandler.Story,
    :event_handler

  ##############################################################################
  # Entity events
  ##############################################################################

  # All
  event EntityEvent.Entity.Created

  # Custom handlers
  event EntityEvent.Entity.Created,
    StoryHandler.Manager,
    :setup_story

  ##############################################################################
  # Network events
  ##############################################################################

  # All
  event NetworkEvent.Bounce.Created
  event NetworkEvent.Bounce.CreateFailed
  event NetworkEvent.Bounce.Removed
  event NetworkEvent.Bounce.RemoveFailed
  event NetworkEvent.Bounce.Updated
  event NetworkEvent.Bounce.UpdateFailed
  event NetworkEvent.Connection.Closed
  event NetworkEvent.Connection.Started

  # Custom handlers
  event NetworkEvent.Connection.Closed,
    NetworkHandler.Tunnel,
    :connection_closed
  event NetworkEvent.Connection.Closed,
    ProcessHandler.TOP,
    :object_handler

  ##############################################################################
  # Notification events
  ##############################################################################

  # All
  event NotificationEvent.Notification.Added
  event NotificationEvent.Notification.Read

  ##############################################################################
  # Log events
  ##############################################################################

  # All
  event LogEvent.Forge.Processed
  event LogEvent.Recover.Processed
  event LogEvent.Log.Created
  event LogEvent.Log.Destroyed
  event LogEvent.Log.Recovered
  event LogEvent.Log.Revised

  # Custom handlers
  event LogEvent.Forge.Processed,
    LogHandler.Log,
    :forge_processed

  event LogEvent.Recover.Processed,
    LogHandler.Log,
    :recover_processed

  event LogEvent.Log.Revised,
    ProcessHandler.TOP,
    :object_handler

  event LogEvent.Log.Recovered,
    ProcessHandler.TOP,
    :object_handler

  event LogEvent.Log.Destroyed,
    ProcessHandler.TOP,
    :object_handler

  ##############################################################################
  # Process events
  ##############################################################################

  # All
  event ProcessEvent.Process.Created
  event ProcessEvent.Process.Completed
  event ProcessEvent.Process.Killed
  event ProcessEvent.Process.Signaled
  event ProcessEvent.TOP.BringMeToLife
  event ProcessEvent.TOP.Recalcado

  # Custom handlers
  event ProcessEvent.Process.Created,
    ProcessHandler.TOP,
    :recalque_handler
  event ProcessEvent.Process.Created,
    StoryHandler.Story,
    :event_handler

  event ProcessEvent.TOP.BringMeToLife,
    ProcessHandler.TOP,
    :wake_me_up

  event ProcessEvent.Process.Signaled,
    ProcessHandler.Process,
    :signal_handler

  ##############################################################################
  # Server events
  ##############################################################################

  # All
  event ServerEvent.Motherboard.Updated
  event ServerEvent.Motherboard.UpdateFailed
  event ServerEvent.Server.Password.Acquired
  event ServerEvent.Server.Joined

  # Custom handlers
  event ServerEvent.Server.Password.Acquired,
    EntityHandler.Database,
    :server_password_acquired

  ##############################################################################
  # Software events
  ##############################################################################

  # All
  event SoftwareEvent.Cracker.Bruteforce.Failed
  event SoftwareEvent.Cracker.Bruteforce.Processed
  event SoftwareEvent.Cracker.Overflow.Processed
  event SoftwareEvent.File.Added
  event SoftwareEvent.File.Deleted
  event SoftwareEvent.File.Downloaded
  event SoftwareEvent.File.DownloadFailed
  event SoftwareEvent.File.Install.Processed
  event SoftwareEvent.File.Uploaded
  event SoftwareEvent.File.UploadFailed
  event SoftwareEvent.File.Transfer.Processed
  event SoftwareEvent.Firewall.Started
  event SoftwareEvent.Firewall.Stopped
  event SoftwareEvent.Virus.Collect.Processed
  event SoftwareEvent.Virus.Collected
  event SoftwareEvent.Virus.Installed
  event SoftwareEvent.Virus.InstallFailed

  # Custom handlers
  event SoftwareEvent.Cracker.Bruteforce.Processed,
    SoftwareHandler.Cracker,
    :bruteforce_conclusion

  event SoftwareEvent.Cracker.Overflow.Processed,
    SoftwareHandler.Cracker,
    :overflow_conclusion

  event SoftwareEvent.File.Downloaded,
    SoftwareHandler.Filesystem,
    :filesystem_handler

  event SoftwareEvent.File.Install.Processed,
    SoftwareHandler.Virus,
    :virus_installed

  event SoftwareEvent.File.Uploaded,
    SoftwareHandler.Filesystem,
    :filesystem_handler

  event SoftwareEvent.File.Transfer.Processed,
    SoftwareHandler.File.Transfer,
    :complete

  event SoftwareEvent.Firewall.Started,
    ProcessHandler.Cracker,
    :firewall_started

  event SoftwareEvent.Firewall.Stopped,
    ProcessHandler.Cracker,
    :firewall_stopped

  event SoftwareEvent.Virus.Collect.Processed,
    SoftwareHandler.Virus,
    :handle_collect

  event SoftwareEvent.Virus.Collected,
    BankHandler.Bank.Account,
    :virus_collected

  event SoftwareEvent.Virus.Installed,
    EntityHandler.Database,
    :on_virus_installed

  ##############################################################################
  # Story events
  ##############################################################################

  # All
  event StoryEvent.Email.Sent
  event StoryEvent.Reply.Sent
  event StoryEvent.Step.ActionRequested
  event StoryEvent.Step.Proceeded
  event StoryEvent.Step.Restarted

  # Custom handlers
  event StoryEvent.Email.Sent,
    StoryHandler.Story,
    :event_handler

  event StoryEvent.Reply.Sent,
    StoryHandler.Story,
    :event_handler

  event StoryEvent.Step.ActionRequested,
    StoryHandler.Story,
    :action_handler

  ##############################################################################
  # Universe events
  ##############################################################################

  # All
  event BankEvent.Bank.Account.Login
  event BankEvent.Bank.Account.Updated
  event BankEvent.Bank.Account.Password.Revealed
  event BankEvent.Bank.Account.Token.Acquired
  event BankEvent.Bank.Transfer.Processed
  event BankEvent.Bank.Transfer.Aborted
  event BankEvent.RevealPassword.Processed

  # Custom handlers
  event BankEvent.Bank.Transfer.Processed,
    BankHandler.Bank.Transfer,
    :transfer_processed
  event BankEvent.Bank.Transfer.Processed,
    NetworkHandler.Connection,
    :bank_transfer_processed

  event BankEvent.Bank.Transfer.Aborted,
    BankHandler.Bank.Transfer,
    :transfer_aborted
  event BankEvent.Bank.Transfer.Aborted,
    SoftwareHandler.Cracker,
    :bank_transfer_aborted

  event BankEvent.Bank.Account.Token.Acquired,
    EntityHandler.Database,
    :bank_token_acquired

  event BankEvent.RevealPassword.Processed,
    BankHandler.Bank.Account,
    :password_reveal_processed

  event BankEvent.Bank.Account.Password.Revealed,
    EntityHandler.Database,
    :bank_password_revealed

  event BankEvent.Bank.Account.Login,
    EntityHandler.Database,
    :bank_account_login
end
