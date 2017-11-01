defmodule Helix.Test.Event.Setup do

  alias Helix.Server.Model.Server

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
  def process_created(gateway_id, target_id) do
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

  @doc """
  Opts:
    - gateway_id: Specify the gateway id.
    - target_id: Specify the target id.
    - gateway_entity_id: Specify the gateway entity id.

  Note the generated process is fake (does not exist on DB).
  """
  def process_created(type, opts \\ [])
  def process_created(:single_server, opts) do
    gateway_id = Access.get(opts, :gateway_id, Server.ID.generate())

    process_created(gateway_id, gateway_id)
  end
  def process_created(:multi_server, opts) do
    gateway_id = Access.get(opts, :gateway_id, Server.ID.generate())

    target_id = Access.get(opts, :target_id, Server.ID.generate())

    process_created(gateway_id, target_id)
  end
end
