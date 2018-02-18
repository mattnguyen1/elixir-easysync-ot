defmodule ChangesetTest do
	use ExUnit.Case
	doctest Changeset

	test "unpacks changeset correctly" do
		[
			{:old_len, old_len},
			{:new_len, new_len},
			{:ops, ops},
			{:char_bank, char_bank}
		] = Changeset.unpack("Z:5<2=5-4*0+2$hi")
		assert old_len === 5
		assert new_len === 3
		assert ops === "=5-4*0+2"
		assert char_bank === "hi"
	end

	test "packs changeset correctly" do
		packed_cs = Changeset.pack([
			{:old_len, 3},
			{:new_len, 5},
			{:ops, "+2"},
			{:char_bank, "hi"}
		])
		assert packed_cs === "Z:3>2+2$hi"
	end
end
