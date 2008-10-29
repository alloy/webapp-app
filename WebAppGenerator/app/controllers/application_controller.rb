class ApplicationController < Rucola::RCController
  ib_outlet :steps_tab_view
  
  kvc_accessor :url, :bundle, :name
  ib_outlet :continue_button
  
  def url=(url)
    @url = url.to_s
    @continue_button.enabled = !!(@url =~ /^https?:\/\/\w+\.\w+/)
  end
  
  def nextStep(sender)
    if bundle = WebAppBundle.bundle_for_url(@url)
      self.bundle = bundle
      self.name = bundle.name
    end
    
    @steps_tab_view.selectNextTabViewItem(self)
  end
  
  def createApp(sender)
    builder = WebAppBuilder.new(@name.to_s, @url, '/Applications', @bundle)
    builder.create_base_application
    OSX::NSWorkspace.sharedWorkspace.selectFile_inFileViewerRootedAtPath(builder.full_path, '')
  end
end