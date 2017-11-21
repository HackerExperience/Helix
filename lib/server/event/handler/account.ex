defmodule Helix.Server.Handler.Server do

  alias Helix.Server.Action.Flow.Motherboard, as: MotherboardFlow

  def account_verified(event) do

    event.entity
    |> MotherboardFlow.initial_hardware(event)
  end
end
