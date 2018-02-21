
defmodule Op do
	@moduledoc """
	Module for creating a single changeset operation
	"""

	defstruct opcode: "", chars: 0, lines: 0, attribs: ""

	@doc """
	Return a Op struct
	"""
	def new(opts \\ []) do
		%Op{
			opcode: Keyword.get(opts, :opcode, "")
		}
	end

	@doc """
	Returns a Op struct from a regex map on the op string
	"""
	def from_regex_match([_, attribs, lines, opcode, chars]) do
		lines = unless lines === "",
			do: elem(Integer.parse(lines), 0), else: 0
		chars = elem(Integer.parse(chars), 0)

		%Op{
			opcode: opcode,
			attribs: attribs,
			lines: lines,
			chars: chars
		}
	end

	@doc """
	Returns a list of Op structs from an op string

	## Examples

		iex> Op.get_ops_from_str("*0*3+5-2*0*1+3")
		[
			%Op{attribs: "*0*3", chars: 5, lines: 0, opcode: "+"},
			%Op{attribs: "", chars: 2, lines: 0, opcode: "-"},
			%Op{attribs: "*0*1", chars: 3, lines: 0, opcode: "+"}
		]
	"""
	def get_ops_from_str(op_str) do
		Regex.scan(~r/((?:\*[0-9a-z]+)*)(?:\|([0-9a-z]+))?([-+=])([0-9a-z]+)|\?|/, op_str)
		|> Stream.filter(&(Enum.at(&1, 0) != ""))
		|> Enum.reduce([], fn(match, ops) -> [from_regex_match(match) | ops] end)
		|> Enum.reverse
	end
end
