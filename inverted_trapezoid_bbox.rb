# encoding: UTF-8
# -----------------------------------------------------------------------------
# Hollow Inverted Trapezoid BBox  (SketchUp 2019 / Ruby 2.5 compatible)
#
# For every independent object in the selection, builds a HOLLOW inverted
# trapezoid collar around that object's ORIENTED bounding box, as its own group.
#
#   - Input is a SLOPE value:   top offset = slope * box height
#         e.g. height 2, slope 1 -> offset 2
#              height 2, slope 2 -> offset 4
#   - Cavity = the source (oriented) bounding box -> no overlap with the source
#   - Inner walls : parallel to the box sides, coincident with them
#   - Outer walls : slope from the box lower edge out to the top
#   - Top         : flat ring between the box top and the offset top edge
#   - Bottom      : open (wall tapers to a knife edge at the box lower bound)
#
# ORIENTATION (always automatic, no option needed):
#   1. Starts from the selected group/component's own local axes, so a tilted
#      or rotated group gets a tilted / rotated collar.
#   2. Then refines the rotation about the local vertical axis to the tightest
#      rectangle around the actual geometry inside (including nested groups),
#      so rotated contents are followed too. If the contents are already
#      aligned with the group's axes, the axes are kept as they are.
#
# What counts as "independent":
#   - each selected Group / Component instance  -> its own trapezoid
#   - loose geometry (edges/faces) that is connected to each other is treated
#     as one object; unconnected loose pieces each get their own trapezoid
#
# Install : copy to  %APPDATA%\SketchUp\SketchUp 2019\SketchUp\Plugins\
#           (Mac: ~/Library/Application Support/SketchUp 2019/SketchUp/Plugins/)
# Run     : Extensions > Hollow Inverted Trapezoid BBox
#           (or in the Ruby Console:  InvertedTrapezoidBBox.run )
# -----------------------------------------------------------------------------

module InvertedTrapezoidBBox
  # Lets this file be re-pasted into the Ruby Console without "already initialized constant" warnings
  constants.each { |c| remove_const(c) }

  MENU_NAME = 'Hollow Inverted Trapezoid BBox'.freeze
  @last_slope = 1.0

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

    # Union-find over vertices so connected loose geometry stays together
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
  # Geometry helpers for orientation
  # ---------------------------------------------------------------------------

  # Collect geometry points of an entity (recursing into groups and
  # components) in the coordinates of the active context.
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

  # Rotation about Z (as a Transformation) giving the minimum-area rectangle
  # around pts in the XY plane. Angle 0 is the starting candidate, so geometry
  # that is already aligned keeps its axes.
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

  # Orthonormal, right-handed frame built from an instance transformation
  # (removes scale so offsets stay true to real-world size)
  def self.frame_from(tr)
    xa = tr.xaxis
    xa.normalize!
    za = xa.cross(tr.yaxis)
    za.normalize!
    ya = za.cross(xa)
    Geom::Transformation.axes(tr.origin, xa, ya, za)
  end

  # Returns [frame, bb] where bb is the bounding box in the frame's coordinates
  def self.oriented_box(cluster)
    pts = []
    cluster.each { |e| collect_points(e, Geom::Transformation.new, pts) }
    return nil if pts.empty?

    # 1) start from the group's own axes (follows tilt of the group)
    base = if cluster.size == 1 && container?(cluster[0])
             frame_from(cluster[0].transformation)
           else
             Geom::Transformation.new
           end

    # 2) refine rotation about the local vertical to the geometry inside
    base_inv = base.inverse
    local = pts.map { |p| p.transform(base_inv) }
    frame = base * plan_rotation(local)

    inv = frame.inverse
    bb = Geom::BoundingBox.new
    pts.each { |p| bb.add(p.transform(inv)) }
    [frame, bb]
  end

  # ---------------------------------------------------------------------------
  # Build one hollow inverted trapezoid group around bb (given in frame coords),
  # then place it with `frame`
  # ---------------------------------------------------------------------------
  def self.build_collar(context_entities, bb, offset, name, frame)
    min_pt = bb.min
    max_pt = bb.max
    z0 = min_pt.z
    z1 = max_pt.z

    # Bottom rectangle = source box lower bound
    b = [
      Geom::Point3d.new(min_pt.x, min_pt.y, z0),
      Geom::Point3d.new(max_pt.x, min_pt.y, z0),
      Geom::Point3d.new(max_pt.x, max_pt.y, z0),
      Geom::Point3d.new(min_pt.x, max_pt.y, z0)
    ]
    # Inner top rectangle = source box top (cavity top edge)
    ti = [
      Geom::Point3d.new(min_pt.x, min_pt.y, z1),
      Geom::Point3d.new(max_pt.x, min_pt.y, z1),
      Geom::Point3d.new(max_pt.x, max_pt.y, z1),
      Geom::Point3d.new(min_pt.x, max_pt.y, z1)
    ]
    # Outer top rectangle = box top pushed outward by offset
    to = [
      Geom::Point3d.new(min_pt.x - offset, min_pt.y - offset, z1),
      Geom::Point3d.new(max_pt.x + offset, min_pt.y - offset, z1),
      Geom::Point3d.new(max_pt.x + offset, max_pt.y + offset, z1),
      Geom::Point3d.new(min_pt.x - offset, max_pt.y + offset, z1)
    ]

    center = Geom::Point3d.new(
      (min_pt.x + max_pt.x) / 2.0,
      (min_pt.y + max_pt.y) / 2.0,
      (z0 + z1) / 2.0
    )

    group = context_entities.add_group
    group.name = name
    ents = group.entities

    outer_faces = []  # normal points away from center
    inner_faces = []  # normal points toward center (into the cavity)
    top_faces   = []  # normal points up (local +Z)

    4.times do |i|
      j = (i + 1) % 4
      outer_faces << ents.add_face(b[i], b[j], to[j], to[i])
      inner_faces << ents.add_face(b[i], b[j], ti[j], ti[i])
      top_faces   << ents.add_face(to[i], to[j], ti[j], ti[i])
    end

    outer_faces.compact.each do |f|
      f.reverse! if f.normal.dot(center.vector_to(f.bounds.center)) < 0
    end
    inner_faces.compact.each do |f|
      f.reverse! if f.normal.dot(center.vector_to(f.bounds.center)) > 0
    end
    top_faces.compact.each { |f| f.reverse! if f.normal.z < 0 }

    # Move the collar from its local frame into place (rotates / tilts it)
    group.transform!(frame)

    group
  end

  # ---------------------------------------------------------------------------
  # Main command
  # ---------------------------------------------------------------------------
  def self.run(register_in_database = false)
    model = Sketchup.active_model
    sel   = model.selection

    if sel.empty?
      UI.messagebox('Please select at least one object first.')
      return
    end

    prompts  = ['Slope (top offset = slope x height; must be > 0)']
    defaults = [@last_slope]
    result   = UI.inputbox(prompts, defaults, register_in_database ? 'Generate Berm' : MENU_NAME)
    return unless result # cancelled

    slope = result[0].to_f
    if slope <= 0.0
      UI.messagebox('The slope must be greater than 0 for the box to be hollow without overlapping the source.')
      return
    end
    @last_slope = slope

    clusters   = clusters_from(sel)
    new_groups = []
    skipped    = 0

    model.start_operation('Create Hollow Inverted Trapezoids', true)
    begin
      clusters.each_with_index do |cluster, idx|
        box = oriented_box(cluster)
        if box.nil?
          skipped += 1
          next
        end
        frame, bb = box

        height = bb.max.z - bb.min.z
        if height < 0.001 || bb.width < 0.001 || bb.height < 0.001
          skipped += 1
          next
        end

        offset = height * slope
        name = "Hollow Inverted Trapezoid #{idx + 1}"
        group = build_collar(model.active_entities, bb, offset, name, frame)
        if register_in_database
          group.set_attribute('VariableDB', 'structural_excavation', true)
          group.set_attribute('VariableDB', 'structural_excavation_seq', format('%013d-%06d', (Time.now.to_f * 1000).to_i, idx))
        end
        new_groups << group
      end
      model.commit_operation
    rescue => e
      model.abort_operation
      UI.messagebox("Error: #{e.message}")
      return nil
    end

    sel.clear
    new_groups.each { |g| sel.add(g) }

    if skipped > 0
      UI.messagebox("#{new_groups.size} trapezoid(s) created.\n" \
                    "#{skipped} object(s) skipped (flat in at least one direction or empty).")
    end
    new_groups
  end

end
