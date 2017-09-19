defmodule Helix.Story.Model.Step.Macros do

  alias HELL.Constant
  alias Helix.Story.Model.Step

  defmacro step(name, contact \\ nil, do: block) do
    quote do
      defmodule unquote(name) do

        require Helix.Story.Model.Step

        Helix.Story.Model.Step.register()

        defimpl Helix.Story.Model.Steppable do

          alias Helix.Story.Action.Story, as: StoryAction

          @contact get_contact(unquote(contact), __MODULE__)
          @step_name Helix.Story.Model.Step.get_name(unquote(name))

          unquote(block)

          # Most steps do not have a "fail" option. Those who do must manually
          # implement this protocol function.
          def fail(_step),
            do: raise "Undefined fail handler at #{inspect unquote(__MODULE__)}"

          # Catch-all for unhandled events, otherwise any unexpected event would
          # thrown an exception here.
          def handle_event(step, _event, _meta),
            do: {:noop, step, []}

          def get_contact(_),
            do: @contact

        end
      end
    end
  end

  defmacro next_step(next_step_module) do
    quote do
      # unless Code.ensure_compiled?(unquote(next_step_module)) do
      #   raise "The step #{inspect unquote(next_step_module)} does not exist"
      # end
      # Verification above is only possible if
      #   1 - We manage to verify on a second round of compilation; OR
      #   2 - We can force the `step_module` to be compiled first; OR
      #   3 - We store each step on a separate file; OR
      #   4 - We sort steps.ex from the last to the first step.
      # I don't want neither 3 or 4. Waiting for a cool hack on 1 or 2.

      def next_step(_),
        do: Helix.Story.Model.Step.get_name(unquote(next_step_module))
    end
  end

  defmacro email(email_id, opts \\ []) do
    prev_emails = get_emails(__CALLER__) || %{}
    email = add_email(email_id, opts)

    emails = Map.merge(prev_emails, email)

    set_emails(__CALLER__, emails)
  end

  defmacro send_email(step, email_id, email_meta \\ quote(do: %{})) do
    emails = get_emails(__CALLER__) || %{}

    unless email_exists?(emails, email_id) do
      raise \
        "cant send email #{inspect email_id} on step " <>
        "#{inspect __CALLER__.module}; undefined"
    end

    quote do
      {:ok, events} =
        StoryAction.send_email(
          unquote(step),
          unquote(email_id),
          unquote(email_meta)
        )

      events
    end
  end

  defmacro filter(step, event, meta, opts) do
    quote do
      def handle_event(unquote(step), unquote(event), unquote(meta)) do
        unquote(
          case opts do
            [do: block] ->
              block
            [send: email_id] ->
              quote do
                event =
                  send_email \
                    unquote(step),
                    unquote(email_id),
                    Keyword.get(unquote(opts), :meta, %{})
                {:noop, unquote(step), event}
              end
            [complete: true] ->
              quote do
                {:complete, unquote(step), []}
              end
            [fail: true] ->
              quote do
                {:fail, unquote(step), []}
              end
          end
        )
      end
    end
  end

  defmacro on_reply(reply_id, opts) do
    # Emails that can receive this reply
    emails = get_emails(__CALLER__)
    valid_emails = get_emails_with_reply(emails, reply_id)

    for email <- valid_emails do
      quote do
        def handle_event(
          step,
          %{email: unquote(email), reply: unquote(reply_id)},
          _meta)
        do
          unquote(
            case opts do
              [send: email_id] ->
                quote do
                  event =
                    send_email \
                      step,
                      unquote(email_id),
                      Keyword.get(unquote(opts), :meta, %{})
                  {:noop, step, event}
                end
              [do: block] ->
                quote do
                  unquote(block)
                end
              [complete: true] ->
                quote do
                  {:complete, step, []}
                end
              _ ->
                quote do
                  {:noop, step, []}
                end
            end
          )
        end
      end
    end
  end

  @doc """
  Below macro is required so the elixir compiler does not complain about the
  module attribute not being used.
  """
  defmacro contact(contact_name) do
    quote do
      @contact unquote(contact_name)
    end
  end

  @spec get_contact(String.t | Constant.t | nil, module :: term) ::
    contact :: Step.contact
  @doc """
  If the given contact is a string or atom, then the `step` explicitly specified
  a contact. On the other hand, if it's not a string/atom (defaults to `nil`),
  then no contact was specified at the step level. In this case, we'll fall back
  to the contact defined for the mission. This is the most common scenario.
  """
  def get_contact(contact, _) when is_binary(contact),
    do: String.to_atom(contact)
  def get_contact(contact, _) when is_atom(contact),
    do: contact
  def get_contact(_, step_module) do
    mission_contact =
      step_module
      |> Module.split()
      |> Enum.drop(4)  # Remove protocol namespace
      |> Enum.drop(-1)  # Get parent
      |> Module.concat()
      |> Module.get_attribute(:contact)

    if is_nil(mission_contact),
      do: raise "No contact for top-level mission at #{inspect step_module}"

    get_contact(mission_contact, step_module)
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
          acc ++ [id]
        Enum.member?(email.locked, reply_id) ->
          acc ++ [id]
        true ->
          acc
      end
    end)
  end

  @spec email_exists?(Step.emails, Step.email_id) ::
    boolean
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
