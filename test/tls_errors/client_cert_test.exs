defmodule TransportTest.TlsErrors.ClientCertTest do
  # tests that server rejects when client certs are no good.

  use ExUnit.Case, async: true

  import TransportTest.TlsOpts

  alias Transport.Tls
  alias TransportTest.PassiveClient, as: Client
  alias TransportTest.PassiveServer, as: Server

  test "Client cannot connect with the wrong root ca" do
    # NB this is symmetric to the server case.
    {:ok, server} = Server.start_link(Tls, self(), tls_opts("server"))
    port = Server.port(server)

    wrong_root_ca = tls_opts("client")
    |> put_in([:tls_opts, :cacertfile], path("wrong-rootCA.pem"))
    |> put_in([:tls_opts, :certfile], path("wrong-root.cert"))
    |> put_in([:tls_opts, :keyfile], path("wrong-root.key"))

    assert :ignore = Client.start_link(Tls, port, self(), wrong_root_ca)
    assert_receive {:client, {:error, {:tls_alert, {:unknown_ca, _}}}}
    assert_receive {:server, {:error, {:tls_alert, {:unknown_ca, _}}}}
  end

  test "Client cannot connect valid cert connected to wrong root ca" do
    {:ok, server} = Server.start_link(Tls, self(), tls_opts("server"))
    port = Server.port(server)

    wrong_cert = tls_opts("client")
    |> put_in([:tls_opts, :certfile], path("wrong-root.cert"))
    |> put_in([:tls_opts, :keyfile], path("wrong-root.key"))

    assert :ignore = Client.start_link(Tls, port, self(), wrong_cert)
    assert_receive {:client, {:error, {:tls_alert, {:unknown_ca, _}}}}
    assert_receive {:server, {:error, {:tls_alert, {:unknown_ca, _}}}}
  end

  test "Client cannot connect with a wrong key for the cert" do
    {:ok, server} = Server.start_link(Tls, self(), tls_opts("server"))
    port = Server.port(server)

    wrong_key = tls_opts("client")
    |> put_in([:tls_opts, :keyfile], path("wrong-root.key"))

    assert :ignore = Client.start_link(Tls, port, self(), wrong_key)
    assert_receive {:client, {:error, {:tls_alert, {:bad_certificate, _}}}}
    assert_receive {:server, {:error, {:tls_alert, {:bad_certificate, _}}}}
  end

  @tag :one
  test "Server doesn't accept if client presents the wrong host name for its cert." do
    {:ok, server} = Server.start_link(Tls, self(), tls_opts("server"))

    port = Server.port(server)

    wrong_key = tls_opts("client")
    |> put_in([:tls_opts, :certfile], path("wrong-host.cert"))
    |> put_in([:tls_opts, :keyfile], path("wrong-host.key"))

    assert :ignore = Client.start_link(Tls, port, self(), wrong_key)
    assert_receive {:client, {:error, {:tls_alert, {:handshake_failure, _}}}}
    assert_receive {:server, {:error, {:tls_alert, {:handshake_failure, _}}}}
  end

end
