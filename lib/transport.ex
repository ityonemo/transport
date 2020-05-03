defmodule Transport do
  @moduledoc """
  Encapsulates a common API which describes a transport strategy.

  Currently the available transport strategies are:
  - `Transport.Tcp`: unencrypted, unauthenticated communication.  Only appropriate
    in `:dev` and `:test` environments.
  - `Transport.Tls`: two-way authenticated, encrypted communication, using X509
    TLS encryption.  This is the general use case for point-to-point
    API services including over untrusted networks.

  You may use this API to implement your own transport layers, or use it
  to mock responses in tests.

  Each of the API callbacks is either a client callback, a server callback,
  or a "both" callback.
  """

  @type socket :: :inet.socket | :ssl.sslsocket | GenServer.server | port

  # CLIENT API

  @doc """
  (client) initiates a unencrypted connection from the client to the server.

  The connection must be opened with `active: false`, or upgrade guarantees
  cannot be ensured for X509-TLS connections.
  """
  @callback connect(:inet.ip_address, :inet.port_number, keyword)
  :: {:ok, socket} | {:error, any}

  @doc """
  (client) upgrades an TCP connection to an encrypted, authenticated
  connection.

  Also should upgrade the connection from `active: false` to `active: true`

  In the case of an unencrypted transport, e.g. `Transport.Tcp`, only perfroms the
  connection upgrade.
  """
  @callback upgrade(socket, keyword) :: {:ok, socket} | {:error, any}

  # SERVER API

  @doc """
  (server) opens a TCP port to listen for incoming connection requests.

  Opens the port in `active: false` to ensure correct synchronization of
  `c:handshake/2` and `c:upgrade/2` events.
  """
  @callback listen(:inet.port_number) :: {:ok, socket} | {:error, any}
  @callback listen(:inet.port_number, keyword) :: {:ok, socket} | {:error, any}

  @doc """
  (server) temporarily blocks the server waiting for a connection request.
  """
  @callback accept(socket, timeout) :: {:ok, socket} | {:error, any}

  @doc """
  (server) blocks the server waiting for a connection request until some data
  comes in.
  """
  @callback recv(socket, length :: non_neg_integer) :: {:ok, binary} | {:error, any}

  @doc """
  (server) Like `b:recv/2` but with a timeout so the server doesn't block
  indefinitely.
  """
  @callback recv(socket, length :: non_neg_integer, timeout) :: {:ok, binary} | {:error, any}

  @doc """
  (server) upgrades the TCP connection to an authenticated, encrypted
  connection.

  Also should upgrade the connection from `active: false` to `active: true`.

  In the case of an unencrypted transport, e.g. `Transport.Tcp`, only performs the
  connection upgrade.
  """
  @callback handshake(:inet.socket, keyword) :: {:ok, socket} | {:error, any}

  # DUAL API
  @doc "(both) sends a packet down the appropriate transport channel"
  @callback send(socket, iodata) :: :ok | {:error, any}

  @doc """
  (both, optional) provides a hint to `c:GenServer.handle_info/2` as to what sorts of
  active packet messages to expect.
  """
  @callback type() :: atom

  @optional_callbacks type: 0
end
