defmodule ChangesetHelpers do
	@doc """
	Convert an integer to a string of the integer in base 36
	"""
	def num_to_base36_str(num) do
		Integer.to_string(num, 36)
		|> String.downcase
	end

	@doc """
	Convert a string of a base 36 number to an integer in base 10
	"""
	def base36_str_to_num(str) do
		elem(Integer.parse(str, 36), 0)
	end

	@doc """
	Returns whether two ops can properly merge into a single op
	"""
	def ops_can_merge?(op1, op2) do
		op1.opcode === op2.opcode &&
		op1.attribs === op2.attribs
	end
end
