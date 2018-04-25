defmodule Helix.Core.Validator do

  @type input_type ::
    :password
    | :hostname
    | :bounce_name
    | :reply_id

  @regex_hostname ~r/^[a-zA-Z0-9-_.@#]{1,20}$/

  @regex_token ~r/^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/

  @spec validate_input(input :: String.t, input_type, opts :: term) ::
    {:ok, validated_input :: String.t}
    | :error
  @doc """
  This is a generic function meant to validate external input that does not
  conform to a specific shape or format (like internal IDs or IP addresses).

  The `type` argument identifies what the input is supposed to represent, and
  we leverage this information to customize the validation for different kinds
  of input.
  """
  def validate_input(input, type, opts \\ [])

  def validate_input(input, :password, _),
    do: validate_password(input)

  def validate_input(input, :money, _),
    do: validate_money(input)

  def validate_input(input, :hostname, _),
    do: validate_hostname(input)

  def validate_input(input, :bounce_name, _),
    do: validate_bounce_name(input)

  def validate_input(input, :reply_id, _),
    do: validate_reply_id(input)

  def validate_input(input, :token, _),
    do: validate_token(input)

  defp validate_hostname(v) when not is_binary(v),
    do: :error
  defp validate_hostname(v) do
    if Regex.match?(@regex_hostname, v) do
      {:ok, v}
    else
      :error
    end
  end

  defp validate_token(v) when not is_binary(v),
    do: :error
  defp validate_token(v) do
    if Regex.match?(@regex_token, v) do
      {:ok, v}
    else
      :error
    end
  end

  defp validate_password(input),
    do: validate_hostname(input)  # TODO

  defp validate_bounce_name(v),
    do: validate_hostname(v)  # TODO

  defp validate_reply_id(v),
    do: validate_hostname(v)  # TODO

  defp validate_money(v),
    do: validate_hostname(v)
end
