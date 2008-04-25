class WebAppBuilder
  attr_reader :name, :path, :full_path
  
  def initialize(name, path)
    @name, @path, @full_path = name, path, File.join(path, name) << '.app'
  end
  
  def create_base_application!
    
  end
end