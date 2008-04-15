class ApplicationController < Rucola::RCController
  ib_outlet :main_window
  ib_outlet :bundles_menu
  ib_outlet :name_text_field
  ib_outlet :url_text_field
  
  def awakeFromNib
    @bundles_menu.addItemsWithTitles(bundles)
    @bundles_menu.itemArray.each do |item|
      item.target = self
      item.action = 'presetChosen:'
    end
  end
  
  def presetChosen(item)
    @name_text_field.stringValue, @url_text_field.stringValue = (if item.title == 'None'
      ['', '']
    else
      preset = defaults[item.title]
      [preset['name'], preset['url']]
    end)
  end
  
  private
  
  def bundles
    Dir.glob("#{Rucola::RCApp.root_path}/bundles/*.wabundle").map { |bundle| bundle.scan(/\/(\w+)\.wabundle$/).first.first }
  end
  
  def defaults
    {
      'Campfire' => { 'name' => 'Campfire', 'url' => 'http://CHANGEME.campfirenow.com' },
      'Twitter' => { 'name' => 'Twitter', 'url' => 'http://twitter.com/CHANGEME' }
    }.to_ns
  end
end