defmodule Helix.Test.Log.Macros do

  alias Helix.Event.Loggable.Utils, as: LoggableUtils
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Query.Bounce, as: BounceQuery
  alias Helix.Server.Model.Server

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Log.Helper, as: LogHelper

  @internet_id NetworkHelper.internet_id()

  @doc """
  Helper to assert the expected log was returned.

  `fragment` is a mandatory parameter, it's an excerpt of the log that must
  exist on the log content.
  """
  defmacro assert_log(log, s_id, e_id, type, data) do
    quote do

      assert unquote(log).server_id == unquote(s_id)
      assert unquote(log).revision.entity_id == unquote(e_id)

      assert unquote(log).revision.type == unquote(type)

      Enum.each(unquote(data), fn {key, value} ->
        assert Map.fetch!(unquote(log).revision.data, to_string(key)) == value
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
  """
  defmacro assert_bounce(bounce, gateway, endpoint, entity) do
    quote location: :keep, generated: true do
      {links, gateway_data, endpoint_data, entity_id} =
        verify_bounce_params(
          unquote(bounce), unquote(gateway), unquote(endpoint), unquote(entity)
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
        {_, _, ip_prev} = bounce_map[idx - 1]
        {_, _, ip_next} = bounce_map[idx + 1]

        log_bounce = LogHelper.get_last_log(server_id, :connection_bounced)
        assert_log log_bounce, server_id, entity_id,
          :connection_bounced, %{ip_prev: ip_prev, ip_next: ip_next}

        idx + 1
      end)
    end
  end

  def verify_bounce_params(bounce, gat, endp, ent, net_id \\ @internet_id)

  def verify_bounce_params(
    bounce_id = %Bounce.ID{}, gateway, endpoint, entity, network_id)
  do
    verify_bounce_params(
      BounceQuery.fetch(bounce_id), gateway, endpoint, entity, network_id
    )
  end

  def verify_bounce_params(
    bounce, gateway = %Server{}, endpoint_id, entity_id, network_id)
  do
    verify_bounce_params(
      bounce, gateway.server_id, endpoint_id, entity_id, network_id
    )
  end

  def verify_bounce_params(
    bounce, gateway, endpoint = %Server{}, entity, network_id)
  do
    verify_bounce_params(
      bounce, gateway, endpoint.server_id, entity, network_id
    )
  end

  def verify_bounce_params(
    bounce, gateway_id, endpoint_id, entity = %Entity{}, network_id)
  do
    verify_bounce_params(
      bounce, gateway_id, endpoint_id, entity.entity_id, network_id
    )
  end

  def verify_bounce_params(
    bounce = %Bounce{},
    gateway_id = %Server.ID{},
    endpoint_id = %Server.ID{},
    entity_id = %Entity.ID{},
    network_id)
  do
    gateway_ip = ServerHelper.get_ip(gateway_id, network_id)
    endpoint_ip = ServerHelper.get_ip(endpoint_id, network_id)

    {
      bounce.links,
      {gateway_id, network_id, gateway_ip},
      {endpoint_id, network_id, endpoint_ip},
      entity_id
    }
  end
end
