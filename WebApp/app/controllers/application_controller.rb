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
    @name_text_field.stringValue, @url_text_field.stringValue = (if item.title == 'None'
      ['', '']
    else
      preset = bundles[item.title.to_s].defaults
      [preset['name'], preset['url']]
    end)
  end
  
  private
  
  def bundles
    @bundles ||= WebAppBundle.bundles
  end
end