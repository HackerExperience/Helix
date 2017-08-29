defmodule Helix.Test.Channel.Helper do

  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server

  def to_topic(server_id = %Server.ID{}),
    do: "server:" <> to_string(server_id)
  def to_topic(account_id = %Account.ID{}),
    do: "account:" <> to_string(account_id)
  def to_topic(entity_id = %Entity.ID{}),
    do: "account:" <> to_string(entity_id)
end
