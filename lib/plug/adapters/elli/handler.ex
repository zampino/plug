defmodule Plug.Adapters.Elli.Handler do
  # @behaviour :elli_handler

  alias :elli_request, as: Request
  # defmodule Req do
  #   defstruct method: nil,
  #             path: "",
  #             args: nil,
  #             raw_path: "",
  #             version: nil,
  #             headers: [],
  #             body: "",
  #             pid: nil,
  #             socket: nil,
  #             callback: nil
  # end

  def init(req, {_plug, _opts}) do
    IO.puts "//////////// request incoming //////////////\n\n#{inspect(req)}" <>
    "\n\n"
    :ignore
  end

  def handle(req, {plug, opts}) do
    conn = connection(req)
    # IO.puts "\n/////////// translate to connection:\n #{inspect(conn)}\n\n"

    conn = plug.call(conn, opts)
    IO.puts "\n((((((((((((((((((((( plug called )))))))))))):\n" <>
      "#{inspect(conn)}\n\n"


    process_connection(conn, plug)
  end


  def downcase_keys(headers) do
    downcase_key = fn({key, value})->
      {String.downcase(key), value}
    end
    Enum.map headers, downcase_key
  end

  def ensure_origin(headers, origin) do
    get_origin = fn({name, value})->
      (name == "origin") && value
    end
    case Enum.find_value(headers, get_origin) do
      nil -> [{"origin", origin} | headers]
      _ -> headers
    end
  end

  # TODO: move to Plug.Adapters.Elli.Conn
  def connection(req) do
    headers = Request.headers(req)

    get_host = fn({name, value})->
      (name == "Host") && value
    end
    host_port = Enum.find_value headers, get_host
    [host, port] = String.split(host_port, ":")

    headers = downcase_keys(headers) |> ensure_origin(host_port)

    {:req,
      method,
      _path,
      _args,
      raw_path,
      _version,
      _headers,
      _body,
      pid,
      _socket,
      _callback} = req

    %Plug.Conn{
      adapter: {__MODULE__, req},
      host: host,
      method: "#{method}",
      owner: self,
      path_info: split_path(raw_path),
      peer: Request.peer(req),
      port: port,
      remote_ip: '100.100.100.100',
      query_string: Request.query_str(req),
      req_headers: headers,
      scheme: :http
    } |> Plug.Conn.put_private :plug_stream_pid, pid
  end

  def read_req_body(req, options) do
    {:req,
      _method,
      _path,
      _args,
      raw_path,
      _version,
      _headers,
      body,
      _pid,
      _socket,
      _callback} = req
    IO.puts "\n -------- reading request body -------\n#{inspect(body)}\n\n"
    {:ok, body, req}
  end

  def send_resp(req, status, headers, body) do
    {:ok, body, req}
  end

  def send_chunked(req, status, headers) do
    {:ok, nil, req}
  end

  def chunk(req, body) do
    pid = Request.chunk_ref(req)
    IO.puts "\n --- about to send chunk ---"
    res = Request.async_send_chunk pid, body
    IO.puts "\n --- chunk sent #{inspect(res)}"
    :ok
  end

  # response processors based on actual connection
  def process_connection(%Plug.Conn{state: :sent}=conn, _plug) do
    IO.puts "\n ||||||| connection being sent |||||||\n\n"
    {conn.status, conn.resp_headers, conn.resp_body}
  end

  def process_connection(%Plug.Conn{state: :chunked}=conn, _plug) do
    IO.puts "\n ||||||| connection being sent |||||||\n\n"
    {:chunk, conn.resp_headers, conn.assigns.init_chunk}
  end

  def process_connection(%Plug.Conn{halted: :true}=conn, _plug) do
    IO.puts "\n ||||||| connection being halted |||||||\n\n"
    exit(:normal)
  end

  # Elli Event handlers

  def handle_event :elli_startup, [], plug do
    IO.puts "\n Elli Started! #{inspect(plug)} \n\n"
    :ok
  end

  def handle_event :request_parse_error, args1, args2 do
    IO.puts "Elli Started! #{inspect(args1)} -- #{inspect(args2)}"
    :ok
  end

  def handle_event :chunk_complete, [req, 200, _headers, _end, _timings], _ do
    IO.puts "\n--- chunk complete ---\n\n"
    Process.exit Request.chunk_ref(req), :unknown
    :ok
  end

  def handle_event :request_error, [_req, err, stacktrace], _args do
    IO.puts "\n--------------------- ERROR ------------------\n" <>
      "#{inspect(err)}\n" <>
      "#{inspect(stacktrace)}\n" <>
      "--------------------------------------------------------"
  end

  def handle_event(other, _, _) do
    IO.puts "[EVENT]: #{inspect(other)}"
  end

  defp split_path(path) do
    segments = :binary.split(path, "/", [:global])
    for segment <- segments, segment != "", do: segment
  end
end
