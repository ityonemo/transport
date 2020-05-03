defmodule TransportTest.TcpTest do
  use ExUnit.Case, async: true

  alias Transport.Tcp

  test "passive tcp clients work" do
    alias TransportTest.PassiveClient, as: Client
    alias TransportTest.PassiveServer, as: Server

    {:ok, server} = Server.start_link(Tcp, self())
    port = Server.port(server)
    {:ok, client} = Client.start_link(Tcp, port, self())

    # make sure that we can send from the client to the server
    Client.send(client, "foo")
    assert_receive {:server, "foo"}

    # make sure that the server can send to the client
    Server.send(server, "foo")
    assert_receive {:client, "foo"}
  end

  test "active tcp clients work" do
    alias TransportTest.ActiveClient, as: Client
    alias TransportTest.ActiveServer, as: Server

    {:ok, server} = Server.start_link(Tcp, self())
    port = Server.port(server)
    {:ok, client} = Client.start_link(Tcp, port, self())

    # make sure that we can send from the client to the server
    Client.send(client, "foo")
    assert_receive {:server, "foo"}

    # make sure that the server can send to the client
    Server.send(server, "foo")
    assert_receive {:client, "foo"}
  end
end
