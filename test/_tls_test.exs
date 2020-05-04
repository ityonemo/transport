defmodule TransportTest.TlsTest do
  use ExUnit.Case, async: true

  alias Transport.Tls
  import TransportTest.TlsOpts

  test "passive tls clients work" do
    alias TransportTest.PassiveClient, as: Client
    alias TransportTest.PassiveServer, as: Server

    {:ok, server} = Server.start_link(Tls, self(), tls_opts("server"))
    port = Server.port(server)
    {:ok, client} = Client.start_link(Tls, port, self(), tls_opts("client"))

    # make sure that we can send from the client to the server
    Client.send(client, "foo")
    assert_receive {:server, "foo"}

    # make sure that the server can send to the client
    Server.send(server, "foo")
    assert_receive {:client, "foo"}
  end

  test "active tls clients work" do
    alias TransportTest.ActiveClient, as: Client
    alias TransportTest.ActiveServer, as: Server

    {:ok, server} = Server.start_link(Tls, self(), tls_opts("server"))
    port = Server.port(server)
    {:ok, client} = Client.start_link(Tls, port, self(), tls_opts("client"))

    # make sure that we can send from the client to the server
    Client.send(client, "foo")
    assert_receive {:server, "foo"}

    # make sure that the server can send to the client
    Server.send(server, "foo")
    assert_receive {:client, "foo"}
  end
end
