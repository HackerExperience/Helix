defprotocol Helix.Event.Notificable do
  @moduledoc """
  # The Notificable protocol

  Events that are emitted from Helix to the Client must implement the
  Notificable protocol. It is responsible for:

  - Telling Phoenix which Channels should receive the event.
  - Filtering or censoring the payload of the event according to each player
    context within that specific channel.
  - Formatting output from Helix.ID to binary (string), as well as any other
    JSON unfriendly structures that need prior handling.
  - Specifying the event type.

  Notificable will deliver events based on players permissions and context.
  This means that the same event may vary slightly from player to player, or
  not arrive at all for some players. Which players receive what messages
  depends on some game mechanics and other factors.

  # Testing Notificable implementation

  Naturally, Notificable becomes a key part of the architecture since it is the
  conductor responsible for notifying and filtering out all in-game events. As
  such, extended and reliable test coverage is vital.

  Testing is relatively easy (stateless / no side-effects), however we may have
  several different contexts for a single event, which may cause some confusion
  as to which context is being tested at a given time.

  In order to test Notificable properly, we must ensure that different players
  receive these different messages, so we must map all possible scenarios.

  The problem is describing which scenario the test case is testing. So I've
  come up with this terminology, which needs some getting used to, but once
  you are familiar with it, it will make you quickly understand each test
  context.

  # Notificable Test Terminology

  In many cases, we have an attacker and a victim. These attacks occur on the
  victim's servers, and originates on the attacker's server, possibly with
  intermediary servers.

  To represent this scenario, the correct test name shall be:

  - attacker AT attack_source - attacker receiving event on his own server
  - attacker AT attack_target - attacker receiving event on victim's server
  - victim AT attack_target - victim receiving event on his own server
  - victim AT attack_source - victim receiving event on his attacker's server

  Notice that `attack_source` refers to the server where the attack
  originated from, and `attack_target` refers to the victim's server.

  We need to ensure that notifications are bound to server, not users. Say:

  - attacker AT attacker_server NOT attack_source
  - victim AT victim_server NOT attack_target

  Both expressions above mean that we are testing the attacker/victim joined
  on a server that belongs to them, but is not related to the action.

  Finally, we may want to make sure third-party users, unrelated to that
  action, also receive special treatment. Hence:

  - third AT attack_target - Third party on victim's server
  - third AT attack_source - Third party on attacker's server. 
  - third AT random_server - Third party on unrelated (random) server.

  Last but not least, in some cases we do not have an attacker/victim
  relationship, say, when I start a process on my own computer. In that case we
  should use:

  - player AT action_server
  - player AT player_server NOT action_server

  Here, `action_server` denotes the server originating that action. Since we
  are under the context of a single player, that server always belongs to
  `player`.

  ---

  Q: Do I need to test all cases?

  A: Usually, no. For instance, it's impossible for a specific server event to
  be sent to a third, unrelated server,  meaning we do not need to test the
  cases when an unrelated server is involved.

  However, we do need to test when an unrelated player is joined on the server
  that is receiving/doing the action.

  Note that this is true for the ServerChannel. Maybe in some other contexts
  we need to test other stuff as well.

  Example test case: `test/process/event/process_created_test.exs`
  """

  alias Phoenix.Socket

  alias Helix.Account.Model.Account
  alias Helix.Server.Model.Server

  @type whom_to_notify ::
    %{
      optional(:server) => [Server.id],
      optional(:account) => [Account.id]
    }

  @spec generate_payload(event :: struct, Socket.t) ::
    {:ok, payload :: term}
    | :noreply
  @doc """
  Generates the actual payload of the event for the given player, according to
  the context provided by `socket`.

  Both `event` and `socket` must have enough information to let Helix know how
  to handle such payload, whether it should have some filters removed or not
  sent at all. That said, it seems inevitable that in some cases we'll have to
  resort to external Queries.[1]

  Must return {:ok, %{data: <payload>, event: <event_name>}} if pushing the
  event to the client is desirable. Otherwise, simply return a :noreply.

  Note that <event_name> must be a string and it's an important identifier for
  the Client, since it's how the client know what event Helix is talking about.

  ---

  [1] - Note that Querying at Notificable should always be last resort, since
  Notificable is executed every time an event is sent to any player.
  """
  def generate_payload(event, socket)

  @spec whom_to_notify(event :: struct) ::
    whom_to_notify
  @doc """
  Specifies which topics should receive the event.

  For instance, suppose an `ProcessCreatedEvent` from server A to B. Both
  servers A and B should be notified about the new process, so their TaskManager
  is updated.

  Note that the filtering does not happen here. It just tells Phoenix that we
  should broadcast the `ProcessCreatedEvent` to anyone listening to events on
  servers A and B.

  Then, before actually sending the event, Phoenix intercepts the event message
  and asks `generate_payload` what the actual payload is to that specific user.

  Must always return a list of Server IDs. (Requires a small change when
  implementing for Account or other channels)
  """
  def whom_to_notify(event)

  @doc """
  Returns the name of the event that will be sent to the client.
  """
  def get_event_name(event)
end
