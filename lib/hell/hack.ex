###########################################
# IGNORE THE FOLLOWING LINES.
# Dialyzer is not particularly a fan of protocols, so it will emit a lot of
# "unknown functions" for non-implemented types on a protocol. This hack will
# implement any possible type to avoid those warnings (albeit it might increase
# the compilation time in a second)
###########################################

defmodule HELL.Hack.Experience do

  defmacro protocolols do

    protocols = [
      Helix.Cache.Model.Cacheable,
      Helix.Event.Notificable,
      Helix.Websocket.Requestable,
      Helix.Websocket.Joinable,
      Helix.Process.Model.Process.ProcessType,
      Helix.Process.Public.View.ProcessViewable,
    ]

    methods = %{
      "Elixir.Helix.Cache.Model.Cacheable" => [{:format_output, 1}],
      "Elixir.Helix.Event.Notificable" => [
        {:whom_to_notify, 1},
        {:generate_payload, 2}
      ],
      "Elixir.Helix.Websocket.Requestable" => [
        {:check_params, 2},
        {:check_permissions, 2},
        {:handle_request, 2},
        {:reply, 2}
      ],
      "Elixir.Helix.Websocket.Joinable" => [
        {:check_params, 2},
        {:check_permissions, 2},
        {:join, 3}
      ],
      "Elixir.Helix.Process.Model.Process.ProcessType" => [
        {:dynamic_resources, 1},
        {:state_change, 4},
        {:kill, 3},
        {:minimum, 1},
        {:conclusion, 2}
      ],
      "Elixir.Helix.Process.Public.View.ProcessViewable" => [
        {:render, 4}
      ]
    }

    impls = [
      Atom,
      BitString,
      Float,
      Function,
      Integer,
      List,
      Map,
      PID,
      Port,
      Reference,
      Tuple
    ]

    Enum.map(protocols, fn protocol ->
      functions = methods[to_string(protocol)]

      for impl <- impls do
        quote do
          defimpl unquote(protocol), for: unquote(impl) do

            unquote (
              Enum.map(functions, fn {name, arity} ->
                args = List.duplicate(quote do _ end, arity)

                quote do
                  def unquote(name)(unquote_splicing(args)) do
                    raise \
                      "#{inspect unquote(protocol)} not implemented " <>
                      "for #{inspect unquote(impl)}"
                  end
                end
              end)
            )
          end
        end
      end
    end)
  end
end

defmodule HELL.Hack.Experience2 do
  require HELL.Hack.Experience

  HELL.Hack.Experience.protocolols()
end