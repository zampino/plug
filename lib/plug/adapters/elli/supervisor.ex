defmodule Plug.Adapters.Elli.Supervisor do
  use Supervisor
  @plug_adapters_elli :plug_adapters_elli

  def start_link options do
    Supervisor.start_link __MODULE__, options, []
  end

  def init(options) do
    children = [
      worker(:elli, [options], [id: @plug_adapters_elli])
    ]
    supervise children, strategy: :one_for_one
  end

  def shutdown do
    case Supervisor.terminate_child(__MODULE__, @plug_adapters_elli) do
      :ok -> Supervisor.delete_child(__MODULE__, @plug_adapters_elli)
      error -> error
    end
  end

end
