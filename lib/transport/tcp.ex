defmodule Transport.Tcp do
  @moduledoc """
  implements a tcp transport strategy.
  """

  @behaviour Transport
  alias Transport

  @type socket :: Transport.socket

  @spec listen(:inet.port_number, keyword) :: {:ok, socket} | {:error, term}
  @doc "Callback implementation for `c:Transport.listen/2`."
  defdelegate listen(port, opts), to: :gen_tcp

  @spec accept(socket, timeout) :: {:ok, socket} | {:error, term}
  @doc "Callback implementation for `c:Transport.accept/2`."
  defdelegate accept(sock, timeout), to: :gen_tcp

  @spec connect(term, :inet.port_number, keyword) :: {:ok, socket} | {:error, term}
  @doc "Callback implementation for `c:Transport.connect/3`."
  defdelegate connect(host, port, opts), to: :gen_tcp

  @spec recv(socket, non_neg_integer) :: {:ok, binary} | {:error, term}
  @doc "Callback implementation for `c:Transport.recv/2`, via `:gen_tcp.recv/2`."
  defdelegate recv(sock, length), to: :gen_tcp

  @spec recv(socket, non_neg_integer, timeout) :: {:ok, binary} | {:error, term}
  @doc "Callback implementation for `c:Transport.recv/3`, via `:gen_tcp.recv/3`."
  defdelegate recv(sock, length, timeout), to: :gen_tcp

  @spec send(socket, iodata) :: :ok | {:error, term}
  @doc "Callback implementation for `c:Transport.send/2`, via `:gen_tcp.send/2`"
  defdelegate send(sock, content), to: :gen_tcp

  @impl true
  @spec upgrade(socket, keyword) :: {:ok, :inet.socket} | {:error, term}
  @doc """
  Callback implementation for `c:Transport.upgrade/2`.

  Does not perform any cryptographic authentication, but this is where you
  should set post-connection options (such as setting `active: true`)
  """
  def upgrade(socket, opts) do
    case :inet.setopts(socket, Keyword.take(opts, [:active])) do
      :ok -> {:ok, socket}
      error -> error
    end
  end

  @impl true
  @spec handshake(:inet.socket, keyword) :: {:ok, Api.socket}
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
  @spec type :: :tcp
  def type, do: :tcp
end
