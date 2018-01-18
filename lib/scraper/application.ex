defmodule Scraper.Application do
  use Application

  def start(_type, _args) do
    children = [
      Supervisor.child_spec(
        Agent,
        id: LinksBuffer,
        start: {Agent, :start_link, [fn -> [] end, [name: Scraper.LinksBuffer]]}
      ),
      Supervisor.child_spec(
        Agent,
        id: DataStore,
        start: {Agent, :start_link, [&MapSet.new/0, [name: Scraper.DataStore]]}
      ),
      {
        Scraper.WorkerSupervisor,
        name: Scraper.WorkerSupervisor,
        max_children: 5,
      },
      {
        Scraper.Manager,
        name: Scraper.Manager,
      }
    ]

    opts = [strategy: :one_for_one, name: Scraper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
