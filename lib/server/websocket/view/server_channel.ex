defmodule Helix.Server.Websocket.View.ServerChannel do

  @spec render_join_error({:error, {:gateway | :server, :not_owner | :not_assembled | :not_found | :password}}) ::
    %{type: String.t, data: %{message: String.t}}
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

  @spec error(String.t) ::
    %{type: String.t, data: %{message: String.t}}
  defp error(message),
    do: %{type: "error", data: %{message: message}}
end
