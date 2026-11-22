# encoding: UTF-8
# -----------------------------------------------------------------------------
# Hollow Solid Intersection  (SketchUp 2019 / Ruby 2.5 compatible)
#
# Select two or more SOLID groups / components and run the command. You choose
# ONE of them as the solid to REDUCE. Every other selected solid passes through
# it and cuts a void (a pass-through hole or pocket) where they overlap, while
# those other solids keep their full volume.
#
#   Before:   [ big solid ]  with   (cutter A)  (cutter B) passing through it
#   After:    [ big solid with voids shaped like A and B ]   (A and B unchanged)
#
#   - Input: "Solid to reduce" dropdown listing the selected solids (number,
#     name and size). Default = the solid with the largest bounding box.
#   - Only the chosen solid is modified. All the others are left exactly as
#     they were and are not trimmed in any way.
#   - Cutters that do not touch the chosen solid have no effect.
#   - If the chosen solid would be consumed completely (it lies entirely inside
#     the cutters), nothing is changed and you are told.
#   - Name, tag (layer), material and attributes (for example the "BoxFromMark"
#     tag used by the Variable Database Quantity column) are carried over to the
#     reduced result.
#   - Selected objects that are not solid (not manifold) are ignored and listed.
#   - One undo step. If anything fails, nothing is changed.
#
# Requires SketchUp's Solid Tools (SketchUp Pro). The script checks this by
# running a tiny test on two throw-away boxes (rolled back immediately), which
# also tells it in which direction Group#subtract works on your version.
#
# Install : copy to  %APPDATA%\SketchUp\SketchUp 2019\SketchUp\Plugins\
#           (Mac: ~/Library/Application Support/SketchUp 2019/SketchUp/Plugins/)
# Run     : Extensions > Hollow Solid Intersection
#           (or in the Ruby Console:  HollowSolidIntersection.run )
# -----------------------------------------------------------------------------

module HollowSolidIntersection
  # Lets this file be re-pasted into the Ruby Console without "already initialized constant" warnings
  constants.each { |c| remove_const(c) }

  MENU_NAME  = 'Hollow Solid Intersection'.freeze
  MIN_VOLUME = 1e-4 # cubic inches; smaller overlaps are treated as "no overlap"

  # nil = not detected yet, true/false = result of the probe
  # true  : receiver.subtract(arg) leaves (arg - receiver)
  # false : receiver.subtract(arg) leaves (receiver - arg)
  @receiver_is_cutter = nil

  def self.container?(e)
    e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
  end

  def self.solid?(e)
    container?(e) && e.respond_to?(:manifold?) && e.manifold?
  end

  # Copy of a group/component, placed in the same context at the same spot
  def self.dup_container(e)
    return e.copy if e.respond_to?(:copy)
    e.parent.entities.add_instance(e.definition, e.transformation)
  end

  # Text shown in the dropdown: "1. Name (W x D x H)"
  def self.label_for(e, idx)
    name = e.name.to_s
    name = e.definition.name.to_s if name.empty?
    name = 'Unnamed' if name.empty?
    b = e.bounds
    dims = [b.width, b.height, b.depth].map { |v| v.to_l.to_s }.join(' x ')
    "#{idx + 1}. #{name.tr('|', '/')} (#{dims})"
  end

  def self.box_volume(e)
    b = e.bounds
    b.width.to_f * b.height.to_f * b.depth.to_f
  end

  # ---------------------------------------------------------------------------
  # A closed box group (used only by the probe)
  # ---------------------------------------------------------------------------
  def self.make_box(ents, x0, y0, z0, x1, y1, z1)
    c = [
      Geom::Point3d.new(x0, y0, z0), Geom::Point3d.new(x1, y0, z0),
      Geom::Point3d.new(x1, y1, z0), Geom::Point3d.new(x0, y1, z0),
      Geom::Point3d.new(x0, y0, z1), Geom::Point3d.new(x1, y0, z1),
      Geom::Point3d.new(x1, y1, z1), Geom::Point3d.new(x0, y1, z1)
    ]
    center = Geom::Point3d.new((x0 + x1) / 2.0, (y0 + y1) / 2.0, (z0 + z1) / 2.0)
    group = ents.add_group
    e = group.entities
    faces = [
      e.add_face(c[0], c[1], c[2], c[3]), e.add_face(c[4], c[5], c[6], c[7]),
      e.add_face(c[0], c[1], c[5], c[4]), e.add_face(c[1], c[2], c[6], c[5]),
      e.add_face(c[2], c[3], c[7], c[6]), e.add_face(c[3], c[0], c[4], c[7])
    ]
    faces.compact.each do |f|
      f.reverse! if f.normal.dot(center.vector_to(f.bounds.center)) < 0
    end
    group
  end

  # ---------------------------------------------------------------------------
  # Find out which way Group#subtract works (and whether Solid Tools respond).
  # Runs once per session and is always rolled back.
  # ---------------------------------------------------------------------------
  def self.detect_subtract_order(model)
    return @receiver_is_cutter unless @receiver_is_cutter.nil?

    model.start_operation('Probe Solid Tools', true)
    begin
      ents = model.active_entities
      a = make_box(ents, 0, 0, 0, 10, 10, 10)  # volume 1000
      b = make_box(ents, 5, 0, 0, 15, 10, 4)   # volume 400, overlap 200
      va = a.volume
      r = a.subtract(b)
      if r && r.valid? && va > 0
        ratio = r.volume / va
        if (ratio - 0.2).abs < 0.05      # b - a  -> receiver is the cutter
          @receiver_is_cutter = true
        elsif (ratio - 0.8).abs < 0.05   # a - b  -> receiver is the base
          @receiver_is_cutter = false
        end
      end
    rescue => e
      puts "Hollow Solid Intersection probe failed: #{e.class}: #{e.message}"
    ensure
      model.abort_operation
    end
    @receiver_is_cutter
  end

  # base minus cutter, whichever way the API wants it. Consumes both groups.
  def self.subtract(base, cutter)
    @receiver_is_cutter ? cutter.subtract(base) : base.subtract(cutter)
  end

  def self.copy_properties(from, to)
    to.name = from.name if from.respond_to?(:name)
    to.layer = from.layer
    to.material = from.material
    dicts = from.attribute_dictionaries
    return unless dicts
    dicts.each do |d|
      d.each_pair { |k, v| to.set_attribute(d.name, k, v) }
    end
  end

  # ---------------------------------------------------------------------------
  # Main command
  # ---------------------------------------------------------------------------
  def self.run
    model = Sketchup.active_model
    sel   = model.selection

    unless Sketchup::Group.method_defined?(:subtract) && Sketchup::Group.method_defined?(:intersect)
      UI.messagebox('This SketchUp version has no Solid Tools API.')
      return
    end

    containers = sel.select { |e| container?(e) }
    solids     = containers.select { |e| solid?(e) }
    ignored    = containers - solids

    if solids.size < 2
      msg = 'Select at least two solid groups/components: the one to reduce and the ones that cut through it.'
      unless ignored.empty?
        names = ignored.map { |e| e.name.to_s.empty? ? '(unnamed)' : e.name }.join(', ')
        msg += "\n\nNot solid (ignored): #{names}"
      end
      UI.messagebox(msg)
      return
    end

    # --- Input: which solid gets reduced ---------------------------------------
    labels  = solids.each_with_index.map { |e, i| label_for(e, i) }
    largest = solids.each_with_index.max_by { |e, _| box_volume(e) }[1]
    result  = UI.inputbox(['Solid to reduce (the others cut voids in it)'],
                          [labels[largest]], [labels.join('|')], MENU_NAME)
    return unless result # cancelled

    hidx = labels.index(result[0])
    if hidx.nil?
      UI.messagebox('Please choose one of the listed solids.')
      return
    end
    host    = solids[hidx]
    cutters = solids.each_with_index.reject { |_, i| i == hidx }.map(&:first)

    if detect_subtract_order(model).nil?
      UI.messagebox("Solid Tools did not respond.\n" \
                    'They need SketchUp Pro (2019 or newer Pro features) and a working licence.')
      return
    end

    reduced   = nil
    used      = 0 # cutters that actually overlapped the host
    host_vol  = host.volume

    model.start_operation('Hollow Solid Intersection', true)
    begin
      current = dup_container(host) # working copy that is reduced step by step

      cutters.each do |c|
        # the part of this cutter that lies inside the host
        ch = dup_container(host)
        cc = dup_container(c)
        inter = ch.intersect(cc)

        if inter && inter.valid? && inter.volume > MIN_VOLUME
          if inter.volume >= host_vol * (1.0 - 1e-6)
            raise 'The solid to reduce lies completely inside one of the other solids.'
          end
          next_current = subtract(current, inter)
          unless next_current && next_current.valid?
            raise 'Subtract failed. The result may be empty, or the solids are not clean manifold solids.'
          end
          current = next_current
          used += 1
        else
          inter.erase! if inter && inter.valid?
          [ch, cc].each { |g| g.erase! if g.valid? }
        end
      end

      if used.zero?
        model.abort_operation
        UI.messagebox('None of the other selected solids overlaps the solid to reduce.')
        return
      end

      copy_properties(host, current)
      host.erase!
      reduced = current

      model.commit_operation
    rescue => e
      model.abort_operation
      UI.messagebox("Hollowing failed: #{e.message}\nNothing was changed.")
      return
    end

    sel.clear
    sel.add(reduced) if reduced && reduced.valid?
    cutters.each { |c| sel.add(c) if c.valid? }

    msg = "Solid reduced by #{used} overlapping solid(s). The other solids keep their full volume."
    unless ignored.empty?
      msg += "\n#{ignored.size} selected object(s) were not solid and were ignored."
    end
    Sketchup.status_text = msg.tr("\n", ' ')
    UI.messagebox(msg) unless ignored.empty?
  end

  # Register menu item once
  unless file_loaded?('hollow_solid_intersection.rb:menu')
    UI.menu('Extensions').add_item(MENU_NAME) { HollowSolidIntersection.run }
    file_loaded('hollow_solid_intersection.rb:menu')
  end
end
