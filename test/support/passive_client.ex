# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc

defmodule TransportTest.PassiveClient do

  # implements an active: false client that is generic between TCP and SSL.

  use GenServer
  import Kernel, except: [send: 2]

  def start_link(transport, port, test_pid, opts \\ []) do
    state = %{transport: transport, port: port, test_pid: test_pid, opts: opts}
    GenServer.start_link(__MODULE__, state)
  end

  @localhost {127, 0, 0, 1}

  def init(state = %{transport: transport}) do
    with {:ok, socket} <- transport.connect(@localhost, state.port),
         {:ok, upgrade} <- transport.upgrade(socket, [timeout: 100] ++ state.opts) do
      {:ok, Map.put(state, :socket, upgrade)}
    else
      error ->
        Kernel.send(state.test_pid, {:client, error})
        :ignore
    end
  end

  def send(server, msg), do: GenServer.cast(server, {:send, msg})

  def handle_cast({:send, msg}, state = %{transport: transport}) do
    case transport.send(state.socket, msg) do
      :ok ->
        Process.send_after(self(), :recv, 0)
      err ->
        Kernel.send(state.test_pid, err)
    end
    {:noreply, state}
  end

  def handle_info(:recv, state = %{transport: transport}) do
    case transport.recv(state.socket, 0) do
      {:ok, data} ->
        Kernel.send(state.test_pid, {:client, data})
      error ->
        Kernel.send(state.test_pid, {:client, error})
    end
    {:noreply, state}
  end
end
