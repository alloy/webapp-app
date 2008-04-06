# Copyright Manfred Stienstra 2008, Fingertips
class String
  def unindent
    dup.unindent!
  end
  def unindent!
    if m = match(/^(\n+)(\s*)/) or m = match(/([^\n]+)\n(\s*)/)
      spaces = m[2].length
      gsub!(/\n\s{#{spaces}}/, "\n")
    end
    self
  end
end