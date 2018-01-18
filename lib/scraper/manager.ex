defmodule Scraper.Manager do
  use GenServer

  require Logger

  def start_link(server_opts \\ []) do
    GenServer.start_link(__MODULE__, [], server_opts)
  end

  def init([]) do
    send(self(), :queue_work)
    {:ok, []}
  end

  def handle_info(:queue_work, _state) do
    Agent.update(
      Scraper.LinksBuffer,
      &Enum.drop_while(&1, fn url ->
        case DynamicSupervisor.start_child(
          Scraper.WorkerSupervisor,
          {Scraper.Worker, url}
        ) do
          {:ok, _pid} ->
            Logger.info("Working on #{url}")
            true
          {:error, :max_children} ->
            false
        end
      end)
    )

    Process.send_after(self(), :queue_work, 2000)

    {:noreply, []}
  end
end
