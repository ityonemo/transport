
defmodule Transporter.Tls do

  @moduledoc """
  implements a two-way TLS transport strategy.

  this transport is useful when you have trusted clients and servers that are
  authenticated against each other and must have an encrypted channel over
  WAN.
  """

  @behaviour Transporter

  @type socket :: Transporter.socket

  @spec send(socket, iodata) :: :ok | {:error, term}
  @doc "Callback implementation for `c:Transporter.send/2`, via `:ssl.send/2`."
  defdelegate send(sock, content), to: :ssl

  @spec recv(socket, non_neg_integer) :: {:ok, binary} | {:error, term}
  @doc "Callback implementation for `c:Transporter.recv/2`, via `:ssl.recv/2`."
  defdelegate recv(sock, length), to: :ssl

  @spec recv(socket, non_neg_integer, timeout) :: {:ok, binary} | {:error, term}
  @doc "Callback implementation for `c:Transporter.recv/3`, via `:ssl.recv/3`."
  defdelegate recv(sock, length, timeout), to: :ssl

  @impl true
  @spec type :: :ssl
  def type, do: :ssl

  @default_client_tls_opts [verify: :verify_peer, fail_if_no_peer_cert: true]
  @default_server_tls_opts [verify: :verify_peer, fail_if_no_peer_cert: true]

  @doc section: :server
  @doc """
  Callback implementation for `c:Transporter.listen/2`.

  NB: `Transporter.Tls` defaults to using a binary tcp port.
  """
  defdelegate listen(port, options \\ []), to: Transporter.Tcp

  @spec accept(socket, timeout) :: {:ok, socket} | {:error, term}
  @doc section: :server
  @doc "Callback implementation for `c:Transporter.accept/2`."
  defdelegate accept(sock, timeout), to: :gen_tcp

  @impl true
  @spec handshake(:inet.socket, keyword) :: {:ok, Api.socket} | {:error, any}
  @doc section: :server
  @doc """
  (server) a specialized function that generates a match function option used to
  verify that the incoming client is bound to a single ip address.

  This is also the place where you should set post-connection options, such
  as setting `active: true`.

  NB: in many point-to-point trusted TLS operations you will want to perform a
  symmetric check against the identity of the inbound client.  Normally you
  wouldn't do this for web (e.g. HTTPS) TLS because public clients typically
  don't have a static DNS-assigned address.  Users of Transporter should strongly
  consider using this feature.  To perform a check against the client, `Transporter`
  has implemented `:customize_hostname_check` for servers as you would in the
  normal client SSL case.

  You should use the options `verify_peer: true` and
  `customize_hostname_check: <check>`  See: http://erlang.org/doc/man/ssl.html#type-customize_hostname_check
  and `:public_key.pkix_verify_hostname/3` to understand this feature.
  """
  def handshake(socket, handshake_opts) do
    # instrument in a series of default tls options into the handshake.
    socket_opts = Keyword.drop(handshake_opts, [:tls_opts])
    tls_opts! = handshake_opts[:tls_opts]
    tls_opts! = @default_server_tls_opts
    |> Keyword.merge(tls_opts! || [])
    |> Keyword.merge(hostname_check(tls_opts!, socket))

    with {:ok, tls_socket} <- :ssl.handshake(socket, tls_opts!, 200),
         :ok <- :ssl.setopts(tls_socket, socket_opts) do
      {:ok, tls_socket}
    else
      any ->
        :gen_tcp.close(socket)
        any
    end
  end

  @spec connect(term, :inet.port_number) :: {:ok, socket} | {:error, term}
  @spec connect(term, :inet.port_number, keyword) :: {:ok, socket} | {:error, term}
  @doc section: :client
  @doc "Callback implementation for `c:Transporter.connect/3`."
  defdelegate connect(host, port, options \\ []), to: Transporter.Tcp

  @impl true
  @spec upgrade(socket :: socket, options :: keyword) ::
    {:ok, :ssl.socket} | {:error, term}
  @doc section: :client
  @doc """
  (client) responds to a server TLS `handshake/2` request, by upgrading to an
  encrypted connection.  Verifies the identity of the server CA, and reject if
  it's not a valid peer.

  This is also where you should set post-connection options (such as setting
  `active: true`)

  If you would like to timeout on the ssl upgrade process, pass the timeout
  value to the keyword `:timeout` in options

  Callback implementation for `c:Transporter.upgrade/2`.
  """
  def upgrade(socket, options!) do
    socket_opts = Keyword.drop(options!, [:tls_opts, :timeout])
    timeout = options![:timeout] || :infinity
    options! =
      Keyword.merge(@default_client_tls_opts, options![:tls_opts] || [])

    with {:ok, tls_socket} <- :ssl.connect(socket, options!, timeout),
         :ok <- :ssl.setopts(tls_socket, socket_opts) do
      {:ok, tls_socket}
    end
  end

  #############################################################################
  ## PRIVATE API

  # the hostname_check functions create a `:customize_hostname_check` for the
  # servers that is functionally identical to the `:customize_hostname_check`
  # options that you would normally pass to clients.

  defp hostname_check(tls_opts, socket) do
    if chk = tls_opts[:customize_hostname_check] do
      [verify_fun: {&hostname_check/3, {socket, chk}}]
    else
      []
    end
  end

  defp hostname_check(cert, :valid_peer, state = {socket, methods}) do
    with {:ok, {peer_ip, _peer_port}} <- :inet.peername(socket),
         true <- :public_key.pkix_verify_hostname(cert, [ip: peer_ip], methods) do
      {:valid, state}
    else
      {:error, reason} ->
        {:fail, reason}
      false ->
        {:fail, :hostname_check_failed}
    end
  end
  defp hostname_check(_cert, reason = {:bad_cert, _}, _), do: {:fail, reason}
  defp hostname_check(_cert, {:extension, _}, user_state), do: {:unknown, user_state}
  defp hostname_check(_cert, :valid, user_state), do: {:valid, user_state}
  defp hostname_check(_cert, :valid_peer, user_state), do: {:valid, user_state}
end
