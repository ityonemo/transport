defmodule Transport.None do

  @behaviour Transport

  @type socket :: Transport.socket

  @impl true
  @doc false
  def listen(_port, _opts), do: {:ok, self()}
  @impl true
  @doc false
  def accept(_sock, _timeout) do
    Process.sleep(100)
    {:error, :timeout}
  end

  @impl true
  @doc false
  def connect(_host, _port, _opts), do: {:ok, self()}

  @impl true
  def recv(_sock, _length), do: {:ok, ""}

  @impl true
  @doc "Callback implementation for `c:Erps.Transport.Api.recv/3`, via `:ssl.recv/3`."
  def recv(_sock, _length, _timeout), do: {:ok, ""}

  @impl true
  @doc false
  def send(_sock, _content), do: :ok

  @impl true
  @doc false
  def upgrade(socket, _opts), do: {:ok, socket}

  @impl true
  @doc false
  def handshake(socket, _opts), do: {:ok, socket}

end
