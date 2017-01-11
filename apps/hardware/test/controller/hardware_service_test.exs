defmodule Helix.Hardware.Controller.HardwareServiceTest do

  use ExUnit.Case, async: false

  alias HELF.Broker
  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController

  @moduletag :umbrella

  describe "after account creation" do
    setup do
      ref = make_ref()

      Broker.subscribe("event:motherboard:setup", cast: fn pid, _, data, _ ->
        send pid, {ref, data}
      end)

      email = Burette.Internet.email()
      password = Burette.Internet.password()
      params = %{
        email: email,
        password_confirmation: password,
        password: password}

      case Broker.call("account:create", params) do
        {_, {:ok, _}} ->
          {:ok, ref: ref}
        _ ->
          :error
      end
    end

    test "motherboard is created",  %{ref: ref} do
      assert_receive {^ref, %{motherboard_id: motherboard_id}}, 5_000
      assert {:ok, _} = MotherboardController.find(motherboard_id)
    end

    test "motherboard slots are created", %{ref: ref} do
      assert_receive {^ref, event}, 5_000
      slots = MotherboardSlotController.find_by(motherboard_id: event.motherboard_id)

      refute Enum.empty?(slots)
    end

    test "motherboard slots are linked", %{ref: ref} do
      assert_receive {^ref, event}, 5_000
      slots = MotherboardSlotController.find_by(motherboard_id: event.motherboard_id)

      Enum.each(slots, fn slot ->
        assert slot.link_component_id
      end)
    end
  end
end