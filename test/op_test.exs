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
end
