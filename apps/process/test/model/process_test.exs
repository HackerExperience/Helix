defmodule Helix.Process.Model.ProcessTest do

  use ExUnit.Case

  alias Ecto.Changeset
  alias Helix.Process.Model.Process

  defp error_fields(changeset) do
    changeset
    |> Changeset.traverse_errors(&(&1))
    |> Map.keys()
  end

  describe "software data" do
    test "software data must be a struct" do
      p = Process.create_changeset(%{software: %{foo: :bar}})

      assert :software in error_fields(p)
    end

    test "a struct is only valid if it implements SoftwareType protocol" do
      p = Process.create_changeset(%{software: %File.Stream{}})

      assert :software in error_fields(p)
    end

    @tag :pending
    test "as long as the struct implements SoftwareType, everything will be alright" do
      p = Process.create_changeset(%{software: %{}})

      refute :software in error_fields(p)
    end
  end

  describe "objective" do
    test "objective is optional" do
      p = Process.create_changeset(%{})
      refute :objective in error_fields(p)
    end

    test "objective is a map whose values are integers" do
      p = Process.create_changeset(%{objective: %{cpu: :foo}})
      assert :objective in error_fields(p)

      p = Process.create_changeset(%{objective: :foo})
      assert :objective in error_fields(p)

      p = Process.create_changeset(%{objective: %{cpu: 0.5}})
      assert :objective in error_fields(p)

      p = Process.create_changeset(%{objective: %{cpu: 50}})
      refute :objective in error_fields(p)
    end

    test "objective values must be non-negative" do
      p = Process.create_changeset(%{objective: %{cpu: -50}})
      assert :objective in error_fields(p)
    end
  end

  describe "ttl" do
    test "seconds_to_change defaults to nil if nothing is going to change" do
      now = DateTime.from_unix!(1470000000)

      p =
        %{objective: %{cpu: 50}}
        |> Process.create_changeset()
        |> Process.update_changeset(%{allocated: %{cpu: 0, dlk: 0}, updated_time: now})
        |> Changeset.apply_changes()

      refute Process.seconds_to_change(p)
    end

    test "seconds_to_change returns amount of seconds to the next change on a process resource consumption" do
      now = DateTime.from_unix!(1470000000)

      p =
        %{objective: %{cpu: 50, dlk: 100}}
        |> Process.create_changeset()
        |> Process.update_changeset(%{allocated: %{cpu: 10, dlk: 10}, updated_time: now})
        |> Changeset.apply_changes()

      assert 5 === Process.seconds_to_change(p)
    end

    test "estimate_conclusion is the value of the longest-to-complete objective (or nil if infinity)" do
      now = DateTime.from_unix!(1470000000)

      p =
        %{objective: %{cpu: 50, dlk: 100}}
        |> Process.create_changeset()
        |> Process.update_changeset(%{allocated: %{dlk: 10}, updated_time: now})
        |> Changeset.apply_changes()

      p1 = Process.estimate_conclusion(p)

      refute p1.estimated_time

      p2 =
        p
        |> Process.update_changeset(%{allocated: %{cpu: 1, dlk: 10}})
        |> Changeset.apply_changes()
        |> Process.estimate_conclusion()

      future = DateTime.from_unix!(1470000050)

      assert :eq === DateTime.compare(future, p2.estimated_time)
    end
  end
end