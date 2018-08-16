defprotocol Helix.Process.Model.Processable do
  @moduledoc """
  The Processable protocol is responsible for implementing a bunch of callbacks
  that will be executed when the underlying Process receives a signal.

  For a list of valid signals and when they occur, see typedoc at ProcessModel.

  Notice that the Processable model below is the bare bones implementation of
  Processable. The actual interface a Process uses, however, is slightly simpler
  and is defined at `Helix.Process.Processable`.
  """

  alias Helix.Event
  alias Helix.Network.Model.Connection
  alias Helix.Process.Model.Process

  @typedoc """
  The actions below are valid actions that will be performed on the process if
  they are returned on one of the callbacks below.

  ## :delete

  Obliterate the process, forever.

  Once this happens, a `ProcessDeletedEvent` is emitted.

  ## :pause

  Pauses a process.

  Emits `ProcessPausedEvent`.

  If the process is already paused, it remains paused (it's idempotent). In that
  case, however, the `ProcessPausedEvent` is not emitted.

  ## :resume

  Resumes a process.

  Emits `ProcessResumedEvent`.

  If the process is already resumed, it remains resumed (it's idempotent). In
  that case, however, the `ProcessResumedEvent` is not emitted.

  ## :renice

  Modifies the priority of the event.

  Emits `ProcessPriorityChangedEvent`

  ## :restart

  Resets any work the process may have done, and starts from scratch.

  Not implemented yet.

  ## :retarget

  Modify the target of a process, potentially changing its resources and/or
  relevant objects. Commonly used with recursive processes.

  ## {:SIGKILL, <reason>}

  Sends a SIGKILL to itself, with the given reason as a parameter.

  Emits a `ProcessSignaledEvent`. 

  Later on, the process *might* be killed. Depends on how it implements the
  `on_kill` callback.

  ## :SIGRETARGET

  Sends a SIGRETARGET to itself

  Later on, the process *might* change. Depends on how it implements the
  `on_retarget` callback.

  ## :noop

  Makes a lot of nada.

  Does not emit anything.
  """
  @type action ::
    :delete
    | :pause
    | :resume
    | :renice
    | :restart
    | {:retarget, Process.retarget_changes}
    | {:SIGKILL, Process.kill_reason}
    | :SIGRETARGET
    | :noop

  @spec complete(t, Process.t) ::
    {action, [Event.t]}
  @doc """
  Called when the process receives a SIGTERM.
  """
  def complete(data, process)

  @spec kill(t, Process.t, Process.kill_reason) ::
    {action, [Event.t]}
  @doc """
  Called when the process receives a SIGKILL. Also receives the kill reason.
  """
  def kill(data, process, reason)

  @spec retarget(t, Process.t) ::
    {action, [Event.t]}
  @doc """
  Called when the process receives a SIGRETARGET, meaning the process finished
  its previous objective and is now looking for something else to do. Commonly
  used on recursive processes.
  """
  def retarget(data, process)

  @spec source_connection_closed(t, Process.t, Connection.t) ::
    {action, [Event.t]}
  @doc """
  Called when the process receives a SIGSRCCONND, meaning the connection that
  originated that process has been closed. Also receives the connection that was
  recently closed.
  """
  def source_connection_closed(data, process, connection)

  @spec target_connection_closed(t, Process.t, Connection.t) ::
    {action, [Event.t]}
  @doc """
  Called when the process receives a SIGTGTCONND, meaning the connection that
  process is targeting has been closed. Also receives the connection that was
  recently closed.
  """
  def target_connection_closed(data, process, connection)

  @spec after_read_hook(term) ::
    t
  @doc """
  Process metadata (Processable) is stored as JSONB on Postgres. After
  retrieval, we may lose some internal data representation, like Helix IDs or
  atoms, which are both converted to string. This method purpose is somewhat
  similar to serialization.
  """
  def after_read_hook(data)
end
