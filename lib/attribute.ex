defmodule Attribute do
	@doc """
	Returns a stringified attribute
	"""
	def to_string([attrib, value]) do
		"[#{attrib},#{value}]"
	end

	@doc """
	Returns a list containing a stringified attrib key and value
	"""
	def to_string_list([attrib, value]) do
		["#{attrib}", "#{value}"]
	end
end
