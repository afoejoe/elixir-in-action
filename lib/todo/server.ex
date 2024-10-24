defmodule Todo.Server do
  use GenServer, restart: :temporary

  @expiry_idle_timeout :timer.seconds(10)

  def start_link(todo_list_name) do
    GenServer.start_link(__MODULE__, todo_list_name, name: via_tuple(todo_list_name))
  end

  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  @impl GenServer
  def init(todo_list_name) do
    IO.puts("Starting Todo Server for #{todo_list_name}")
    {:ok, {todo_list_name, nil}, {:continue, :load}}
  end

  @impl GenServer
  def handle_continue(:load, {todo_list_name, _}) do
    {:noreply, {todo_list_name, Todo.Database.get(todo_list_name) || Todo.List.new()},
     @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_cast({:add_entry, new_entry}, {todo_list_name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, new_entry)

    Todo.Database.store(todo_list_name, new_list)
    {:noreply, {todo_list_name, new_list}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_call({:entries, date}, _, {todo_list_name, todo_list}) do
    {
      :reply,
      Todo.List.entries(todo_list, date),
      {todo_list_name, todo_list},
      @expiry_idle_timeout
    }
  end

  @impl GenServer
  def handle_info(:timeout, {name, todo_list}) do
    IO.puts("Stopping todo server for #{name}")
    {:stop, :normal, {name, todo_list}}
  end

  defp via_tuple(todo_list_name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, todo_list_name})
  end
end
