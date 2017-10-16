defmodule Helix.Event.Loggable.Utils do
  @moduledoc """
  Utils for the Loggable protocol and underlying implementations. 
  """

  import HELL.Macros

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Software.Model.File

  @type log_file_name :: String.t
  @type unknown_ip :: String.t

  @unknown_ip "Unknown"

  @spec censor_ip(IPv4.t | unknown_ip) ::
    censored_ip :: IPv4.t | unknown_ip
  @doc """
  Replaces the last 5 numbers of the IP address with an 'x'.

  ### Examples:

  "123.123.123.123" => "123.123.1xx.xxx"
  "123.123.12.12" => "123.12x.xx.xx"
  "1.2.3.4" => "x.x.x.x"
  """
  def censor_ip(ip) do
    ip
    |> String.to_charlist()
    |> Enum.reverse()
    |> Enum.reduce({[], 0}, fn char, {output, num_replaces} ->
      if char_is_number?(char) and num_replaces < 5 do
        {output ++ 'x', num_replaces + 1}
      else
        {output ++ [char], num_replaces}
      end
    end)
    |> elem(0)
    |> Enum.reverse
    |> List.to_string()
  end

  @spec get_ip(Server.id, Network.id) ::
    IPv4.t
    | unknown_ip :: String.t
  @doc """
  Log-focused method to fetch a server IP address. Returns an empty string if
  the IP was not found.
  """
  def get_ip(server_id, network_id) do
    case ServerQuery.get_ip(server_id, network_id) do
      ip when is_binary(ip) ->
        ip
      nil ->
        @unknown_ip
    end
    |> format_ip()
  end

  @doc """
  Log-focused method to figure out the file name that should be logged.
  """
  @spec get_file_name(File.t) ::
    log_file_name
  def get_file_name(file = %File{}) do
    file.full_path
    |> String.split("/")
    |> List.last()
  end

  docp """
  Helper to verify whether the ASCII char is a number.
  48 is 0 and 57 is 9
  """
  defp char_is_number?(char),
    do: char >= 48 and char <= 57

  docp """
  Formats an IP address to the log display.
  """
  defp format_ip(ip),
    do: "[" <> ip <> "]"
end
