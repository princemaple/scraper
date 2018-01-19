defmodule Scraper.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    {server_opts, opts} = Keyword.split(opts, [:name])
    Supervisor.start_link(__MODULE__, opts, server_opts)
  end

  def init(opts) do
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
        name: Scraper.WorkerSupervisor, max_children: 5
      },
      {
        Scraper.Manager,
        name: Scraper.Manager
      }
    ]

    opts = Keyword.merge([strategy: :one_for_one], opts)

    Supervisor.init(children, opts)
  end
end
