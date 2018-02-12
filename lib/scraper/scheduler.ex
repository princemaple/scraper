defmodule Scraper.Scheduler do
  use GenServer

  require Logger

  def start_link(opts) do
    {server_opts, opts} = Map.split(opts, [:name])
    GenServer.start_link(__MODULE__, opts, Map.to_list(server_opts))
  end

  def schedule(server, url) when is_binary(url) do
    GenServer.call(
      {:via, Registry, {server, :scheduler}},
      {:link_ready, %Scraper.Link{url: url, depth: 0}}
    )
  end

  def schedule(server, %Scraper.Link{} = link) do
    GenServer.call(
      {:via, Registry, {server, :scheduler}},
      {:link_ready, link}
    )
  end

  def init(opts), do: {:ok, Map.put(opts, :maximum_reached, false)}

  def handle_call({:link_ready, link}, _from, %{maximum_reached: true} = state) do
    {:reply, enqueue(link, state), state}
  end

  def handle_call(
        {:link_ready, link},
        _from,
        %{scraper_id: scraper_id, max_workers: max_workers} = state
      ) do
    %{active: worker_count} =
      DynamicSupervisor.count_children({:via, Registry, {scraper_id, :worker_supervisor}})

    if worker_count < max_workers do
      Logger.debug("Starting worker for #{link.url}")
      {:reply, start_worker(link, state), state}
    else
      Logger.debug("Queuing #{link.url}")
      {:reply, enqueue(link, state), %{state | maximum_reached: true}}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    with {:ok, link} <- dequeue(state) do
      start_worker(link, state)
      {:noreply, state}
    else
      _ -> {:noreply, %{state | maximum_reached: false}}
    end
  end

  defp enqueue(link, %{scraper_id: scraper_id, links_buffer: links_buffer}) do
    links_buffer.enqueue({:via, Registry, {scraper_id, :links_buffer}}, link)
  end

  defp dequeue(%{scraper_id: scraper_id, links_buffer: links_buffer}) do
    links_buffer.dequeue({:via, Registry, {scraper_id, :links_buffer}})
  end

  defp start_worker(link, %{scraper_id: scraper_id} = state) do
    with {:ok, pid} <-
           DynamicSupervisor.start_child(
             {:via, Registry, {scraper_id, :worker_supervisor}},
             {Scraper.Worker, Map.put(state, :link, link)}
           ) do
      Process.monitor(pid)
      {:ok, pid}
    end
  end
end
