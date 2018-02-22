defmodule MergingOpAssembler do
	defstruct assem: %OpAssembler{}, buf_op: %Op{}, chars_after_newline: 0

	@doc """
	Returns the flushed assembler with the intent to end the document
	"""
	def end_document(assem), do: flush(assem, true)

	@doc """
	Appends the buffer op if it exists. Also append an extra buffer if there
	is something to add after the newline
	"""
	def flush(assem = %MergingOpAssembler{buf_op: %Op{opcode: ""}}), do: assem
	def flush(assem) do
		%MergingOpAssembler{assem |
			assem: OpAssembler.append(assem.assem, assem.buf_op)
		}
		|> maybe_flush_chars_after_newline(assem.chars_after_newline)
	end

	@doc """
	Attempts to append the buffer op as long as the document isn't ending while
	the buffer op is an implicit keep. (An implicit keep is a keep at the
	end of a changeset without any attribs)
	"""
	def flush(assem = %MergingOpAssembler{buf_op: %Op{ opcode: "=", attribs: ""}}, true), do: assem
	def flush(assem, _), do: flush(assem)

	# If there are chars after newline, then append them into the assembler
	defp maybe_flush_chars_after_newline(assem, 0), do: assem
	defp maybe_flush_chars_after_newline(assem, chars_after_newline) do
		%MergingOpAssembler{assem |
			assem: OpAssembler.append(assem.assem, %Op{assem.buf_op |
				lines: 0, chars: chars_after_newline}),
			buf_op: %Op{},
			chars_after_newline: 0
		}
	end
end

defimpl Assem, for: MergingOpAssembler do
	import ChangesetHelpers
	import MergingOpAssembler

	@doc """
	Returns the op string of a flushed assembler
	"""
	def to_string(assem) do
		OpAssembler.to_string(flush(assem).assem)
	end

	@doc ~S"""
	Appends an op into the op assembler. If the op's opcode and attribs do not
	match the buffer, then it is not mergable, and the buffer must be flushed
	and reset to be the appended op.

	If they are mergable, then, we must decide how it merges into the buffer.
	If an op is multilined, it can always merge safely, but if it is not, then
	it either must go after multiline buffer, or merge safely with an inline
	buffer.

	## Example
		[xxx\\n, yyy] -> yyy cannot merge
		[xxx\\n, y\\ny\\ny] -> [xxx\\ny\\ny]
		[xxx, y\\ny] -> [xxxy\\ny]
		[xxx, yyy] -> [xxxyyy]
	"""
	def append(assem, %Op{ chars: 0}), do: assem
	def append(assem, op) do
		assem
		|> merge_op_or_flush_buffer(op, ops_can_merge?(assem.buf_op, op))
	end

	# Merge
	defp merge_op_or_flush_buffer(assem, op, true), do: merge_op_into_buffer(assem, op)
	# Flush
	defp merge_op_or_flush_buffer(assem, op, false) do
		flush(assem)
		|> (&(%MergingOpAssembler{&1 | buf_op: op})).()
	end

	# Neither the buffer nor the op is multi-lined, so just modify the chars
	defp merge_op_into_buffer(assem = %MergingOpAssembler{buf_op: %Op{lines: 0}}, op = %Op{lines: 0}) do
		%MergingOpAssembler{assem |
			buf_op: %Op{assem.buf_op |
				chars: assem.buf_op.chars + op.chars
			}
		}
	end
	# Op is not multilined, but buffer is, so modify chars_after_newline with op
	defp merge_op_into_buffer(assem, op = %Op{lines: 0}) do
		%MergingOpAssembler{assem |
			chars_after_newline: assem.chars_after_newline + op.chars
		}
	end
	# Op is multilined, so it is always mergable into the buffer
	defp merge_op_into_buffer(assem, op) do
		%MergingOpAssembler{assem |
			buf_op: %Op{assem.buf_op |
				chars: assem.buf_op.chars + op.chars + assem.chars_after_newline,
				lines: assem.buf_op.lines + op.lines
			},
			chars_after_newline: 0
		}
	end
end
