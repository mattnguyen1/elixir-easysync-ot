defmodule OpTest do
  use ExUnit.Case
  doctest Op

  test "creates an Op struct with the correct fields" do
    %Op{
      opcode: opcode,
      attribs: attribs,
      lines: lines,
      chars: chars
    } = Op.from_regex_match(["*0+7", "*0", "0", "+", "7"])
    assert opcode === "+"
    assert attribs === "*0"
    assert lines === 0
    assert chars === 7
  end

  test "return empty array when getting ops from empty string" do
    assert [] === Op.get_ops_from_str("")
  end

  test "should slice an op correctly" do
    op_to_slice = %Op{ opcode: "=", chars: 10, lines: 5, attribs: "*0*1"}
    magnitude_op = %Op{ opcode: "+", chars: 3, lines: 2, attribs: "*3*4"}
    op_to_slice = Op.slice_op(op_to_slice, magnitude_op)

    assert op_to_slice === %Op{
      opcode: "=",
      chars: 7,
      lines: 3,
      attribs: "*0*1"
    }
  end
end
