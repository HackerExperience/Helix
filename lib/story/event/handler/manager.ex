defmodule Helix.Story.Event.Handler.Manager do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Account.Model.Account
  alias Helix.Server.Action.Flow.Server, as: ServerFlow
  alias Helix.Server.Action.Flow.Motherboard, as: MotherboardFlow
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery
  alias Helix.Story.Action.Flow.Manager, as: ManagerFlow
  alias Helix.Story.Action.Flow.Story, as: StoryFlow

  alias Helix.Entity.Event.Entity.Created, as: EntityCreatedEvent

  def setup_story(
    event = %EntityCreatedEvent{entity: entity, source: %Account{}})
  do
    plan = %{dlk: 128, ulk: 16}  # TODO 341
    flowing do
      with \
        {:ok, _network, nc} <- ManagerFlow.setup_story_network(entity),
        {:ok, motherboard, mobo} <-
          MotherboardFlow.initial_hardware(entity, event),

        {:ok, server} <- ServerFlow.setup(:desktop_story, entity, mobo, event),

        [nic] = MotherboardQuery.get_nics(motherboard),
        {:ok, _, _} <- MotherboardFlow.setup_network(entity, nic, nc, plan),

        {:ok, _} <- StoryFlow.start_story(entity, event)
      do
        {:ok, server, motherboard}
      end
    end
  end
  def setup_story(%EntityCreatedEvent{source: _}),
    do: :noop
end
