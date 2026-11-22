# encoding: UTF-8
# -----------------------------------------------------------------------------
# Box From Mark  (SketchUp 2019 / Ruby 2.5 compatible)
#
# Kept only so older scripts that call BoxFromMark.run keep working. The
# function is built into the Variable Database: use its "Place Mark" button
# (or Extensions > Place Box From Mark). No selection needed: pick a mark from
# the dropdown and click in the model to place it.
#
# This file adds no menu entry of its own.
#
# Install : copy to  %APPDATA%\SketchUp\SketchUp 2019\SketchUp\Plugins\
# -----------------------------------------------------------------------------

module BoxFromMark
  # Lets this file be re-pasted into the Ruby Console without "already initialized constant" warnings
  constants.each { |c| remove_const(c) }

  def self.run
    unless defined?(VariableDB) && VariableDB.respond_to?(:safe_place_mark)
      UI.messagebox("The 'Variable Database' extension (variable_database.rb) is not loaded " \
                    "or is too old.\nInstall the latest version and restart SketchUp.")
      return
    end
    VariableDB.safe_place_mark
  end
end
