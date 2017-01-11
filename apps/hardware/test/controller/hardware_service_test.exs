defmodule Helix.Hardware.Controller.HardwareServiceTest do

  use ExUnit.Case, async: false

  alias HELF.Broker
  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController
  alias Helix.Hardware.Model.MotherboardSlot, as: MotherboardSlot

  @moduletag :umbrella

  defp forward_broker_cast(topic) do
    ref = make_ref()

    Broker.subscribe(topic, cast: fn pid, _, data, _ ->
      send pid, {ref, data}
    end)

    ref
  end

  defp create_account do
    email = Burette.Internet.email()
    password = Burette.Internet.password()
    params = %{
      email: email,
      password_confirmation: password,
      password: password}

    case Broker.call("account:create", params) do
      {_, {:ok, account}} ->
        {:ok, account}
      {_, {:error, error}} ->
        {:error, error}
    end
  end

  describe "after account creation" do
    test "motherboard is created" do
      ref = forward_broker_cast("event:motherboard:created")
      create_account()
      assert_receive {^ref, %{motherboard_id: motherboard_id}}

      assert {:ok, _} = MotherboardController.find(motherboard_id)
    end

    test "motherboard slots are created" do
      ref = forward_broker_cast("event:motherboard:created")
      create_account()
      assert_receive {^ref, event}

      slots = MotherboardController.get_slots(event.motherboard_id)
      refute Enum.empty?(slots)
    end

    test "motherboard linked at least a single of each slot type" do
      ref = forward_broker_cast("event:motherboard:created")
      create_account()
      assert_receive {^ref, event}

      linked_every_slot_group =
        event.motherboard_id
        |> MotherboardController.get_slots()
        |> Enum.group_by(&(&1.link_component_type))
        |> Enum.map(fn {key, slots} ->
          slots
          |> Enum.filter(&MotherboardSlot.linked?/1)
          |> length() > 0
        end)
        |> Enum.reduce(&(&1 and &2))

      assert true === linked_every_slot_group
    end
  end
end