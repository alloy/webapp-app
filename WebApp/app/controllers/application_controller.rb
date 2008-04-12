class ApplicationController < Rucola::RCController
  ib_outlet :main_window
  
  def awakeFromNib
  end
  
  private
  
  def bundles
    Dir.glob("#{Rucola::RCApp.root_path}/bundles/*.wabundle").map { |bundle| File.basename(bundle) }
  end
  
  def bundle_menu_items
    bundles.map do |name|
      item = OSX::NSMenuItem.alloc.init
      item.title = name
      item
    end
  end
end