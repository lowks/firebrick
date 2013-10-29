defmodule SmtpHandler do
  # @behaviour :gen_smtp_server_session


# -export([init/4, handle_HELO/2, handle_EHLO/3, handle_MAIL/2, handle_MAIL_extension/2,
#   handle_RCPT/2, handle_RCPT_extension/2, handle_DATA/4, handle_RSET/1, handle_VRFY/2,
#   handle_other/3, handle_AUTH/4, handle_STARTTLS/1, code_change/3, terminate/2]).

  @relay true

  defrecord State, options: [] do
    record_type options: list
  end

  @type error_message :: {:error, String.t, State.t}

# %% @doc Initialize the callback module's state for a new session.
# %% The arguments to the function are the SMTP server's hostname (for use in the SMTP anner),
# %% The number of current sessions (eg. so you can do session limiting), the IP address of the
# %% connecting client, and a freeform list of options for the module. The Options are extracted
# %% from the `callbackoptions' parameter passed into the `gen_smtp_server_session' when it was
# %% started.
# %%
# %% If you want to continue the session, return `{ok, Banner, State}' where Banner is the SMTP
# %% banner to send to the client and State is the callback module's state. The State will be passed
# %% to ALL subsequent calls to the callback module, so it can be used to keep track of the SMTP
# %% session. You can also return `{stop, Reason, Message}' where the session will exit with Reason
# %% and send Message to the client.
  @spec init(binary, non_neg_integer, tuple, list) :: {:ok, String.t, State.t} | {:stop, any, String.t}
  def init(hostname, session_count, address, options) do
    :io.format("peer: ~p~n", [address])
    case session_count > 20 do
      false ->
        banner = [hostname, " ESMTP smtp_server_example"]
        state = State[options: options]
        {:ok, banner, state}
      true ->
        :io.format("Connection limit exceeded~n")
        {:stop, :normal, ["421 ", hostname, " is too busy to accept mail right now"]}
    end
  end


  # %% @doc Handle the HELO verb from the client. Arguments are the Hostname sent by the client as
  # %% part of the HELO and the callback State.
  # %%
  # %% Return values are `{ok, State}' to simply continue with a new state, `{ok, MessageSize, State}'
  # %% to continue with the SMTP session but to impose a maximum message size (which you can determine
  # %% , for example, by looking at the IP address passed in to the init function) and the new callback
  # %% state. You can reject the HELO by returning `{error, Message, State}' and the Message will be
  # %% sent back to the client. The reject message MUST contain the SMTP status code, eg. 554.
  @spec handle_HELO(binary, State[]) :: {:ok, pos_integer, State} | {:ok, State} | error_message
  def handle_HELO("invalid", state) do
    # contrived example
    {:error, "554 invalid hostname", state}
  end

  def handle_HELO("trusted_host", state) do
    {:ok, state} # no size limit because we trust them.
  end

  def handle_HELO(hostname, state) do
    :io.format("HELO from ~s~n", [hostname])
    {:ok, 655360, state} # 640kb of HELO should be enough for anyone.
    # If {ok, state} was returned here, we'd use the default 10mb limit
  end


  # %% @doc Handle the EHLO verb from the client. As with EHLO the hostname is provided as an argument,
  # %% but in addition to that the list of ESMTP Extensions enabled in the session is passed. This list
  # %% of extensions can be modified by the callback module to add/remove extensions.
  # %%
  # %% The return values are `{ok, Extensions, State}' where Extensions is the new list of extensions
  # %% to use for this session or `{error, Message, State}' where Message is the reject message as
  # %% with handle_HELO.
  @spec handle_EHLO(binary, list, State.t) :: {:ok, list, State.t} | error_message
  def handle_EHLO("invalid", _extensions, state) do
    # contrived example
    {:error, "554 invalid hostname", state}
  end

  def handle_EHLO(hostname, extensions, state) do
    :io.format("EHLO from ~s~n", [hostname])
    # You can advertise additional extensions, or remove some defaults
    my_extensions = case :proplists.get_value(:auth, state.options, false) do
      true ->
        # auth is enabled, so advertise it
        extensions ++ [{"AUTH", "PLAIN LOGIN CRAM-MD5"}, {"STARTTLS", true}]
      false ->
        extensions
    end
    {:ok, my_extensions, state}
  end


  # %% @doc Handle the MAIL FROM verb. The From argument is the email address specified by the
  # %% MAIL FROM command. Extensions to the MAIL verb are handled by the `handle_MAIL_extension'
  # %% function.
  # %%
  # %% Return values are either `{ok, State}' or `{error, Message, State}' as before.
  @spec handle_MAIL(binary, State.t) :: {:ok, State.t} | error_message
  def handle_MAIL("badguy@blacklist.com", state) do
    { :error, "552 go away", state}
  end

  def handle_MAIL(from, state) do
    :io.format("Mail from ~s~n", [from])
    # you can accept or reject the FROM address here
    {:ok, state}
  end

  # @doc Handle an extension to the MAIL verb. Return either `{ok, State}' or `error' to reject
  # the option.
  @spec handle_MAIL_extension(binary, State.t) :: {:ok, State.t} | :error
  #TODO
  def handle_MAIL_extension("X-SomeExtension" = extension, state) do
    :io.format("Mail from extension ~s~n", [extension])
    # any MAIL extensions can be handled here
    {:ok, state}
  end

  def handle_MAIL_extension(extension, _state) do
    :io.format("Unknown MAIL FROM extension ~s~n", [extension])
    :error
  end

@spec handle_RCPT(binary(), State.t) :: {:ok, State.t} | {:error, String.t, State.t}
def handle_RCPT("nobody@example.com", state) do
  {:error, "550 No such recipient", state}
end

def handle_RCPT(to, state) do
  :io.format("Mail to ~s~n", [to])
  # you can accept or reject RCPT TO addesses here, one per call
  {:ok, state}
end

# -spec handle_RCPT_extension(Extension :: binary(), State :: #state{}) -> {'ok', #state{}} | 'error'.
# handle_RCPT_extension(<<"X-SomeExtension">> = Extension, State) ->
#   % any RCPT TO extensions can be handled here
#   io:format("Mail to extension ~s~n", [Extension]),
#   {ok, State};
# handle_RCPT_extension(Extension, _State) ->
#   io:format("Unknown RCPT TO extension ~s~n", [Extension]),
#   error.

  @spec handle_DATA(binary, [binary,...], binary, State.t) :: {:ok, String.t, State.t} | {:error, String.t, State.t}
  def handle_DATA(_from, _to, "", state) do
    {:error, "552 Message too small", state}
  end

  def handle_DATA(from, to, data, state) do
    # some kind of unique id
    ref_list = Kernel.bitstring_to_list(:erlang.md5(term_to_binary(:erlang.now())))
    reference = :lists.flatten Enum.map(ref_list, fn(n)-> :io_lib.format("~2.16.0b", [n]) end)

    IO.inspect "TODO Still cant handle data"
    IO.inspect data

    # if RELAY is true, then relay email to email address, else send email data to console
    # case :proplists.get_value(relay, state.options, false) do
    #   true  -> relay(from, to, data)
    #   false ->

    #     :io.format("message from ~s to ~p queued as ~s, body length ~p~n", [from, to, reference, byte_size(data)])
    #     case :proplists.get_value(parse, state.options, false) do
    #       false -> :ok
    #       true ->
    #         try do
    #           result = :mimemail.decode(data)
    #           :io.format("Message decoded successfully!~n")
    #         rescue
    #           [reason] ->
    #             :io.format("Message decode FAILED with ~p:~n", [reason])
    #             case :proplists.get_value(dump, state.options, false) do
    #             false -> :ok
    #             true ->
    #               # optionally dump the failed email somewhere for analysis
    #               file = "dump/#{reference}",
    #               case :filelib.ensure_dir(file) do
    #                 :ok ->
    #                   :file.write_file(file, data)
    #                 _ ->
    #                   :ok
    #               end
    #             end
    #           end
    #         end
    #       end
    #     end
    #   end
    # end

    # At this point, if we return ok, we've accepted responsibility for the email
    {:ok, reference, state}
  end

  @spec handle_RSET(State.t) :: State.t
  def handle_RSET(state) do
    state # reset any relevant internal state
  end

  @spec handle_VRFY(binary, State.t) :: {:ok, String.t, State.t} | {:error, String.t, State.t}
  def handle_VRFY("someuser", state) do
    {:ok, "someuser@#{:smtp_util.guess_FQDN()}", state}
  end

  def handle_VRFY(_address, state) do
    {:error, "252 VRFY disabled by policy, just send some mail", state}
  end

  @spec handle_other(binary, binary, State.t) :: {String.t, State.t}
  def handle_other(verb, _args, state) do
    # You can implement other SMTP verbs here, if you need to
    {["500 Error: command not recognized : '", verb, "'"], state}
  end

  # this callback is OPTIONAL
  # it only gets called if you add AUTH to your ESMTP extensions
  # @spec handle_AUTH('login' | 'plain' | 'cram-md5', binary, binary | {binary, binary}, State.t) :: {:ok, State.t} | :error
  # def handle_AUTH(type, "username", "PaSSw0rd", state) when type =:= login; type =:= plain do
  #   {ok, state}
  # end

  def handle_AUTH('cram-md5', "username", {digest, seed}, state) do
    case :smtp_util.compute_cram_digest("PaSSw0rd", seed) do
      digest ->
        {:ok, state}
      _ ->  # never comes to this, because previous case matches all
        :error
    end
  end

  def handle_AUTH(_type, _username, _password, _state) do
    :error
  end

  # this callback is OPTIONAL
  # it only gets called if you add STARTTLS to your ESMTP extensions
  @spec handle_STARTTLS(State.t) :: State.t
  def handle_STARTTLS(state) do
    :io.format("TLS Started~n")
    state
  end

  @spec code_change(any, State.t, any) :: {:ok, State.t}
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  @spec terminate(any, State.t) :: {:ok, any, State.t}
  def terminate(reason, state) do
    {:ok, reason, state}
  end


  # Internal Functions

  defp relay(_, [], _) do
    :ok
  end

  defp relay(from, [to|rest], data) do
    # relay message to email address
    [_user, host] = :string.tokens(to, "@")
    :gen_smtp_client.send({from, [to], :erlang.binary_to_list(data)}, [relay: host])
    relay(from, rest, data)
  end

end