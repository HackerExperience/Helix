alias Helix.Hardware.Repo
alias Helix.Hardware.Model.ComponentSpec

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

  Enum.each(spec_params, fn params ->
    params
    |> ComponentSpec.create_changeset()
    |> Repo.insert(on_conflict: :nothing)
  end)
end