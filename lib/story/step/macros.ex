defmodule Helix.Story.Step.Macros do

  alias Helix.Story.Step

  defmacro step(name, do: block) do
    quote do
      defmodule unquote(name) do

        require Helix.Story.Step

        Helix.Story.Step.register()

        defimpl Helix.Story.Steppable do
          unquote(block)

          def fail(_step) do
            raise \
              "Fail handler not implemented for" <>
              "#{inspect unquote(__MODULE__)}"
          end
        end
      end
    end
  end

  defmacro next_step(step_module) do
    quote do
      # unless Code.ensure_compiled?(unquote(step_module)) do
      #   raise "The step #{inspect unquote(step_module)} does not exist"
      # end
      # Verification above is only possible if
      #   1 - We manage to verify on a second round of compilation; OR
      #   2 - We can force the `step_module` to be compiled first; OR
      #   3 - We store each step on a separate file; OR
      #   4 - We sort steps.ex from the last to the first step.
      # I don't want neither 3 or 4. Waiting for a cool hack on 1 or 2.

      def next_step(_) do
        Helix.Story.Step.get_step_name(unquote(step_module))
      end
    end
  end
  defmacro email(email_id, opts \\ []) do
    prev_emails = get_emails(__CALLER__) || %{}
    email = add_email(email_id, opts)

    emails = Map.merge(prev_emails, email)

    set_emails(__CALLER__, emails)
  end

  defmacro send_email(email_id, entity_id, args \\ %{}) do
    emails = get_emails(__CALLER__) || %{}

    unless email_exists?(emails, email_id) do
      raise \
        "cant send email #{inspect email_id} on step " <>
        "#{inspect unquote(__MODULE__)}; undefined"
    end

    # Email.send(entity_id, char_id, email_id, email_meta)
    # Step.save_email(entity_id, step_name, email_id)
  end

  defmacro setup(entity_var, prev_step_var \\ quote(do: _), block) do
    contents =
      quote do
        unquote(block)
        :ok
      end

    entity = Macro.escape(entity_var)
    prev_step = Macro.escape(prev_step_var)
    contents = Macro.escape(contents, unquote: true)

    quote \
      bind_quoted: [entity: entity, prev_step: prev_step, contents: contents]
    do
      def setup(unquote(entity), unquote(prev_step)), do: unquote(contents)
    end
  end

  defmacro filter(step, event, meta, opts) do
    case opts do
      [do: block] ->
        quote do
          def handle_event(unquote(step), unquote(event), unquote(meta)) do
            unquote(block)
          end
        end
      [send: email_id] ->
        quote do
          def handle_event(unquote(step), unquote(event), _meta) do
            send_email \
              unquote(email_id),
              step.entity_id,
              Keyword.get(opts, :meta, %{})
            {:noop, unquote(step)}
          end
        end
      [complete: true] ->
        quote do
          def handle_event(unquote(step), _event, _meta) do
            {:complete, unquote(step)}
          end
        end
      [fail: true] ->
        quote do
          def handle_event(unquote(step), _event, _meta) do
            {:fail, unquote(step)}
          end
        end
    end
  end

  defmacro on_reply(reply_id, opts) do

    # Emails that can receive this reply
    emails = get_emails(__CALLER__)
    valid_emails = get_emails_with_reply(emails, reply_id)

    for email <- valid_emails do
      quote do
        def handle_event(step, %{email: unquote(email), reply: unquote(reply_id)}, _meta) do
          unquote(
            case opts do
              [send: email_id] ->
                quote do
                  send_email \
                    unquote(email_id),
                    step.entity_id,
                    Keyword.get(opts, :meta, %{})
                  {:noop, step}
                end
              [do: block] ->
                quote do
                  unquote(block)
                end
              [complete: true] ->
                quote do
                  {:complete, step}
                end
              _ ->
                quote do
                  {:noop, step}
                end
            end
          )
        end
      end
    end
  end

  defp ensure_list(nil),
    do: []
  defp ensure_list(value) when is_list(value),
    do: value
  defp ensure_list(value),
    do: [value]

  @spec add_email(Step.email_id, term) ::
    Step.emails
  defp add_email(email_id, opts) do
    metadata = %{
      id: email_id,
      replies: ensure_list(opts[:reply]),
      locked: ensure_list(opts[:locked])
    }

    Map.put(%{}, email_id, metadata)
  end

  @spec get_emails_with_reply(Step.emails, Step.reply_id) ::
    [Step.email_id]
  defp get_emails_with_reply(emails, reply_id) do
    Enum.reduce(emails, [], fn {id, email}, acc ->
      cond do
        Enum.member?(email.replies, reply_id) ->
          acc ++ [email.id]
        Enum.member?(email.locked, reply_id) ->
          acc ++ [email.id]
        true ->
          acc
      end
    end)
  end

  @spec email_exists?(Step.emails, Step.email_id) ::
    bool
  defp email_exists?(emails, email_id) do
    Map.get(emails, email_id, false) && true
  end

  @spec get_emails(Macro.Env.t) ::
    Step.emails
    | nil
  defp get_emails(%Macro.Env{module: module}),
    do: Module.get_attribute(module, :emails)

  @spec set_emails(Macro.Env.t, Step.emails) ::
    :ok
  defp set_emails(%Macro.Env{module: module}, emails),
    do: Module.put_attribute(module, :emails, emails)

end
