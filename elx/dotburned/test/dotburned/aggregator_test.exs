defmodule DotburnedWeb.AggregatorTest do
  use ExUnit.Case

  alias Dotburned.Aggregator
  alias Phoenix.PubSub
  alias Dotburned.Schema.Burn
  alias Dotburned.Schema.Summary

  #test "aggregator removes old" do
  #  {:ok, pid} = Aggregator.start_link(name: :test)
#
  #  for i <- 30..0//-1 do
  #    PubSub.broadcast(Dotburned.PubSub, "new_burn", %Burn{
  #      id: -i,
  #      timestamp: DateTime.utc_now() |> DateTime.add(-i, :hour),
  #      aggregated: i * 100,
  #      amount: 100,
  #      blockNumber: 1
  #    })
  #  end
#
  #  assert GenServer.call(pid, :buckets_today) == [100 | Enum.map(1..23, fn _ -> 100 end)]
  #end

  test "aggregator computes daily summary" do
    now = DateTime.from_naive!(~N[2021-01-01 00:00:00], "Etc/UTC")

    burns = for i <- 0..9 do
      %Burn{
        id: -i,
        timestamp: now |> DateTime.add(-i, :second),
        aggregated: i * 100,
        amount: 100,
        blockNumber: 1
      }
    end

    assert Aggregator.aggregate!(burns, now, 1, 5) |> elem(0) == [100, 100, 100, 100, 100]
    assert Aggregator.aggregate!(burns, now, 2, 3) |> elem(0) == [200, 200, 200]
    assert Aggregator.aggregate!([], now, 2, 3) |> elem(0) == [0, 0, 0]
    assert Aggregator.aggregate!(burns, now, 1, 11) |> elem(0) == [100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 0]

    assert_raise ArgumentError, fn ->
      Aggregator.aggregate!(burns, now, 0, 3)
    end
    assert_raise ArgumentError, fn ->
      Aggregator.aggregate!(burns, now, 1, 0)
    end
  end
end
