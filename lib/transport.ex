defmodule Transport do
  @moduledoc """
  Encapsulates a common API which describes a transport strategy.

  By using this API you can use TCP and TLS interchangeably, by specifying
  strategy modules in your server and client configurations.  This API also
  seeks to iron out common missteps in setting up TLS connections and enforce
  some best practices for securing your WAN transmissions.

  Currently the available transport strategies are:
  - `Transport.Tcp`: unencrypted, unauthenticated communication.  Only
    appropriate in `:dev` and `:test` environments.  Allows you to simplify
    early stage and test deployments.
  - `Transport.Tls`: two-way authenticated, encrypted communication, using
    X509 TLS encryption.  This is the general use case for point-to-point
    API services including over untrusted networks.

  You may use this API to implement your own transport layers, or use it
  to mock responses in tests.
  """

  @type socket :: :inet.socket | :ssl.sslsocket | GenServer.server | port

  # DUAL API
  @doc """
  (for clients **and** servers) sends iodata down the appropriate transport
  channel.

  If the data are bigger than the MTU, it may be broken into multiple packets
  over the line.
  """
  @callback send(socket, iodata) :: :ok | {:error, any}

  @doc """
  (for clients **and** servers) blocks until data of a requested length
  comes over the transport channel.

  See `:gen_tcp.recv/2` for more information.
  """
  @callback recv(socket, length :: non_neg_integer) ::
    {:ok, binary} | {:error, any}

  @doc """
  (for clients **and** servers).  Like `b:recv/2` but with a timeout so the
  server doesn't block indefinitely.

  See `:gen_tcp.recv/3` for more information.
  """
  @callback recv(socket, length :: non_neg_integer, timeout) ::
    {:ok, binary} | {:error, any}

  @doc """
  returns an atom which is intended for matching on active packet messages.

  When the connection is `active: :true`, the owning process will recieve
  messages of the form: `{:tcp, <socket>, <data>}` or
  `{:ssl, <socket>, <data>}`, this function helps you generically match the
  identifier on the front of this message tuple.
  """
  @callback type() :: atom

  #############################################################################
  ## Client API

  @doc section: :client
  @doc """
  (for clients) initiates an unencrypted connection from the client to the
  server.

  This unencrypted connection can be upgraded to an encrypted connection later,
  using the `b:upgrade/2` function.  Implementation modules guarantee an
  `active: false` connection to ensure timing correctness when establishing
  the upgraded encryption.

  If you need to set `active: true` or other connection options that the
  upgrade process is sensitive to, you can set them in the options argument
  of `b:upgrade/2`.
  """
  @callback connect(
    identifier :: :inet.ip_address,
    port :: :inet.port_number, keyword) ::
    {:ok, socket} | {:error, any}

  @doc section: :client
  @doc """
  (for clients) upgrades a TCP connection to an authenticated, encrypted
  connection, if the transport module implements encryption.

  connection options that are incompatible with encryption upgrading (such as
  `active: true`) should be passed into the options argument.
  """
  @callback upgrade(socket, options :: keyword) ::
    {:ok, socket} | {:error, any}

  #############################################################################
  ## Server API

  @callback listen(port :: :inet.port_number) :: {:ok, socket} | {:error, any}
  @doc section: :server
  @doc """
  (for servers) opens an unencrypted TCP port to listen for incoming
  connection requests.

  Implementation modules guarantee an `active: false` connection to ensure
  correct synchronization of `c:handshake/2` events.
  """
  @callback listen(port :: :inet.port_number, keyword) ::
    {:ok, socket} | {:error, any}

  @doc section: :server
  @doc """
  (for servers) blocks on a socket opened with `b:listen/1,2` and waits for a
  connection request.

  The resulting opened socket will be unencrypted, and must be upgraded with
  `b:handshake/2` to initiate secure communications.
  """
  @callback accept(socket, timeout) :: {:ok, socket} | {:error, any}

  @doc section: :server
  @doc """
  (for servers) upgrades an associated TCP connection to an authenticated,
  encrypted connection, if the transport module implements encryption.

  connection options that are incompatible with the handshake (such as
  `active: true`) should be passed into the options argument here.
  """
  @callback handshake(socket :: :inet.socket, keyword) ::
    {:ok, socket} | {:error, any}

end
