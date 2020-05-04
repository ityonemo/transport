defmodule TransportTest.TlsErrors.UnencryptedTest do
  # tests that unencrypted client and unencrypted server
  # are both rejected.

  use ExUnit.Case, async: true

  import TransportTest.TlsOpts

  alias Transport.Tcp
  alias Transport.Tls
  alias TransportTest.PassiveClient, as: Client
  alias TransportTest.PassiveServer, as: Server

  test "TCP client channel gets closed by server requiring TLS" do
    {:ok, server} = Server.start_link(Tls, self(), tls_opts("server"))
    port = Server.port(server)
    {:ok, client} = Client.start_link(Tcp, port, self())
    Client.send(client, "foo")
    assert_receive {:client, {:error, :closed}}
    assert_receive {:server, {:error, {:tls_alert, _}}}
  end

  test "TCP server channel times out when client requires TLS" do
    # this is because a naive TCP server doesn't perform the handshake at all and
    # can't recoginze what's up.
    {:ok, server} = Server.start_link(Tcp, self())
    port = Server.port(server)
    assert :ignore = Client.start_link(Tls, port, self(), tls_opts("client"))
    assert_receive {:client, {:error, :timeout}}
  end
end
