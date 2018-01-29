defmodule Helix.Test.Log.Macros do

  alias HELL.Utils
  alias Helix.Event.Loggable.Utils, as: LoggableUtils
  alias Helix.Entity.Model.Entity
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Network.Model.Bounce
  alias Helix.Server.Model.Server

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper

  @internet_id NetworkHelper.internet_id()

  @doc """
  Helper to assert the expected log was returned.

  `fragment` is a mandatory parameter, it's an excerpt of the log that must
  exist on the log content.

  Opts:
  - contains: List of words/terms that should be present on the log message
  - rejects: List of words/terms that must not be present on the log message
  """
  defmacro assert_log(log, s_id, e_id, fragment, opts \\ quote(do: [])) do
    contains = Keyword.get(opts, :contains, []) |> Utils.ensure_list()
    reject = Keyword.get(opts, :reject, []) |> Utils.ensure_list()

    quote do

      assert unquote(log).server_id == unquote(s_id)
      assert unquote(log).entity_id == unquote(e_id)
      assert unquote(log).message =~ unquote(fragment)

      Enum.each(unquote(contains), fn term ->
        assert unquote(log).message =~ term
      end)
      Enum.each(unquote(reject), fn term ->
        refute unquote(log).message =~ term
      end)

    end
  end

  defmacro censor_ip(ip) do
    quote do
      LoggableUtils.censor_ip(unquote(ip))
    end
  end

  @doc """
  Helper to assert the logs were correctly generated within the bounce chain.

  It will check for the std log message "Connection bounced from (n-1) to (n+1)"

  Opts:
  - rejects: Values that must not be contained within the bounce message. It
    automatically includes the `gateway_ip` and the `endpoint_ip` on the reject
    list (if applicable). Useful for rejecting extra stuff, like the log action
    (e.g. "download", "upload") or custom data (like the file name, version etc)
  """
  defmacro assert_bounce(bounce, gateway, endpoint, entity, opts) do
    quote location: :keep do
      {
        links,
        gateway_data = {_, _, gateway_ip},
        endpoint_data = {_, _, endpoint_ip},
        entity_id,
        {extra_rejects, _opts}
      } = verify_bounce_params(
        unquote(bounce),
        unquote(gateway),
        unquote(endpoint),
        unquote(entity),
        unquote(opts)
      )

      bounce_map =
        [gateway_data | links] ++ [endpoint_data]
        |> Enum.reduce({0, %{}}, fn link, {idx, acc} ->
          {idx + 1, Map.put(acc, idx, link)}
        end)
        |> elem(1)

      length_bounce = length(links)

      links
      |> Enum.reduce(1, fn link = {server_id, _, _}, idx ->
        # Unless we are on the first bounce, `gateway_ip` must not show up
        first_ip = idx >= 2 && gateway_ip || []

        # Unless we are on the last bounce, `endpoint_ip` must not show up
        last_ip = idx <= length_bounce - 1 && endpoint_ip || []

        {_, _, ip_prev} = bounce_map[idx - 1]
        {_, _, ip_next} = bounce_map[idx + 1]

        msg = "Connection bounced from #{ip_prev} to #{ip_next}"

        assert [log_bounce | _] = LogQuery.get_logs_on_server(server_id)
        assert_log \
          log_bounce, server_id, entity_id,
          "Connection bounced",
          contains: ["from #{ip_prev} to #{ip_next}"],
          rejects: [first_ip, last_ip, extra_rejects] |> List.flatten()

        idx + 1
      end)
    end
  end

  def verify_bounce_params(
    bounce = %Bounce{},
    gateway = %Server{},
    endpoint = %Server{},
    entity = %Entity{},
    opts,
    network_id \\ @internet_id)
  do
    gateway_ip = ServerHelper.get_ip(gateway, network_id)
    endpoint_ip = ServerHelper.get_ip(endpoint, network_id)

    extra_rejects = Keyword.get(opts, :rejects, [])

    {
      bounce.links,
      {gateway.server_id, network_id, gateway_ip},
      {endpoint.server_id, network_id, endpoint_ip},
      entity.entity_id,
      {extra_rejects, opts}
    }
  end
end
