class WebAppBuilder
  attr_reader :name, :path, :full_path
  
  def initialize(name, url, path, bundle)
    @name, @url, @path, @bundle, @full_path = name, url, path, bundle, File.join(path, name) << '.app'
  end
  
  def create_base_application!
    unpack!
    write_info_plist!
    write_info_plist_strings!
    copy_bundle!
  end
  
  def unpack!
    pkg = File.join(Rucola::RCApp.assets_path, 'webapp_base_app.tar.bz2')
    system "/usr/bin/tar -xjf #{pkg} --directory /tmp/ && mv /tmp/WebAppApplication.app #{full_path}"
  end
  
  def write_info_plist!
    plist_path = path_to('Info.plist')
    plist = OSX::NSDictionary.dictionaryWithContentsOfFile(plist_path)
    
    plist['WebAppURL'] = @url
    plist['CFBundleIdentifier'] = "nl.superalloy.webapp.#{@name}"
    
    plist.writeToFile_atomically(plist_path, true)
  end
  
  def write_info_plist_strings!
    strings = path_to('Resources/English.lproj/InfoPlist.strings')
    File.open(strings, 'w') do |file|
      copyright = "\"WebApp application\\nCopyright 2008 Eloy Duran <e.duran@superalloy.nl>.\""
      file.write "CFBundleName = \"#{@name}\";\nCFBundleGetInfoString = #{copyright};\nNSHumanReadableCopyright = #{copyright};"
    end
  end
  
  def copy_bundle!
    if @bundle
      FileUtils.cp_r @bundle.path, path_to('Resources/bundles/')
    end
  end
  
  private
  
  def path_to(file)
    File.join full_path, 'Contents', file
  end
end