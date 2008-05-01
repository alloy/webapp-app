class CampfirePreferencesController < OSX::NSWindowController
  def init
    self if self.initWithWindowNibPath_owner(File.expand_path('../../views/CampfirePreferences.nib', __FILE__), self)
  end
end