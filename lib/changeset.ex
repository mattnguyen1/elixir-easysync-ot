defmodule Changeset do
	@moduledoc """
	This module contains a set of functions used to manipulate easysync based
	changesets for operational transforms.
	"""
	defstruct old_len: 0, new_len: 0, ops: "", char_bank: ""

	import Op
	import ChangesetHelpers

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

	# Exhausted all ops
	def apply_zip(assem, [], [], nil, nil, _) do
		SmartOpAssembler.end_document(assem)
		|> Assem.to_string
	end

	# Some op still can be taken
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

	@doc """
	Zip function that will use a composition strategy when zipping two ops in
	order to produce a single op.
	Composition strategy is the following priority list:
	1. Base op deletes, so the next op isn't taken into account yet since there
	is no opcode that can change the fact that the base op has deleted something.
	In this case, just output the base op.
	2. There is no base op, so just output the next op.
	3. Next op deletes, which means it is deleting something that the base op
	is either keeping or adding. Output an op with the magnitude of what was deleted.
	4. Next op inserts, in which case, the base op would not have any knowledge about,
	and so just output the next op.
	5. Next op keeps, which means just keep whatever was in the base op, and if needed,
	compose the attributes if the next op keep had any.
	"""
	def zip_by_compose(base_op, next_op, pool)

	# Base op is a delete -> output base op
	def zip_by_compose(base_op = %Op{opcode: "-"}, next_op, _), do: {nil, next_op, base_op}

	# Base op is exhausted -> output next op
	def zip_by_compose(nil, next_op, _), do: {nil, nil, next_op}

	# Next op is a delete -> output a deletion with no attribs of the amount sliced
	def zip_by_compose(base_op, next_op = %Op{opcode: "-"}, _) do
		slice(base_op, next_op, base_op.opcode === "=")
		|> modify_compose_output("-", "")
	end

	# Next op is an insert -> output the next op
	def zip_by_compose(base_op, next_op = %Op{opcode: "+"}, _) do
		{base_op, :nil, next_op}
	end

	# Next op is a keep ->
	def zip_by_compose(base_op, next_op = %Op{opcode: "="}, pool) do
		{base_op, next_op, output_op} = slice(base_op, next_op, true)
		{base_op, next_op, %Op{output_op |
			attribs: ""
		}}
	end

	defp slice(base_op, next_op, has_output_op) do
		cond do
			base_op.chars === next_op.chars ->
				{:nil, :nil, maybe_copy(base_op, has_output_op)}
			base_op.chars > next_op.chars ->
				{Op.slice_op(base_op, next_op), :nil, maybe_copy(next_op, has_output_op)}
			true ->
				{:nil, Op.slice_op(next_op, base_op), maybe_copy(base_op, has_output_op)}
		end
	end

	defp maybe_copy(op_to_copy, true), do: Op.copy_magnitude(op_to_copy)
	defp maybe_copy(_, false), do: :nil

	defp modify_compose_output(result = {_, _, nil}, _, _), do: result
	defp modify_compose_output({base_op, next_op, output_op}, opcode, attribs),
		do: {base_op, next_op, %Op{output_op | opcode: opcode, attribs: attribs}}

	@doc """
	Composes two attribute strings into a single attribute string
	"""
	def compose_attributes(base_attrib_str, next_attrib_str, can_delete_attrib, pool)

	# Only next attrib string exists
	def compose_attributes(:nil, next_attrib_str, true, _), do: next_attrib_str

	# Only base attrib string exists
	def compose_attributes(base_attrib_str, :nil, _, _), do: base_attrib_str

	# Both strings exist, so compose
	def compose_attributes(base_attrib_str, next_attrib_str, can_delete_attrib, pool) do
		attrib_map = attrib_str_to_map(base_attrib_str, pool)
		next_attrib_num_list = attrib_str_to_num(next_attrib_str)

		Enum.reduce(next_attrib_num_list, attrib_map, fn attr_num, map ->
			[attrib_key, attrib_value] = AttributePool.get(pool, attr_num)
			if Map.has_key?(map, attrib_key) do
				maybe_put_attrib(map, attrib_key, attrib_value, can_delete_attrib)
				|> maybe_delete_attrib(attrib_key, attrib_value, can_delete_attrib)
			else
				maybe_put_attrib(map, attrib_key, attrib_value, can_delete_attrib)
			end
		end)
		|> Map.to_list()
		|> Enum.sort_by(&{elem(&1, 0), String.first(elem(&1, 1))})
		|> Enum.map(fn {k, v} -> [k, v] end)
		|> Enum.reduce(%StringAssembler{}, fn attrib, assem ->
			pool = AttributePool.put(pool, attrib)
			Assem.append(assem, "*")
			|> Assem.append(AttributePool.get_num_str(pool, attrib)) end)
		|> (&({pool, Assem.to_string(&1)})).()
	end

	defp maybe_put_attrib(map, attrib_key, new_attrib_val, can_delete_attrib)
	defp maybe_put_attrib(map, _, "", false), do: map
	defp maybe_put_attrib(map, attrib_key, new_attrib_val, _),
		do: Map.put(map, attrib_key, new_attrib_val)

	defp maybe_delete_attrib(map, attrib_key, new_attrib_val, can_delete_attrib)
	defp maybe_delete_attrib(map, attrib_key, "", false),
		do: Map.delete(map, attrib_key)
	defp maybe_delete_attrib(map,_,_,_), do: map

	defp attrib_str_to_num(attrib_str) do
		Regex.scan(~r/\*([0-9a-z]+)/, attrib_str)
		|> Enum.map(fn [_, num] -> base36_str_to_num(num) end)
	end
	defp attrib_str_to_map(attrib_str, pool) do
		attrib_str_to_num(attrib_str)
		|> Map.new(&AttributePool.get_as_tuple(pool, &1))
	end
end
