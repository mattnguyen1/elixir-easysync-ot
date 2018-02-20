defmodule OpAssembler do
	import ChangesetHelpers
	defstruct pieces: []

	@doc """
	Returns the op string
	"""
	def to_string(assem) do
		"#{assem.pieces}"
	end

	@doc """
	Appends an op onto the assembler
	"""
	def append(assem, op) do
		new_pieces = [assem.pieces | op.attribs]
		|> maybe_append_lines(op.lines)
		|> (&([&1 | op.opcode])).()
		|> (&([&1 | num_to_base36_str(op.chars)])).()

		%OpAssembler{assem |
			pieces: new_pieces
		}
	end

	defp maybe_append_lines(pieces, 0), do: pieces
	defp maybe_append_lines(pieces, lines), do: [pieces | "|#{num_to_base36_str(lines)}"]
end
