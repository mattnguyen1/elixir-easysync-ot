
defmodule Op do
	@moduledoc """
	Module for creating a single changeset operation
	"""
	defstruct opcode: "", chars: 0, lines: 0, attribs: ""

	@doc """
	Returns a Op struct from a regex map on the op string

	## Examples

		iex>Op.from_regex_match(["*0*2|3+7", "*0*2", "3", "+", "7"])
		%Op{
			opcode: "+",
			attribs: "*0*2",
			lines: 3,
			chars: 7
		}
	"""
	def from_regex_match([_, attribs, lines, opcode, chars]) do
		{lines, _} = parse_integer(lines)
		{chars, _} = parse_integer(chars)
		%Op{
			opcode: opcode,
			attribs: attribs,
			lines: lines,
			chars: chars
		}
	end
	defp parse_integer(str), do: if str === "", do: {0, ""}, else: Integer.parse(str)

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

	@doc """
	Copies the magnitude of the chars and lines of an op, but not its opcode
	or its attributes.

	## Examples

		iex> Op.copy_magnitude(%Op{chars: 5, lines: 2, attribs: "*0", opcode: "+"})
		%Op{chars: 5, lines: 2, attribs: "", opcode: ""}
	"""
	def copy_magnitude(op_to_copy) do
		%Op{op_to_copy |
			opcode: "",
			attribs: ""
		}
	end

	def slice_op(op_to_slice, magnitude_op) do
		%Op{op_to_slice |
			chars: op_to_slice.chars - magnitude_op.chars,
			lines: op_to_slice.lines - magnitude_op.lines
		}
	end
end
