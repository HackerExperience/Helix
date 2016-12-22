alias HELM.Hardware.Repo
alias HELM.Hardware.Controller.ComponentSpec, as: ComponentSpecController
alias HELM.Hardware.Model.ComponentType

Repo.transaction fn ->
  mobo_params = %{
    component_type: "mobo",
    spec: %{
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
          type: "usb"
        },
        "4" => %{
          type: "nic"
        }
      }
    }
  }

  cpu_params = %{
    component_type: "cpu",
    spec: %{
      spec_type: "cpu",
    }
  }

  ram_params = %{
    component_type: "ram",
    spec: %{
      spec_type: "ram"
    }
  }

  hdd_params = %{
    component_type: "hdd",
    spec: %{
      spec_type: "hdd"
    }
  }

  usb_params = %{
    component_type: "usb",
    spec: %{
      spec_type: "usb"
    }
  }

  nic_params = %{
    component_type: "nic",
    spec: %{
      spec_type: "nic"
    }
  }

  spec_params = [
    mobo_params,
    cpu_params,
    ram_params,
    hdd_params,
    usb_params,
    nic_params
  ]

  Enum.map(spec_params, fn params ->
    {:ok, spec} = ComponentSpecController.create(params)
    spec
  end)
end