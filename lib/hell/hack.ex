###########################################
# IGNORE THE FOLLOWING LINES.
# Dialyzer is not particularly a fan of protocols, so it will emit a lot of
# "unknown functions" for non-implemented types on a protocol. This hack will
# implement any possible type to avoid those warnings (albeit it might increase
# the compilation time in a second)
###########################################
defmodule HELL.Hack.Experience do
  @moduledoc false

  defmacro protocolols do

    protocols = [
      Helix.Event.Listenable,
      Helix.Event.Loggable,
      Helix.Event.Notificable,
      Helix.Event.Publishable,
      Helix.Websocket.Requestable,
      Helix.Websocket.Joinable,
      Helix.Cache.Model.Cacheable,
      Helix.Process.Model.Processable,
      Helix.Process.Public.View.ProcessViewable,
      Helix.Story.Model.Steppable
    ]

    methods = %{
      "Elixir.Helix.Cache.Model.Cacheable" => [{:format_output, 1}],
      "Elixir.Helix.Event.Publishable" => [
        {:whom_to_publish, 1},
        {:generate_payload, 2},
        {:get_event_name, 1}
      ],
      "Elixir.Helix.Event.Notificable" => [
        {:whom_to_notify, 1},
        {:get_notification_info, 1},
        {:extra_params, 1}
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
        {:join, 3},
        {:log_error, 3}
      ],
      "Elixir.Helix.Process.Model.Processable" => [
        {:kill, 3},
        {:complete, 2},
        {:retarget, 2},
        {:source_connection_closed, 3},
        {:target_connection_closed, 3},
        {:target_log_revised, 3},
        {:target_log_recovered, 3},
        {:target_log_destroyed, 3},
        {:after_read_hook, 1}
      ],
      "Elixir.Helix.Process.Public.View.ProcessViewable" => [
        {:get_scope, 4},
        {:render, 3}
      ],
      "Elixir.Helix.Story.Model.Steppable" => [
        {:start, 1},
        {:setup, 1},
        {:handle_event, 3},
        {:complete, 1},
        {:restart, 3},
        {:next_step, 1},
        {:get_contact, 1},
        {:get_emails, 1},
        {:get_replies_of, 2},
        {:format_meta, 1},
      ],
      "Elixir.Helix.Event.Listenable" => [
        {:get_objects, 1}
      ],
      "Elixir.Helix.Event.Loggable" => [
        {:generate, 1}
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
          @doc false
          defimpl unquote(protocol), for: unquote(impl) do
            unquote (
              Enum.map(functions, fn {name, arity} ->
                args = List.duplicate(quote do _ end, arity)

                quote do
                  @doc false
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
  @moduledoc false

  require HELL.Hack.Experience

  HELL.Hack.Experience.protocolols()
end
