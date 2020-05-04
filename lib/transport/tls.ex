
defmodule Transport.Tls do

  @moduledoc """
  implements a two-way TLS transport strategy.

  this transport is useful when you have trusted clients and servers that are
  authenticated against each other and must have an encrypted channel over
  WAN.
  """

  @behaviour Transport

  @type socket :: Transport.socket

  defdelegate listen(port, options \\ []), to: Transport.Tcp

  @spec accept(socket, timeout) :: {:ok, socket} | {:error, term}
  @doc "Callback implementation for `c:Transport.accept/2`."
  defdelegate accept(sock, timeout), to: :gen_tcp

  @spec connect(term, :inet.port_number) :: {:ok, socket} | {:error, term}
  @spec connect(term, :inet.port_number, keyword) :: {:ok, socket} | {:error, term}
  @doc "Callback implementation for `c:Transport.connect/3`."
  defdelegate connect(host, port, options \\ []), to: Transport.Tcp

  @spec send(socket, iodata) :: :ok | {:error, term}
  @doc "Callback implementation for `c:Transport.send/2`, via `:ssl.send/2`."
  defdelegate send(sock, content), to: :ssl

  @default_client_tls_opts [verify: :verify_peer, fail_if_no_peer_cert: true]
  @default_server_tls_opts [verify: :verify_peer, fail_if_no_peer_cert: true]

  @impl true
  @spec upgrade(socket, keyword) :: {:ok, :ssl.socket} | {:error, term}
  @doc """
  (client) responds to a server TLS `handshake/2` request, by upgrading to an
  encrypted connection.  Verifies the identity of the server CA, and reject if
  it's not a valid peer.

  This is also where you should set post-connection options (such as setting
  `active: true`)

  If you would like to timeout on the ssl upgrade process, pass the timeout
  value to the keyword `:timeout` in options

  Callback implementation for `c:Transport.upgrade/2`.
  """
  def upgrade(socket, upgrade_opts!) do
    socket_opts = Keyword.drop(upgrade_opts!, [:tls_opts, :timeout])
    timeout = upgrade_opts![:timeout] || :infinity
    upgrade_opts! =
      Keyword.merge(@default_client_tls_opts, upgrade_opts![:tls_opts] || [])

    with {:ok, tls_socket} <- :ssl.connect(socket, upgrade_opts!, timeout),
         :ok <- :ssl.setopts(tls_socket, socket_opts) do
      {:ok, tls_socket}
    end
  end

  @spec recv(socket, non_neg_integer) :: {:ok, binary} | {:error, term}
  @doc "Callback implementation for `c:Transport.recv/2`, via `:ssl.recv/2`."
  defdelegate recv(sock, length), to: :ssl

  @spec recv(socket, non_neg_integer, timeout) :: {:ok, binary} | {:error, term}
  @doc "Callback implementation for `c:Transport.recv/3`, via `:ssl.recv/3`."
  defdelegate recv(sock, length, timeout), to: :ssl

  @impl true
  @spec handshake(:inet.socket, keyword) :: {:ok, Api.socket} | {:error, any}
  @doc """
  (server) a specialized function that generates a match function option used to
  verify that the incoming client is bound to a single ip address.

  This is also the place where you should set post-connection options, such
  as setting `active: true`.
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

  @impl true
  @spec type :: :ssl
  def type, do: :ssl
end
