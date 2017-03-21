{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.configure(exclude: [:pending, :umbrella])

ExUnit.start()