{:ok, _} = Application.ensure_all_started(:helf_router)
{:ok, _} = Application.ensure_all_started(:helf_broker)
{:ok, _} = Application.ensure_all_started(:account)
ExUnit.start()
