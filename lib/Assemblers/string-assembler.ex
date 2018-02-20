defmodule StringAssembler do
	defstruct pieces: []
end

defimpl Assem, for: StringAssembler do
	def append(assem, str) do
		%StringAssembler{assem | pieces: [assem.pieces | str]}
	end

	def to_string(assem) do
		"#{assem.pieces}"
	end
end
