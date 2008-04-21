class WebAppBundle
  class << self
    def bundles
      bundles = {}
      Dir.glob("#{Rucola::RCApp.root_path}/bundles/*.wabundle").each do |path|
        bundle = WebAppBundle.new(path)
        bundles[bundle.display_name] = bundle
      end
      bundles
    end
  end
  
  attr_reader :path, :display_name
  
  def initialize(path)
    @path = path
    @display_name = path.scan(/(\w+)\.wabundle$/).first.first
  end
  
  def defaults
    YAML.load File.read(File.join(@path, 'defaults.yml'))
  end
end