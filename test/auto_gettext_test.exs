defmodule AutoGettextTest do
  use ExUnit.Case
  doctest AutoGettext

  test "greets the world" do
    assert AutoGettext.hello() == :world
  end
end
