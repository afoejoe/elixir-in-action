defmodule Todo.Tasks do
  def run do
    1..5
    |> Enum.map(&Task.async(fn -> run_query("query #{&1}") end))
    |> Enum.map(&Task.await/1)
  end

  defp run_query(query_def) do
    Process.sleep(2000)
    "#{query_def} result"
  end
end
