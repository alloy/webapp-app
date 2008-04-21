class ApplicationController < Rucola::RCController
  ib_outlet :main_window
  ib_outlet :bundles_menu
  ib_outlet :name_text_field
  ib_outlet :url_text_field
  
  def awakeFromNib
    @bundles_menu.addItemsWithTitles(bundles.keys)
    @bundles_menu.itemArray.each do |item|
      item.target = self
      item.action = 'presetChosen:'
    end
  end
  
  def presetChosen(item)
    if item.title == 'None'
      @name_text_field.stringValue, @url_text_field.stringValue = ['', '']
    else
      preset = bundles[item.title.to_s].defaults
      @name_text_field.stringValue, @url_text_field.stringValue = preset['name'], preset['url']
      
      if start = preset['url'].index('CHANGEME')
        @url_text_field.selectText(self)
        @url_text_field.window.firstResponder.selectedRange = OSX::NSRange.new(start..(start + 7))
      end
    end
  end
  
  private
  
  def bundles
    @bundles ||= WebAppBundle.bundles
  end
end