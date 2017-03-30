defmodule Helix.Account.WS.View.Account do

  alias Helix.Account.Model.Account
  alias Ecto.Changeset

  # TODO: Use a protocol

  def format(acc = %Account{}) do
    acc
    |> Map.take([:account_id, :email])
    |> Map.put(:username, acc.display_name)
  end

  def format(cs = %Changeset{}) do
    Changeset.traverse_errors(cs, fn {message, _opts} ->
      message
    end)
  end

  def format(value) do
    value
  end
end
