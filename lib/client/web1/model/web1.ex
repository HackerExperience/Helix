defmodule Helix.Client.Web1.Model.Web1 do

  @type action :: :tutorial_accessed_task_manager

  @actions [:tutorial_accessed_task_manager]
  @actions_str Enum.map(@actions, &to_string/1)

  def valid_actions,
    do: @actions
  def valid_actions_str,
    do: @actions_str
end
