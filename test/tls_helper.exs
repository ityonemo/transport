require Logger

tempdir_name = Base.encode16(:crypto.strong_rand_bytes(32))
tempdir = Path.join([System.tmp_dir!(), ".erps-test", tempdir_name])

defmodule TransportTest.TlsFiles do
  @path tempdir
  def path, do: @path
  def cleanup do
    File.rm_rf!(@path)
  end
end

ExUnit.after_suite(fn %{failures: 0} ->
  # only clean up our temporary directory if it was succesful
  TransportTest.TlsFiles.cleanup()
  :ok
  _ -> :ok
end)

File.mkdir_p!(tempdir)

Logger.info("test certificates path: #{tempdir}")

# make your own CA
{ca, ca_key} = TransportTest.TlsFileGen.generate_root(tempdir, "rootCA")
# generate server authentications
TransportTest.TlsFileGen.generate_cert(tempdir, "server", ca, ca_key)
# generate client authentications
TransportTest.TlsFileGen.generate_cert(tempdir, "client", ca, ca_key)

# generate a key that is unrelated to the correct keys.
TransportTest.TlsFileGen.generate_key(tempdir, "wrong-key")

# generate a client and cert that has wrong hosts.
TransportTest.TlsFileGen.generate_cert(tempdir, "wrong-host", ca, ca_key, host: "1.1.1.1")

# make a chain of content that comes from the wrong CA root
{wrong_ca, wrong_ca_key} = TransportTest.TlsFileGen.generate_root(tempdir, "wrong-rootCA")
# generate server authentications
TransportTest.TlsFileGen.generate_cert(tempdir, "wrong-root", wrong_ca, wrong_ca_key)

