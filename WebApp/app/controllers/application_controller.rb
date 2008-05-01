class ApplicationController < Rucola::RCController
  EMPTY_IMAGE = OSX::NSImage.alloc.init
  
  ib_outlet :main_window
  ib_outlet :bundles_menu
  ib_outlet :name_text_field
  ib_outlet :url_text_field
  ib_outlet :path_text_field
  ib_outlet :icon_image_well
  
  def awakeFromNib
    @bundles_menu.addItemsWithTitles(bundles.keys)
    @bundles_menu.itemArray.each do |item|
      item.target = self
      item.action = 'presetChosen:'
    end
  end
  
  def presetChosen(item)
    if item.title == 'None'
      set_name_and_url('', '')
      @icon_image_well.image = EMPTY_IMAGE
    else
      bundle = bundles[item.title.to_s]
      defaults = bundle.defaults
      set_name_and_url(defaults['name'], defaults['url'])
      
      if start = defaults['url'].index('CHANGEME')
        @url_text_field.selectText(self)
        @url_text_field.window.firstResponder.selectedRange = OSX::NSRange.new(start..(start + 7))
      end
      
      if bundle.icon
        @icon_image_well.image = OSX::NSImage.alloc.initWithContentsOfFile(bundle.icon)
      else
        @icon_image_well.image = EMPTY_IMAGE
      end
    end
  end
  
  def openBrowsePanel(sender)
    panel = OSX::NSOpenPanel.openPanel
    panel.canChooseDirectories, panel.canChooseFiles = true, false
    if panel.runModalForDirectory_file_types('/Applications', nil, nil) == OSX::NSOKButton
      @path_text_field.stringValue = panel.filenames.first
    end
  end
  
  def createApp(sender)
    builder = WebAppBuilder.new(@name_text_field.stringValue, @url_text_field.stringValue, @path_text_field.stringValue, selected_bundle)
    builder.create_base_application!
    OSX::NSWorkspace.sharedWorkspace.selectFile_inFileViewerRootedAtPath(builder.full_path, '')
  end
  
  private
  
  def set_name_and_url(name, url)
    @name_text_field.stringValue, @url_text_field.stringValue = name, url
  end
  
  def bundles
    @bundles ||= WebAppBundle.bundles
  end
  
  def selected_bundle
    bundles[@bundles_menu.selectedItem.title.to_s]
  end
end