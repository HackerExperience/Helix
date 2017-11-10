defmodule Helix.Test.Event.Setup.Process do

  alias Helix.Process.Event.Process.Created, as: ProcessCreatedEvent

  alias HELL.TestHelper.Random
  alias Helix.Test.Process.Setup, as: ProcessSetup

  def created(opts \\ []) do
    {process, _} = ProcessSetup.fake_process(opts)

    %ProcessCreatedEvent{
      confirmed: true,
      process: process,
      gateway_id: process.gateway_id,
      target_id: process.target_id,
      gateway_ip: Random.ipv4(),
      target_ip: Random.ipv4()
    }
  end
end
