defmodule Helix.Hardware.Controller.HardwareServiceTest do

  use ExUnit.Case, async: false

  alias HELF.Broker
  alias Helix.Hardware.Repo
  alias Helix.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.MotherboardSlot

  @moduletag :umbrella

  setup_all do
    if is_nil Repo.get_by(ComponentSpec, spec_id: "MOBO01") do
      Repo.transaction fn ->
        mobo_params = %{
          component_type: "mobo",
          spec: %{
            spec_code: "MOBO01",
            spec_type: "mobo",
            slots: %{
              "0" => %{
                type: "cpu"
              },
              "1" => %{
                type: "ram"
              },
              "2" => %{
                type: "hdd"
              },
              "3" => %{
                type: "nic"
              }
            }
          }
        }

        cpu_params = %{
          component_type: "cpu",
          spec: %{
            spec_code: "CPU01",
            spec_type: "cpu",
          }
        }

        ram_params = %{
          component_type: "ram",
          spec: %{
            spec_code: "RAM01",
            spec_type: "ram"
          }
        }

        hdd_params = %{
          component_type: "hdd",
          spec: %{
            spec_code: "HDD01",
            spec_type: "hdd"
          }
        }

        nic_params = %{
          component_type: "nic",
          spec: %{
            spec_code: "NIC01",
            spec_type: "nic"
          }
        }

        spec_params = [
          mobo_params,
          cpu_params,
          ram_params,
          hdd_params,
          nic_params
        ]

        Enum.map(spec_params, fn params ->
          {:ok, spec} = ComponentSpecController.create(params)
          spec
        end)
      end
    end

    :ok
  end

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
      slots = MotherboardController.get_slots(event.motherboard_id)

      possible_types = MapSet.new(slots, &(&1.link_component_type))
      linked_types =
        slots
        |> Enum.filter(&MotherboardSlot.linked?/1)
        |> MapSet.new(&(&1.link_component_type))

      assert MapSet.equal?(possible_types, linked_types)
    end
  end
end