defmodule Changeset do
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

		[
			{:old_len, old_len}, # length of text before changeset is applied
			{:new_len, new_len}, # length of text after changeset is applied
			{:ops, ops}, # change operations on the text
			{:char_bank, char_bank} # characters added in the change
		]
	end

	def pack([{:old_len, old_len}, {:new_len, new_len}, {:ops, ops}, {:char_bank, char_bank}]) do
		len_change = Integer.to_string(new_len - old_len)
		change_sign = if len_change >= 0, do: ">", else: "<"
		old_len = Integer.to_string(old_len)
		new_len = Integer.to_string(new_len)

		"Z:" <> old_len <> change_sign <> new_len <> ops <> "$" <> char_bank
	end
end
