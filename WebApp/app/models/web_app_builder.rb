class WebAppBuilder
  attr_reader :name, :path, :full_path
  
  def initialize(name, url, path)
    @name, @url, @path, @full_path = name, url, path, File.join(path, name) << '.app'
  end
  
  def create_base_application!
    unpack!
    write_info_plist!
    write_info_plist_strings!
  end
  
  def unpack!
    pkg = File.join(Rucola::RCApp.assets_path, 'webapp_base_app.tar.bz2')
    system "/usr/bin/tar -xjf #{pkg} --directory /tmp/ && mv /tmp/CampfireTest.app #{full_path}"
  end
  
  def write_info_plist!
    plist_path = File.join(full_path, 'Contents', 'Info.plist')
    plist = OSX::NSDictionary.dictionaryWithContentsOfFile(plist_path)
    
    plist['WebAppURL'] = @url
    plist['CFBundleIdentifier'] = "nl.superalloy.webapp.#{@name}"
    
    plist.writeToFile_atomically(plist_path, true)
  end
  
  def write_info_plist_strings!
    strings = File.join(full_path, 'Contents', 'Resources', 'English.lproj', 'InfoPlist.strings')
    File.open(strings, 'w') do |file|
      copyright = "\"WebApp application\\nCopyright 2008 Eloy Duran <e.duran@superalloy.nl>.\""
      file.write "CFBundleName = \"#{@name}\";\nCFBundleGetInfoString = #{copyright};\nNSHumanReadableCopyright = #{copyright};"
    end
  end
end