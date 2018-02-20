defmodule ChangesetHelpers do
	def num_to_base36_str(num) do
		Integer.to_string(num, 36)
		|> String.downcase
	end

	def ops_can_merge?(op1, op2) do
		op1.opcode === op2.opcode &&
		op1.attribs === op2.attribs
	end
end
