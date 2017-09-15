defprotocol Helix.Process.Public.View.ProcessViewable do
  @moduledoc """
  The ProcessViewable protocol is responsible for returning the expected data
  to the client. It must be implemented by each process who intends to return
  something because the actual output depends on the context:

  A process may have different details/data to a specific entity. For instance,
  the entity whose process originated from always has full access to the 
  process. A third-party looking at the server who originated the request also
  has full access. However, a third-party looking at a process that was not
  authored, but instead targets the server she's currently at, will have limited
  information.

  That's why Entity and Server are passed along, so the implementation of the
  protocol can figure out the correct context.
  """

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process
  alias Helix.Process.Public.View.Process, as: ProcessView

  @typep allowed_processes ::
    ProcessView.partial_process
    | ProcessView.full_process
    | %{}

  @spec get_scope(term, Process.t, Server.id, Entity.id) ::
    ProcessView.scopes
  @doc """
  `get_scope/4` is responsible solely for figuring out which context the player
  has with regards to the given process/data. It's usually either `full` or
  `partial`
  """
  def get_scope(data, process, server_id, entity_id)

  @spec render(term, Process.t, ProcessView.scopes) ::
    {allowed_processes, data :: map}
  @doc """
  The implementation of `render/3` is responsible for rendering the result that
  should be sent to the client, already knowing which context the player has
  access, as returned by `get_scope/4`.

  Note that this result is sent directly to the client, so it should be JSON
  friendly, e.g. converting Helix.IDs to Strings.

  `render/3` expects a two-tuple to be returned, with the first element being
  the "base process" map, and the second one the "data" map.

  The "base process" map holds generic information about the process, like
  `process_id`, `file_id`, `connection_id` etc.
  The "data" map holds specific information about that process type, like which
  log is being forged (in the case of a LogForger process), or what's the amount
  (in the case of a BankTransfer process).

  After returned, both maps are merged into a single one, which will finally be
  pushed to the client.

  If the process is not meant to be rendered/displayed to the client, it must
  return an empty map for both the "base" process and the "data" map.
  """
  def render(data, process, scope)
end
