defmodule TransportTest.TlsTest do
  use ExUnit.Case, async: true

  alias Transport.Tls

  defp path(file), do: Path.join(TransportTest.TlsFiles.path(), file)

  # for tests we don't have actual fqdns for our server (which is tied
  # to a self-signed certificate authority internal to the tests).  We've
  # branded the "dns" as 127.0.0.1, so verify_server_identity/2 will make
  # that match.
  defp extra_opts("client") do
    [customize_hostname_check: [match_fun: &verify_server_identity/2]]
  end
  defp extra_opts(_), do: []

  defp tls_opts(who) do
    [tls_opts: [
     cacertfile: path("rootCA.pem"),
     certfile:   path("#{who}.cert"),
     keyfile:    path("#{who}.key")] ++ extra_opts(who)]
  end

  defp verify_server_identity({:ip, ip}, {:dNSName, dnsname}) do
    :inet.ntoa(ip) == dnsname
  end
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
