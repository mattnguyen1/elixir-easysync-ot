defmodule Changeset do
	@moduledoc """
	This module contains a set of functions used to manipulate easysync based
	changesets for operational transforms.
	"""

	defstruct old_len: 0, new_len: 0, ops: "", char_bank: ""

	@doc """
	Returns an empty Changeset struct
	"""
	def new do
		%Changeset{}
	end

	@doc """
	Unpacks a changeset string into a changeset keyword list

	## Examples

		iex> Changeset.unpack("Z:3>5=1*0*1+2=2*0+3$hello")
		%Changeset{old_len: 3, new_len: 8, ops: "=1*0*1+2=2*0+3", char_bank: "hello"}
	"""
	def unpack(cs) do
		[header, old_len, change_sign, len_change]
			= Regex.run(~r/Z:([0-9a-z]+)([><])([0-9a-z]+)|/, cs)
			|> (fn([a, b, c, d]) -> [a, elem(Integer.parse(b), 0), c, elem(Integer.parse(d), 0)] end).()
		change_mag = if change_sign == ">", do: 1, else: -1
		ops_start = String.length(header)
		ops_end = :binary.match(cs, "$") |> elem(0)
		new_len = old_len + len_change * change_mag
		ops = String.slice(cs, ops_start..ops_end-1)
		char_bank = String.slice(cs, ops_end+1..-1)

		%Changeset{
			old_len: old_len, # length of text before changeset is applied
			new_len: new_len, # length of text after changeset is applied
			ops: ops, # change operations on the text
			char_bank: char_bank # characters added in the change
		}
	end

	@doc """
	Packs a Changeset into a string

	## Examples

		iex> Changeset.pack(%Changeset{old_len: 1,new_len: 4,ops: "=1*0+3",char_bank: "hey"})
		"Z:1>3=1*0+3$hey"
	"""
	def pack(cs) do
		len_change = Integer.to_string(cs.new_len - cs.old_len)
		change_sign = if len_change >= 0, do: ">", else: "<"
		old_len = Integer.to_string(cs.old_len)

		"Z:" <> old_len <> change_sign <> len_change <> cs.ops <> "$" <> cs.char_bank
	end
end

defmodule Changeset.Op do
	defstruct opcode: "", chars: 0, lines: 0, attribs: ""

	def new(opts \\ []) do
		%Changeset.Op{
			opcode: Keyword.get(opts, :opcode, "")
		}
	end
end
