# encoding: UTF-8
# Registers the "Variable Database Tools" extension (loads variable_tools/main.rb)
require 'sketchup.rb'
require 'extensions.rb'

module VariableToolsLoader
  unless file_loaded?('variable_tools.rb:register')
    ext = SketchupExtension.new('Variable Database Tools', 'variable_tools/main')
    ext.description = 'Variable Database with four sheets (Footing Schedule, Footing Tabulation, ' \
                      'Bulk Excavation and Miscellaneous; marks are components, forms and volume ' \
                      'outputs, custom input columns, column filters, Grid X / Grid Y, resizable ' \
                      'columns, editable TOC / top / bottom elevations, Color by column, Import ' \
                      'Selection, Place Mark) plus Excavation From Footing, Box To Next Face, ' \
                      'Move To Elevation, Move Top To Elevation, Hollow Solid Intersection and ' \
                      'Hollow Inverted Trapezoid BBox.'
    ext.version     = '3.4.0'
    ext.creator     = 'Custom'
    Sketchup.register_extension(ext, true)
    file_loaded('variable_tools.rb:register')
  end
end
