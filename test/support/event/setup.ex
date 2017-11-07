defmodule Helix.Test.Event.Setup do

  alias Helix.Process.Event.Process.Created, as: ProcessCreatedEvent

  alias HELL.TestHelper.Random
  alias Helix.Test.Process.Setup, as: ProcessSetup

  ##############################################################################
  # Process events
  ##############################################################################

  @doc """
  Accepts:

  - (gateway :: Server.ID, target :: Server.ID, gateway_entity :: Entity.ID),
    in which case a fake process with random ID is generated
  """
  def process_created(a, b) do
  end
end

defmodule Helix.Test.Event.Setup.Process do

  alias Helix.Process.Event.Process.Created, as: ProcessCreatedEvent
  alias Helix.Server.Model.Server

  alias HELL.TestHelper.Random
  alias Helix.Test.Process.Setup, as: ProcessSetup

  def created,
    do: created(Server.ID.generate(), Server.ID.generate())

  def created(gateway_id),
    do: created(gateway_id, gateway_id)

  def created(gateway_id, target_id) do
    # Generates a random process on the given server(s)
    process_opts = [gateway_id: gateway_id, target_id: target_id]
    {process, _} = ProcessSetup.fake_process(process_opts)

    %ProcessCreatedEvent{
      confirmed: true,
      process: process,
      gateway_id: gateway_id,
      target_id: target_id,
      gateway_ip: Random.ipv4(),
      target_ip: Random.ipv4()
    }
  end
end
