defmodule Helix.Test.Story.StepHelper do

  alias Helix.Entity.Model.Entity

  def all_steps do
    [
      %{
        name: :fake_steps@test_meta,
        meta: %{foo: :bar, id: Entity.ID.generate()}
      },
      %{
        name: :fake_steps@test_simple,
        meta: %{}
      },
      %{
        name: :fake_steps@test_one,
        meta: %{step: :one}
      },
      %{
        name: :fake_steps@test_two,
        meta: %{step: :two}
      },
      %{
        name: :fake_steps@test_counter,
        meta: %{i: 0}
      }
    ]
  end

  def random_step,
    do: Enum.random(all_steps())

  def get_contact,
    do: :test_contact
end

defmodule Helix.Story.Mission.FakeSteps do

  import Helix.Story.Model.Step.Macros

  contact :test_contact

  step TestMeta do

    alias Helix.Entity.Model.Entity

    def setup(step, _),
      do: {:ok, step, []}

    def complete(step),
      do: {:ok, step, []}

    @doc """
    Meta format:
    %{
      foo: :bar,
      entity_id: Entity.id,
    }
    """
    def format_meta(%{meta: meta}) do
      %{
        foo: String.to_existing_atom(meta["foo"]),
        id: Entity.ID.cast!(meta["id"])
      }
    end

    next_step __MODULE__
  end

  step TestSimple do
    def setup(step, _),
      do: {:ok, step, []}
    def complete(step),
      do: {:ok, step, []}
    next_step __MODULE__
  end

  step TestOne do
    def setup(step, _),
      do: {:ok, step, []}

    def complete(step),
      do: {:ok, step, []}

    def format_meta(%{meta: meta}),
      do: %{step: String.to_existing_atom(meta["step"])}

    next_step Helix.Story.Mission.FakeSteps.TestTwo
  end

  step TestTwo do
    def setup(step, _),
      do: {:ok, step, []}

    def complete(step),
      do: {:ok, step, []}

    def format_meta(%{meta: meta}),
      do: %{step: String.to_existing_atom(meta["step"])}
    next_step __MODULE__
  end

  step TestCounter do
    def setup(step, _),
      do: {:ok, step, []}

    def complete(step),
      do: {:ok, step, []}

    def format_meta(%{meta: meta}),
      do: %{i: meta["i"]}
    next_step __MODULE__
  end

  step TestMsg do
    email "e1",
      reply: ["reply_to_e1"],
      locked: ["locked_reply_to_e1"]

    email "e2",
      reply: ["reply_to_e2"]

    email "e3",
      reply: ["reply_to_e3"]

    on_reply "reply_to_e1" do
      raise "replied_to_e1"
    end

    on_reply "reply_to_e2",
      send: "e3"

    on_reply "reply_to_e3",
      complete: true

    def setup(step, _) do
      send_email step, "e1"
      {:ok, step, []}
    end

    def complete(step),
      do: {:ok, step, []}

    next_step Helix.Story.Mission.FakeSteps.TestSimple
  end
end
