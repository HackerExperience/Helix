defmodule Helix.Server.Websocket.View.ServerChannel do

  @type join_error_reason ::
    :not_owner
    | :not_assembled
    | :not_found
    | :password

  @spec render_join_error({:error, {:gateway | :server, join_error_reason}}) ::
    %{data: %{message: String.t}, status: :error | :internal_error}
  def render_join_error({:error, {:gateway, :not_owner}}),
    do: error("User is not server owner")
  def render_join_error({:error, {:gateway, :not_assembled}}),
    do: error("Gateway is not functioning")
  def render_join_error({:error, {:server, :not_found}}),
    do: error("Target server not found")
  def render_join_error({:error, {:server, :not_assembled}}),
    do: error("Target server is not functioning")
  def render_join_error({:error, {:server, :password}}),
    do: error("Target server password is invalid")
  def render_join_error(_),
    do: internal_error("An unexpected error occurred")

  @spec error(String.t) ::
    %{data: %{message: String.t}, status: :error}
  defp error(message),
    do: %{data: %{message: message}, status: :error}

  @spec internal_error(String.t) ::
    %{data: %{message: String.t}, status: :internal_error}
  defp internal_error(message),
    do: %{data: %{message: message}, status: :internal_error}
end
