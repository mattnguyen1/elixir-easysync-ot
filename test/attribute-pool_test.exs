defmodule AttributePoolTest do
  use ExUnit.Case
  doctest AttributePool

  test "putting in the same attribute should return an unchanged pool" do
    pool = %AttributePool{} |>
      AttributePool.put(["author", 123])
    assert pool === %AttributePool{
      attr_to_num: %{"[author,123]" => 0},
      next_num: 1,
      num_to_attr: %{0 => ["author", "123"]}
    }

    pool = AttributePool.put(pool, ["author", 123])
    assert pool === %AttributePool{
      attr_to_num: %{"[author,123]" => 0},
      next_num: 1,
      num_to_attr: %{0 => ["author", "123"]}
    }
  end
end
