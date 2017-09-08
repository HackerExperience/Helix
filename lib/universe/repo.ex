defmodule Helix.Universe.Repo do
  use Ecto.Repo, otp_app: :helix

  # HACK: ExUnit + Ecto.Sandbox do not play well with serializable
  @serializable (if Mix.env == :test,
    do: "",
    else: "SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")

  def serializable_transaction do
    __MODULE__.transaction(fn ->
      Ecto.Adapters.SQL.query(__MODULE__, @serializable)
    end)
  end
end
