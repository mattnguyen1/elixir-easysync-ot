defprotocol Assem do
  @doc """
  Returns a string of the joined pieces of an assembler
  """
  def to_string(assem)

  @doc """
  Appends an item onto the end of an assembler
  """
  def append(assem, item)
end
