defmodule TransportTest.TlsErrors.ServerCertTest do
  # tests that client rejects when server certs are no good.

  use ExUnit.Case, async: true

  import TransportTest.TlsOpts

  alias Transporter.Tls
  alias TransportTest.PassiveClient, as: Client
  alias TransportTest.PassiveServer, as: Server

  test "Client doesn't like it when server is not matched" do
    wrong_cert = tls_opts("server")
    |> put_in([:tls_opts, :certfile], path("wrong-root.cert"))
    |> put_in([:tls_opts, :keyfile], path("wrong-root.key"))

    {:ok, server} = Server.start_link(Tls, self(), wrong_cert)
    port = Server.port(server)

    assert :ignore = Client.start_link(Tls, port, self(), tls_opts("client"))

    assert_receive {:client, {:error, {:tls_alert, {:unknown_ca, _}}}}
    assert_receive {:server, {:error, {:tls_alert, {:unknown_ca, _}}}}
  end

  test "Client dosn't accept it if server presents wrong certificate key." do
    wrong_key = tls_opts("server")
    |> put_in([:tls_opts, :keyfile], path("wrong-root.key"))

    {:ok, server} = Server.start_link(Tls, self(), wrong_key)
    port = Server.port(server)

    assert :ignore = Client.start_link(Tls, port, self(), tls_opts("client"))
    assert_receive {:client, {:error, {:tls_alert, {:decrypt_error, _}}}}
    assert_receive {:server, {:error, {:tls_alert, {:decrypt_error, _}}}}
  end

  @tag :one
  test "Client doesn't accept if server presents the wrong host name for its cert." do
    wrong_host = tls_opts("server")
    |> put_in([:tls_opts, :certfile], path("wrong-host.cert"))
    |> put_in([:tls_opts, :keyfile], path("wrong-host.key"))

    {:ok, server} = Server.start_link(Tls, self(), wrong_host)
    port = Server.port(server)

    assert :ignore = Client.start_link(Tls, port, self(), tls_opts("client"))

    assert_receive {:client, {:error, {:tls_alert, {:handshake_failure, _}}}}
    assert_receive {:server, {:error, {:tls_alert, {:handshake_failure, _}}}}
  end

end
