defmodule Transport.Tcp do
  @moduledoc """
  implements a tcp transport strategy.
  """

  @behaviour Transport
  alias Transport

  @type socket :: Transport.socket

  @connection_opts [:binary, active: false]

  @spec send(socket, iodata) :: :ok | {:error, term}
  @doc "Callback implementation for `c:Transport.send/2`, via `:gen_tcp.send/2`"
  defdelegate send(sock, content), to: :gen_tcp

  @spec recv(socket, non_neg_integer) :: {:ok, binary} | {:error, term}
  @doc "Callback implementation for `c:Transport.recv/2`, via `:gen_tcp.recv/2`."
  defdelegate recv(sock, length), to: :gen_tcp

  @spec recv(socket, non_neg_integer, timeout) :: {:ok, binary} | {:error, term}
  @doc "Callback implementation for `c:Transport.recv/3`, via `:gen_tcp.recv/3`."
  defdelegate recv(sock, length, timeout), to: :gen_tcp

  @impl true
  @spec type :: :tcp
  def type, do: :tcp

  @impl true
  @spec listen(:inet.port_number, keyword) :: {:ok, socket} | {:error, term}
  @doc section: :server
  @doc """
  Callback implementation for `c:Transport.listen/2`.

  NB: `Transport.Tcp` defaults to using a binary tcp port.
  """
  def listen(port, opts \\ []) do
    :gen_tcp.listen(port, @connection_opts ++ opts)
  end

  @spec accept(socket, timeout) :: {:ok, socket} | {:error, term}
  @doc section: :server
  @doc "Callback implementation for `c:Transport.accept/2`."
  defdelegate accept(sock, timeout), to: :gen_tcp

  @impl true
  @spec handshake(:inet.socket, keyword) :: {:ok, Api.socket}
  @doc section: :server
  @doc """
  Callback implementation for `c:Transport.handshake/2`.

  Does not request the client-side for an upgrade to an authenticated or
  encrypted channel, but this is also where you should set post-connection
  options (such as setting `active: true`)
  """
  def handshake(socket, opts!) do
    opts! = Keyword.take(opts!, [:active])
    case :inet.setopts(socket, opts!) do
      :ok -> {:ok, socket}
      any -> any
    end
  end

  @impl true
  @spec connect(term, :inet.port_number) :: {:ok, socket} | {:error, term}
  @spec connect(term, :inet.port_number, keyword) :: {:ok, socket} | {:error, term}
  @doc section: :client
  @doc "Callback implementation for `c:Transport.connect/3`."
  def connect(host, port, opts! \\ []) do
    timeout = opts![:timeout] || :infinity
    opts! = Keyword.drop(opts!, [:timeout])
    :gen_tcp.connect(host, port, @connection_opts ++ opts!, timeout)
  end

  @impl true
  @spec upgrade(socket, keyword) :: {:ok, :inet.socket} | {:error, term}
  @doc section: :client
  @doc """
  Callback implementation for `c:Transport.upgrade/2`.

  Does not perform any cryptographic authentication, but this is where you
  should set post-connection options (such as setting `active: true`)
  """
  def upgrade(socket, opts!) do
    opts! = Keyword.drop(opts!, [:tls_opts, :timeout])
    case :inet.setopts(socket, opts!) do
      :ok -> {:ok, socket}
      error -> error
    end
  end
end
