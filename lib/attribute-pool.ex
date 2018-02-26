defmodule AttributePool do
	defstruct num_to_attr: %{}, attr_to_num: %{}, next_num: 0

	@doc """
	Puts an attribute into the pool
	"""
	def put(pool, attrib) do
		if Map.has_key?(pool.attr_to_num, Attribute.to_string(attrib)) do
			pool
		else
			%AttributePool{pool |
				num_to_attr: Map.put(
					pool.num_to_attr,
					pool.next_num,
					Attribute.to_string_list(attrib)
				),
				attr_to_num: Map.put(
					pool.attr_to_num,
					Attribute.to_string(attrib),
					pool.next_num
				),
				next_num: pool.next_num + 1
			}
		end
	end

	@doc """
	Gets an attribute from a pool
	"""
	def get(pool, num) do
		Map.get(pool.num_to_attr, num)
	end

	@doc """
	Gets an attribute as a tuple from a pool
	"""
	def get_as_tuple(pool, num) do
		get(pool, num)
		|> (fn [key, value] -> {key, value} end).()
	end

	@doc """
	Gets the attrib num from a pool
	"""
	def get_num(pool, attrib) do
		Map.get(pool.attr_to_num, Attribute.to_string(attrib))
	end

	def get_num_str(pool, attrib) do
		get_num(pool, attrib)
		|> ChangesetHelpers.num_to_base36_str()
	end
end
