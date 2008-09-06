require 'uri'

class ApplicationController < Rucola::RCController
  ib_outlet :steps_tab_view
  
  kvc_accessor :url, :bundle
  ib_outlet :continue_button
  
  # def awakeFromNib
  #   @bundle = nil
  # end
  
  def url=(url)
    @url = url.to_s
    @continue_button.enabled = !!(@url =~ /^https?:\/\/\w+\.\w+/)
  end
  
  def nextStep(sender)
    #setValue_forKey(WebAppBundle.bundle_for_url(@url), 'bundle')
    self.bundle = WebAppBundle.bundle_for_url(@url)
    @steps_tab_view.selectNextTabViewItem(self)
  end
end