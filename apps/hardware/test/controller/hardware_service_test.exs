defmodule Helix.Hardware.Controller.HardwareServiceTest do

  use ExUnit.Case, async: true

  alias HELF.Broker
  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController

  @moduletag :umbrella

  defp forward_event(event) do
    ref = make_ref()
    Broker.subscribe(event, cast: fn pid, _, data, _ ->
      send pid, {ref, data}
    end)
    ref
  end

  describe "after account creation" do
    setup do
      email = Burette.Internet.email()
      password = Burette.Internet.password()
      params = %{email: email, password_confirmation: password, password: password}
      {_, {:ok, _}} = Broker.call("account:create", params)

      :ok
    end

    test "motherboard is created" do
      ref_create = forward_event("event:motherboard:created")
      ref_setup = forward_event("event:motherboard:setup")

      assert_receive {^ref_create, motherboard_id}, 5_000
      assert_receive {^ref_setup, {^motherboard_id, _}}, 5_000

      assert {:ok, _} = MotherboardController.find(motherboard_id)
    end

    test "motherboard slots are created" do
      ref = forward_event("event:motherboard:setup")
      assert_receive {^ref, {motherboard_id, _}}, 5_000
      slots = MotherboardSlotController.find_by(motherboard_id: motherboard_id)

      refute Enum.empty?(slots)
    end

    test "motherboard slots are linked" do
      ref = forward_event("event:motherboard:setup")
      assert_receive {^ref, {motherboard_id, _}}, 5_000
      slots = MotherboardSlotController.find_by(motherboard_id: motherboard_id)

      Enum.each(slots, fn slot ->
        assert slot.link_component_id
      end)
    end
  end
end