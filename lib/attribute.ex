defmodule Attribute do
	@doc """
	Returns a stringified attribute

	## Examples

		iex>Attribute.to_string(["bold", true])
		"[bold,true]"
	"""
	def to_string([attrib, value]) do
		"[#{attrib},#{value}]"
	end

	@doc """
	Returns a list containing a stringified attrib key and value

	## Examples

		iex>Attribute.to_string_list(["author", "12345"])
		["author", "12345"]
		iex>Attribute.to_string_list(["italics", false])
		["italics", "false"]
	"""
	def to_string_list([attrib, value]) do
		["#{attrib}", "#{value}"]
	end
end
