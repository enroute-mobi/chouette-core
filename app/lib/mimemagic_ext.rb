require 'mimemagic'

class MimeMagic

  # Returns true if type is a XML format
  def xml?; child_of?('application/xml'); end

  # Returns true if type is a ZIP format
  def zip?; child_of?('application/zip'); end

end
