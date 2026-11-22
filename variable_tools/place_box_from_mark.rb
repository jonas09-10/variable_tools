# encoding: UTF-8
# -----------------------------------------------------------------------------
# Place Box From Mark  (SketchUp 2019 / Ruby 2.5 compatible)
#
# The placing tool now lives INSIDE the Variable Database (variable_database.rb):
# open Extensions > Variable Database and click the "Place Mark" button.
#
# This small file only keeps the Extensions > Place Box From Mark menu entry and
# the PlaceBoxFromMark.run call working. It does exactly what the "Place Mark"
# button does: no selection needed, pick a mark from the dropdown, click in the
# model to place it (box, or the imported shape if the mark has one).
#
# Install : copy to  %APPDATA%\SketchUp\SketchUp 2019\SketchUp\Plugins\
# Run     : Extensions > Place Box From Mark   (or  PlaceBoxFromMark.run )
# -----------------------------------------------------------------------------

module PlaceBoxFromMark
  # Lets this file be re-pasted into the Ruby Console without "already initialized constant" warnings
  constants.each { |c| remove_const(c) }

  MENU_NAME = 'Place Box From Mark'.freeze

  def self.run
    unless defined?(VariableDB) && VariableDB.respond_to?(:safe_place_mark)
      UI.messagebox("The 'Variable Database' extension (variable_database.rb) is not loaded " \
                    "or is too old.\nInstall the latest version and restart SketchUp.")
      return
    end
    VariableDB.safe_place_mark
  end

  # Register menu item once
  unless file_loaded?('place_box_from_mark.rb:menu')
    UI.menu('Extensions').add_item(MENU_NAME) { PlaceBoxFromMark.run }
    file_loaded('place_box_from_mark.rb:menu')
  end
end
