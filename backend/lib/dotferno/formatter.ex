defmodule Dotferno.Format do
  def plank_to_dot(amount) do
    amount / 10000000000
  end

  def fmt_time_ago(time, now \\ nil) do
    now = now || DateTime.utc_now()
    since = now |> DateTime.diff(time, :second)

    cond do
      since < 60 -> "just now"
      since < 3600 -> "#{d(since, 60)}m ago"
      since < 86400 -> "#{d(since, 3600)}h ago"
      since < 604800 -> "#{d(since, 86400)}d ago"
      true -> time |> DateTime.to_iso8601()
    end
  end

  def fmt_plank(amount, no_unit \\ false) do
    amount |> plank_to_dot() |> fmt_dot(no_unit)
  end

  def fmt_dot(dot, no_unit \\ false) do
    cond do
      dot < 1000 -> {Kernel.round(dot), "DOT"}
      dot < 1000000 -> {d(dot, 1000), "K DOT"}
      dot < 1000000000 -> {d(dot, 1000000, 1), "M DOT"}
    end
    |> case do
      {v, _u} when no_unit -> v
      {v, u} -> "#{v}#{u}"
    end
  end

  defp d(a, b, prec \\ 0) do
    a / b
    |> case do
      v when prec == 0 -> Kernel.round(v)
      v -> Float.round(v, prec)
    end
  end

  def link_block(block) do
    "https://polkadot.subscan.io/event?block=#{block}&page=1&time_dimension=date&module=balances&event_id=burned"
  end
end
