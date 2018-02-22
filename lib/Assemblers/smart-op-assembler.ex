defmodule SmartOpAssembler do
	import StringAssembler

	defstruct [
		delete_assem: %MergingOpAssembler{},
		keep_assem: %MergingOpAssembler{},
		insert_assem: %MergingOpAssembler{},
		assem: %StringAssembler{},
		last_opcode: "",
		length_change: 0
	]

	@doc """
	Ends the document by ending the keep assembler
	"""
	def end_document(assem) do
		%SmartOpAssembler{assem |
			keep_assem: MergingOpAssembler.end_document(assem.keep_assem)
		}
	end

	@doc """
	Flush the keeps into the main assembler and reset the keep assembler
	"""
	def flush_keeps(assem) do
		%SmartOpAssembler{assem |
			assem: Assem.append(assem.assem, Assem.to_string(assem.keep_assem)),
			keep_assem: %MergingOpAssembler{}
		}
	end

	@doc """
	Flushes inserts and deletes into the main assembler, and resets the insert
	and delete assemblers
	"""
	def flush_insert_delete(assem) do
		%SmartOpAssembler{assem |
			assem: Assem.append(assem.assem, Assem.to_string(assem.delete_assem))
			|> Assem.append(Assem.to_string(assem.insert_assem)),
			delete_assem: %MergingOpAssembler{},
			insert_assem: %MergingOpAssembler{}
		}
	end
end

defimpl Assem, for: SmartOpAssembler do
	import SmartOpAssembler

	def to_string(assem) do
		assem = flush_insert_delete(assem) |> flush_keeps
		Assem.to_string(assem.assem)
	end

	def append(assem, %Op{opcode: ""}), do: assem
	def append(assem, %Op{chars: 0}), do: assem
	def append(assem, nil), do: assem
	def append(assem, op = %Op{opcode: "-"}) do
		append_with_assem(assem, :delete_assem, op)
	end
	def append(assem, op = %Op{opcode: "+"}) do
		append_with_assem(assem, :insert_assem, op)
	end
	def append(assem, op = %Op{opcode: "="}) do
		append_with_assem(assem, :keep_assem, op)
	end

	defp append_with_assem(assem, opcode_assem_type, op) do
		maybe_flush_before_append(assem, op)
		|> (&(%SmartOpAssembler{&1 |
			last_opcode: op.opcode,
			length_change: get_length_change(&1, op)
		})).()
		|> (&(Map.put(&1, opcode_assem_type, Assem.append(Map.get(&1, opcode_assem_type), op)))).()
	end

	defp get_length_change(assem, op = %Op{opcode: "+"}), do: assem.length_change + op.chars
	defp get_length_change(assem, op = %Op{opcode: "-"}), do: assem.length_change - op.chars
	defp get_length_change(assem, %Op{opcode: "="}), do: assem.length_change

	defp maybe_flush_before_append(assem, %Op{opcode: "="}) do
		if assem.last_opcode !== "=", do: flush_insert_delete(assem), else: assem
	end
	defp maybe_flush_before_append(assem, _) do
		if assem.last_opcode === "=", do: flush_keeps(assem), else: assem
	end
end
