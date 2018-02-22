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

	@doc """
	Iterates over two op strings and applies a zip function over the ops
	to continuously output new ops until a new op string is formed.
	"""
	def apply_zip(op_str_1, index_1, op_str_2, index_2, zip_func) do
		ops1 = Op.get_ops_from_str(op_str_1)
			|> Enum.slice(index_1..-1)
		ops2 = Op.get_ops_from_str(op_str_2)
			|> Enum.slice(index_2..-1)
		assem = %SmartOpAssembler{}

		apply_zip(assem, ops1, ops2, nil, nil, zip_func)
	end
	def apply_zip(assem, [], [], nil, nil, _) do
		SmartOpAssembler.end_document(assem)
		|> Assem.to_string
	end
	def apply_zip(assem, op_list1, op_list2, op1, op2, zip_func) do
		[op1 | op_list1] = take_op(op1, op_list1)
		[op2 | op_list2] = take_op(op2, op_list2)
		{op1, op2, op_out} = zip_func.(op1, op2)
		apply_zip(
			Assem.append(assem, op_out),
			op_list1, op_list2, op1, op2, zip_func
		)
	end

	defp take_op(nil, arr = [_ | _]), do: arr
	defp take_op(nil, []), do: [nil | []]
	defp take_op(op, arr), do: [op | arr]
end
