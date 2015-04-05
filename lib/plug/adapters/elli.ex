defmodule Plug.Adapters.Elli do
  alias Plug.Adapters.Elli

  @moduledoc """
  Adapter interface to the Elli webserver.

  ## Options

  * `:ip` - the ip to bind the server to.
    Must be a tuple in the format `{x, y, z, w}`.

  * `:port` - the port to run the server.
    Defaults to 4000 (http) and 4040 (https).

  * `:acceptors` - the number of acceptors for the listener.
    Defaults to 100.

  * `:max_connections` - max number of connections supported.
    Defaults to `:infinity`.

  * `:ref` - the reference name to be used.
    Defaults to `plug.HTTP` (http) and `plug.HTTPS` (https).
    This is the value that needs to be given on shutdown.

  """

  @doc """
  Run cowboy under http.

  ## Example

      # Starts a new interface
      Plug.Adapters.Elli.http MyPlug, [], port: 80

      # The interface above can be shutdown with
      Plug.Adapters.Elli.shutdown MyPlug.HTTP

  """
  @spec http(module(), Keyword.t, Keyword.t) ::
      {:ok, pid} | {:error, :eaddrinuse} | {:error, term}
  def http(plug, options, elli_options) do
    run(:http, plug, options, elli_options)
  end

  def run(:http, plug, options, elli_options) do
    opts = Keyword.put(elli_options, :callback, Elli.Handler)
    |> Keyword.put(:callback_args, {plug, options})

    default_elli_options
    |> Keyword.merge(opts)
    |> Elli.Supervisor.start_link()
  end

  def default_elli_options do
    [port: 4000]
  end

  def shutdown do
    Elli.Supervisor.shutdown
  end
end
