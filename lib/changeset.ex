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

	# def apply_zip(op_str_1, index_1, op_str_2, index_2, zip_func) do
	# 	ops1 = Op.get_ops_from_str(op_str_1)
	# 		|> Enum.slice(index_1..-1)
	# 	ops2 = Op.get_ops_from_str(op_str_2)
	# 		|> Enum.slice(index_2..-1)
	#
	# 	apply_zip(ops1, ops2, zip_func)
	# end
	#
	# def apply_zip([], [], zip_func)
end

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
