defmodule Scraper.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    scraper_id = Keyword.fetch!(opts, :scraper_id)
    {data_store, opts} = Keyword.pop(opts, :data_store, Scraper.Naive.DataStore)
    {data_store_opts, opts} = Keyword.pop(opts, :data_store_opts, [])
    {data_selectors, opts} = Keyword.pop(opts, :data_selectors, [])
    {links_buffer, opts} = Keyword.pop(opts, :links_buffer, Scraper.Naive.LinksBuffer)
    {links_buffer_opts, opts} = Keyword.pop(opts, :links_buffer_opts, [])
    {link_selectors, opts} = Keyword.pop(opts, :link_selectors, [])
    {max_workers, opts} = Keyword.pop(opts, :max_workers, System.schedulers_online() * 2)
    {max_depth, opts} = Keyword.pop(opts, :max_depth, 1)

    children = [
      {
        Registry,
        keys: :unique, name: scraper_id
      },
      {
        DynamicSupervisor,
        strategy: :one_for_one,
        max_children: max_workers,
        name: {:via, Registry, {scraper_id, :worker_supervisor}}
      },
      {
        links_buffer,
        [{:name, {:via, Registry, {scraper_id, :links_buffer}}} | links_buffer_opts]
      },
      {
        data_store,
        [{:name, {:via, Registry, {scraper_id, :data_store}}} | data_store_opts]
      },
      {
        Scraper.Scheduler,
        %{
          scraper_id: scraper_id,
          links_buffer: links_buffer,
          data_store: data_store,
          max_workers: max_workers,
          max_depth: max_depth,
          data_selectors: data_selectors,
          link_selectors: link_selectors,
          name: {:via, Registry, {scraper_id, :scheduler}}
        }
      }
    ]

    opts = Keyword.merge([strategy: :one_for_one], opts)

    Supervisor.init(children, opts)
  end
end
