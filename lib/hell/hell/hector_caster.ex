defmodule HELL.Hector do

  alias HELL.Utils
  alias Helix.Server.Model.Server

  def caster(type, value) do
    case type do
      :server_id ->
        cast(Server.ID, value)
      _ ->
        has_id? = Utils.atom_contains?(value, "_id")

        if has_id? do
          raise "Unhandled id of type #{inspect type} for #{inspect value}"
        else
          Hector.std_caster(type, value)
        end
    end
  end

  def cast(module, value) do
    with {:ok, _} <- apply(module, :cast, [value]) do
      to_string(value)
    end
  end
end
