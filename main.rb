# encoding: UTF-8
# Loads every tool. variable_database must come first (the others read from it).
dir = File.dirname(__FILE__)
%w[
  variable_database
  box_from_mark
  place_box_from_mark
  box_to_next_face
  excavation_from_footing
  hollow_solid_intersection
  inverted_trapezoid_bbox
].each { |name| require File.join(dir, name) }
