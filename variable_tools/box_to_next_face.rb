# encoding: UTF-8
# -----------------------------------------------------------------------------
# Box To Next Face  (SketchUp 2019 / Ruby 2.5 compatible)
#
# For every independent object in the selection, creates a solid box that:
#
#   - BOTTOM : starts at the bottom of the selected geometry
#   - SIDES  : the footprint is the object's bounding box pushed outward by the
#              user-defined offset on every side
#   - TOP    : extends upward until it meets the first OTHER face; the top
#              plane is placed exactly at that face's lowest point inside the
#              footprint
#
# If no face is found above the object (nothing limits the box), the command
# is INVALID: a message is shown and nothing at all is created.
#
# Details
#   - "Up" is the object's own local vertical, so a tilted group extends along
#     its own tilt. The box follows the object's orientation (group axes, then
#     tightest plan rotation of the geometry inside), the same way as the
#     trapezoid and Box From Mark extensions.
#   - The selected geometry itself is ignored when looking for the limit, as
#     are boxes previously made by this extension. Hidden geometry and geometry
#     on hidden tags/layers is ignored too.
#   - A face counts as the limit when it touches the volume swept upward by
#     the footprint. Faces with holes are treated as solid (outer loop only).
#   - The original geometry is kept. One undo step removes the new boxes.
#
# Install : copy to  %APPDATA%\SketchUp\SketchUp 2019\SketchUp\Plugins\
#           (Mac: ~/Library/Application Support/SketchUp 2019/SketchUp/Plugins/)
# Run     : Extensions > Box To Next Face
#           (or in the Ruby Console:  BoxToNextFace.run )
# -----------------------------------------------------------------------------

require 'set'

module BoxToNextFace
  # Lets this file be re-pasted into the Ruby Console without "already initialized constant" warnings
  constants.each { |c| remove_const(c) }

  MENU_NAME = 'Box To Next Face'.freeze
  ATTR_DICT = 'BoxToNextFace'.freeze
  EPS       = 0.001 # inches, SketchUp's own geometric tolerance
  @last_offset = 100.mm

  def self.container?(e)
    e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
  end

  # ---------------------------------------------------------------------------
  # Split the selection into independent clusters (arrays of entities)
  # ---------------------------------------------------------------------------
  def self.clusters_from(selection)
    clusters = []
    loose    = []

    selection.each do |e|
      if container?(e)
        clusters << [e]
      elsif e.is_a?(Sketchup::Edge) || e.is_a?(Sketchup::Face)
        loose << e
      elsif e.respond_to?(:bounds)
        clusters << [e]
      end
    end

    parent = {}
    find = lambda do |v|
      parent[v] = v unless parent.key?(v)
      parent[v] = parent[parent[v]] while parent[v] != parent[parent[v]]
      parent[v]
    end
    union = lambda do |a, b|
      ra = find.call(a)
      rb = find.call(b)
      parent[ra] = rb unless ra == rb
    end

    loose.each do |e|
      vs = e.vertices
      find.call(vs[0])
      vs.each_cons(2) { |a, b| union.call(a, b) }
    end

    groups = {}
    loose.each do |e|
      root = find.call(e.vertices[0])
      (groups[root] ||= []) << e
    end
    clusters.concat(groups.values)

    clusters
  end

  # ---------------------------------------------------------------------------
  # Orientation helpers
  # ---------------------------------------------------------------------------
  def self.collect_points(e, tr, pts)
    if e.is_a?(Sketchup::Edge)
      pts << e.start.position.transform(tr)
      pts << e.end.position.transform(tr)
    elsif e.is_a?(Sketchup::Face)
      e.vertices.each { |v| pts << v.position.transform(tr) }
    elsif e.is_a?(Sketchup::Group)
      sub = tr * e.transformation
      e.entities.each { |c| collect_points(c, sub, pts) }
    elsif e.is_a?(Sketchup::ComponentInstance)
      sub = tr * e.transformation
      e.definition.entities.each { |c| collect_points(c, sub, pts) }
    elsif e.respond_to?(:bounds) && !e.bounds.empty?
      b = e.bounds
      (0..7).each { |i| pts << b.corner(i).transform(tr) }
    end
  end

  def self.convex_hull(points)
    pts = points.sort
    return pts if pts.size <= 2
    cross = lambda do |o, a, b|
      (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    end
    lower = []
    pts.each do |p|
      lower.pop while lower.size >= 2 && cross.call(lower[-2], lower[-1], p) <= 0
      lower << p
    end
    upper = []
    pts.reverse_each do |p|
      upper.pop while upper.size >= 2 && cross.call(upper[-2], upper[-1], p) <= 0
      upper << p
    end
    lower.pop
    upper.pop
    lower + upper
  end

  def self.plan_rotation(pts)
    hull = convex_hull(pts.map { |p| [p.x.to_f, p.y.to_f] }.uniq)
    return Geom::Transformation.new if hull.empty?

    area_at = lambda do |ang|
      c = Math.cos(ang)
      s = Math.sin(ang)
      minx = miny = Float::INFINITY
      maxx = maxy = -Float::INFINITY
      hull.each do |p|
        u =  p[0] * c + p[1] * s
        v = -p[0] * s + p[1] * c
        minx = u if u < minx
        maxx = u if u > maxx
        miny = v if v < miny
        maxy = v if v > maxy
      end
      (maxx - minx) * (maxy - miny)
    end

    best_ang  = 0.0
    best_area = area_at.call(0.0)

    if hull.size >= 2
      hull.each_with_index do |a, i|
        b = hull[(i + 1) % hull.size]
        ang = Math.atan2(b[1] - a[1], b[0] - a[0])
        area = area_at.call(ang)
        if area < best_area * (1.0 - 1e-6) - 1e-9
          best_area = area
          best_ang  = ang
        end
      end
    end

    c = Math.cos(best_ang)
    s = Math.sin(best_ang)
    Geom::Transformation.axes(
      Geom::Point3d.new(0, 0, 0),
      Geom::Vector3d.new(c, s, 0),
      Geom::Vector3d.new(-s, c, 0),
      Geom::Vector3d.new(0, 0, 1)
    )
  end

  def self.frame_from(tr)
    xa = tr.xaxis
    xa.normalize!
    za = xa.cross(tr.yaxis)
    za.normalize!
    ya = za.cross(xa)
    Geom::Transformation.axes(tr.origin, xa, ya, za)
  end

  # Returns [frame, bb]; bb is the bounding box in the frame's coordinates
  def self.oriented_box(cluster)
    pts = []
    cluster.each { |e| collect_points(e, Geom::Transformation.new, pts) }
    return nil if pts.empty?

    base = if cluster.size == 1 && container?(cluster[0])
             frame_from(cluster[0].transformation)
           else
             Geom::Transformation.new
           end

    base_inv = base.inverse
    local = pts.map { |p| p.transform(base_inv) }
    frame = base * plan_rotation(local)

    inv = frame.inverse
    bb = Geom::BoundingBox.new
    pts.each { |p| bb.add(p.transform(inv)) }
    [frame, bb]
  end

  # ---------------------------------------------------------------------------
  # Finding the limiting face
  # ---------------------------------------------------------------------------

  # All faces of the model (world coordinates, outer loop only), skipping the
  # selected entities, hidden things and boxes made by this extension.
  def self.collect_polys(entities, tr, skip_ids, polys)
    entities.each do |e|
      next if skip_ids.include?(e.entityID)
      next if e.respond_to?(:hidden?) && e.hidden?
      next if e.respond_to?(:layer) && e.layer && !e.layer.visible?

      if e.is_a?(Sketchup::Face)
        polys << e.outer_loop.vertices.map { |v| v.position.transform(tr) }
      elsif container?(e)
        next if e.get_attribute(ATTR_DICT, 'generated')
        ents = e.is_a?(Sketchup::Group) ? e.entities : e.definition.entities
        collect_polys(ents, tr * e.transformation, skip_ids, polys)
      end
    end
  end

  # Keep the part of polygon `poly` ([x,y,z] points) where coordinate `axis`
  # is >= value (keep_greater) or <= value (Sutherland-Hodgman, one plane)
  def self.clip(poly, axis, value, keep_greater)
    out = []
    poly.each_with_index do |cur, i|
      prev = poly[i - 1]
      cur_in  = keep_greater ? cur[axis]  >= value : cur[axis]  <= value
      prev_in = keep_greater ? prev[axis] >= value : prev[axis] <= value
      if cur_in != prev_in
        t = (value - prev[axis]) / (cur[axis] - prev[axis])
        out << [0, 1, 2].map { |k| prev[k] + t * (cur[k] - prev[k]) }
      end
      out << cur if cur_in
    end
    out
  end

  # Lowest z (frame coordinates) at which any polygon enters the volume swept
  # upward from the footprint [xmin,xmax] x [ymin,ymax], starting at z0.
  # Returns nil when nothing limits the box.
  def self.limit_z(polys, to_frame, xmin, xmax, ymin, ymax, z0)
    best = nil
    xl = xmin + EPS
    xh = xmax - EPS
    yl = ymin + EPS
    yh = ymax - EPS
    zl = z0 + EPS

    polys.each do |poly|
      next if poly.size < 3
      pts = poly.map do |p|
        q = p.transform(to_frame)
        [q.x.to_f, q.y.to_f, q.z.to_f]
      end

      # quick reject by the polygon's extents
      next if pts.all? { |p| p[0] <= xl } || pts.all? { |p| p[0] >= xh }
      next if pts.all? { |p| p[1] <= yl } || pts.all? { |p| p[1] >= yh }
      next if pts.all? { |p| p[2] <= zl }

      piece = clip(pts, 0, xl, true)
      piece = clip(piece, 0, xh, false) if piece.size >= 3
      piece = clip(piece, 1, yl, true)  if piece.size >= 3
      piece = clip(piece, 1, yh, false) if piece.size >= 3
      piece = clip(piece, 2, zl, true)  if piece.size >= 3
      next if piece.size < 3

      z = piece.map { |p| p[2] }.min
      best = z if best.nil? || z < best
    end

    best
  end

  # ---------------------------------------------------------------------------
  # Build a closed box group in the frame's local space, then place it
  # ---------------------------------------------------------------------------
  def self.build_box(context_entities, x0, x1, y0, y1, z0, z1, frame, name)
    c = [
      Geom::Point3d.new(x0, y0, z0), Geom::Point3d.new(x1, y0, z0),
      Geom::Point3d.new(x1, y1, z0), Geom::Point3d.new(x0, y1, z0),
      Geom::Point3d.new(x0, y0, z1), Geom::Point3d.new(x1, y0, z1),
      Geom::Point3d.new(x1, y1, z1), Geom::Point3d.new(x0, y1, z1)
    ]
    center = Geom::Point3d.new((x0 + x1) / 2.0, (y0 + y1) / 2.0, (z0 + z1) / 2.0)

    group = context_entities.add_group
    group.name = name
    ents = group.entities

    faces = [
      ents.add_face(c[0], c[1], c[2], c[3]),
      ents.add_face(c[4], c[5], c[6], c[7]),
      ents.add_face(c[0], c[1], c[5], c[4]),
      ents.add_face(c[1], c[2], c[6], c[5]),
      ents.add_face(c[2], c[3], c[7], c[6]),
      ents.add_face(c[3], c[0], c[4], c[7])
    ]
    faces.compact.each do |f|
      f.reverse! if f.normal.dot(center.vector_to(f.bounds.center)) < 0
    end

    group.transform!(frame)
    group
  end

  # ---------------------------------------------------------------------------
  # Main command
  # ---------------------------------------------------------------------------
  def self.run
    model = Sketchup.active_model
    sel   = model.selection

    if sel.empty?
      UI.messagebox('Please select at least one object first.')
      return
    end

    result = UI.inputbox(['Side offset from the geometry (>= 0)'],
                         [@last_offset], MENU_NAME)
    return unless result # cancelled

    offset = result[0].to_l
    if offset < 0
      UI.messagebox('The offset cannot be negative.')
      return
    end
    @last_offset = offset
    off = offset.to_f

    clusters = clusters_from(sel)

    # Faces of the whole model in world coordinates, minus the selection
    skip_ids = Set.new
    sel.each { |e| skip_ids << e.entityID }
    polys = []
    collect_polys(model.entities, Geom::Transformation.new, skip_ids, polys)

    edit_tr = model.edit_transform

    # Work out every box first. If any object has no limit, nothing is created.
    plans    = []
    no_limit = 0
    clusters.each do |cluster|
      box = oriented_box(cluster)
      next if box.nil?
      frame, bb = box

      xmin = bb.min.x.to_f - off
      xmax = bb.max.x.to_f + off
      ymin = bb.min.y.to_f - off
      ymax = bb.max.y.to_f + off
      z0   = bb.min.z.to_f

      to_frame = (edit_tr * frame).inverse
      z1 = limit_z(polys, to_frame, xmin, xmax, ymin, ymax, z0)

      if z1.nil? || z1 - z0 <= EPS
        no_limit += 1
      else
        plans << [frame, xmin, xmax, ymin, ymax, z0, z1]
      end
    end

    if plans.empty? && no_limit == 0
      UI.messagebox('Nothing to do: the selection contains no usable geometry.')
      return
    end

    if no_limit > 0
      UI.messagebox("Invalid command: no limiting face was found above #{no_limit} " \
                    "of the selected object(s).\nNothing was created.\n\n" \
                    'The upper face needs another face above the object to stop at.')
      return
    end

    new_groups = []
    model.start_operation('Box To Next Face', true)
    begin
      plans.each_with_index do |(frame, xmin, xmax, ymin, ymax, z0, z1), idx|
        g = build_box(model.active_entities, xmin, xmax, ymin, ymax, z0, z1,
                      frame, "Box To Next Face #{idx + 1}")
        g.set_attribute(ATTR_DICT, 'generated', true)
        g.set_attribute(ATTR_DICT, 'offset', off)
        g.set_attribute(ATTR_DICT, 'height', z1 - z0)
        new_groups << g
      end
      model.commit_operation
    rescue => e
      model.abort_operation
      UI.messagebox("Error: #{e.message}")
      return
    end

    sel.clear
    new_groups.each { |g| sel.add(g) }
  end

  # Register menu item once
  unless file_loaded?('box_to_next_face.rb:menu')
    UI.menu('Extensions').add_item(MENU_NAME) { BoxToNextFace.run }
    file_loaded('box_to_next_face.rb:menu')
  end
end
