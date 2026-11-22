# encoding: UTF-8
# -----------------------------------------------------------------------------
# Excavation From Footing  (SketchUp 2019 / Ruby 2.5 compatible)
#
# Select a FOOTING (or several) and run the command. For each footing the
# plugin builds the taller box that represents the EXCAVATION needed to reach it:
#
#   - BOTTOM : the footing's bottom level (lower it with "Extra depth below")
#   - SIDES  : the footing's bounding box pushed outward by the "Side offset"
#              (working space around the footing)
#   - TOP    : extends upward until it reaches the first OTHER face above the
#              footing (slab, ground surface, ...). The top plane sits exactly at
#              the lowest point where that face meets the excavation footprint.
#
# If no face is found above the footing (nothing limits the excavation), the
# command is INVALID: a message is shown and nothing at all is created.
#
# Inputs
#   Side offset                 : space around the footing, 0 or more
#   Extra depth below footing   : digging below the footing bottom, 0 or more
#
# Details
#   - "Up" is the footing's own local vertical, so a tilted footing is excavated
#     along its own tilt. The box follows the footing's orientation (group
#     axes, then the tightest plan rotation of the geometry inside).
#   - The selected footing itself, hidden geometry, hidden tags, and boxes made
#     by this tool or by Box To Next Face are ignored when looking for the limit.
#   - A face counts as the limit when it touches the volume swept upward by the
#     excavation footprint. Faces with holes are treated as solid.
#   - The footing is kept. Each excavation is a closed group named
#     "Excavation <n>" carrying its dimensions and volume as attributes.
#     The total volume is reported when the command finishes.
#   - One undo step removes all the new excavations.
#
# Install : copy to  %APPDATA%\SketchUp\SketchUp 2019\SketchUp\Plugins\
#           (Mac: ~/Library/Application Support/SketchUp 2019/SketchUp/Plugins/)
# Run     : Extensions > Excavation From Footing
#           (or in the Ruby Console:  ExcavationFromFooting.run )
# -----------------------------------------------------------------------------

require 'set'

module ExcavationFromFooting
  # Lets this file be re-pasted into the Ruby Console without "already initialized constant" warnings
  constants.each { |c| remove_const(c) }

  MENU_NAME = 'Excavation From Footing'.freeze
  ATTR_DICT = 'ExcavationFromFooting'.freeze
  # boxes made by these tools are never treated as a limiting face
  GENERATED_DICTS = %w[ExcavationFromFooting BoxToNextFace].freeze
  EPS       = 0.001 # inches, SketchUp's own geometric tolerance
  @last_side  = 300.mm # working space around the footing
  @last_depth = 0.mm   # extra digging below the footing bottom

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
        next if GENERATED_DICTS.any? { |d| e.get_attribute(d, 'generated') }
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


  # Collect the selected footing's actual surface triangles in excavation-frame
  # coordinates. Unlike the bounding box, these preserve changes in bottom level.
  def self.surface_triangles(entity, transform, out)
    if entity.is_a?(Sketchup::Face)
      mesh = entity.mesh
      mesh.polygons.each do |polygon|
        points = polygon.map { |index| mesh.point_at(index.abs).transform(transform) }
        next unless points.length >= 3
        (1...(points.length - 1)).each do |i|
          tri = [points[0], points[i], points[i + 1]]
          a, b, c = tri
          area2 = (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)
          out << tri if area2.abs > EPS * EPS
        end
      end
    elsif container?(entity)
      sub = transform * entity.transformation
      entities = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
      entities.each { |child| surface_triangles(child, sub, out) }
    end
  end

  # The first surface encountered travelling upward from below the footing.
  # A vertical ray through a stepped footing therefore finds each step's
  # underside rather than the overall bounding-box minimum.
  def self.bottom_at(triangles, x, y)
    best = nil
    triangles.each do |tri|
      a, b, c = tri
      den = (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
      next if den.abs < EPS * EPS
      u = ((b.y - c.y) * (x - c.x) + (c.x - b.x) * (y - c.y)) / den
      v = ((c.y - a.y) * (x - c.x) + (a.x - c.x) * (y - c.y)) / den
      w = 1.0 - u - v
      next if u < -1e-6 || v < -1e-6 || w < -1e-6
      z = u * a.z + v * b.z + w * c.z
      best = z if best.nil? || z < best
    end
    best
  end

  def self.add_outward_face(entities, points, outward)
    face = entities.add_face(points)
    raise 'Unable to create excavation face' unless face
    face.reverse! if face.normal.dot(outward) < 0
    face
  end

  # Build a stepped excavation solid from rectangular XY cells. The cell
  # boundaries are taken from the source geometry's vertices, so horizontal
  # steps are preserved without depending on SketchUp Pro solid operations.
  def self.build_shaped_excavation(context, frame, xs, ys, bottoms, top, name)
    group = context.add_group
    group.name = name
    ents = group.entities
    nx = xs.length - 1
    ny = ys.length - 1
    point = lambda { |x, y, z| Geom::Point3d.new(x, y, z) }
    add_outward_face(ents, [point.call(xs[0], ys[0], top),
      point.call(xs[-1], ys[0], top), point.call(xs[-1], ys[-1], top),
      point.call(xs[0], ys[-1], top)], Geom::Vector3d.new(0, 0, 1))
    nx.times do |i|
      ny.times do |j|
        x0, x1 = xs[i], xs[i + 1]
        y0, y1 = ys[j], ys[j + 1]
        z = bottoms[i][j]
        add_outward_face(ents, [point.call(x0,y0,z), point.call(x0,y1,z),
          point.call(x1,y1,z), point.call(x1,y0,z)], Geom::Vector3d.new(0,0,-1))
        # Only expose the portion of a wall below the adjacent cell's bottom.
        [[-1,0], [1,0], [0,-1], [0,1]].each do |di,dj|
          ii, jj = i + di, j + dj
          neighbor = if ii < 0 || ii >= nx || jj < 0 || jj >= ny
                       top
                     else
                       bottoms[ii][jj]
                     end
          next unless neighbor > z + EPS
          if di == -1
            corners = [[x0,y0],[x0,y1]]; normal = Geom::Vector3d.new(-1,0,0)
          elsif di == 1
            corners = [[x1,y1],[x1,y0]]; normal = Geom::Vector3d.new(1,0,0)
          elsif dj == -1
            corners = [[x1,y0],[x0,y0]]; normal = Geom::Vector3d.new(0,-1,0)
          else
            corners = [[x0,y1],[x1,y1]]; normal = Geom::Vector3d.new(0,1,0)
          end
          a, b = corners
          add_outward_face(ents, [point.call(a[0],a[1],z),
            point.call(b[0],b[1],z), point.call(b[0],b[1],neighbor),
            point.call(a[0],a[1],neighbor)], normal)
        end
      end
    end
    cleanup_partition_edges(ents)
    group.transform!(frame)
    group
  end

  # Remove only redundant coplanar partition edges left by the cell grid.
  # Edges at a genuine elevation step are preserved. SketchUp merges the
  # adjacent coplanar faces when their common edge is erased.
  def self.cleanup_partition_edges(entities)
    loop do
      candidates = entities.grep(Sketchup::Edge).select do |edge|
        next false unless edge.valid? && edge.faces.length == 2
        a, b = edge.faces
        next false unless a.valid? && b.valid?
        next false unless a.normal.parallel?(b.normal)
        # Parallel planes can be offset: require coplanarity as well.
        a.plane && b.vertices.all? { |v| v.position.distance_to_plane(a.plane).abs < EPS }
      end
      break if candidates.empty?
      removed = 0
      candidates.each do |edge|
        next unless edge.valid? && edge.faces.length == 2
        a, b = edge.faces
        next unless a.valid? && b.valid? && a.normal.parallel?(b.normal)
        next unless b.vertices.all? { |v| v.position.distance_to_plane(a.plane).abs < EPS }
        edge.erase!
        removed += 1
      end
      break if removed == 0
    end
  end

  def self.shaped_plan(cluster, frame, bb, side, depth, top)
    inverse = frame.inverse
    triangles = []
    cluster.each { |e| surface_triangles(e, inverse, triangles) }
    raise 'Selected footing has no usable faces' if triangles.empty?
    # Partition at source vertices. For a conventional orthogonal stepped
    # footing this exactly follows the underside at each elevation.
    x0, x1 = bb.min.x.to_f - side, bb.max.x.to_f + side
    y0, y1 = bb.min.y.to_f - side, bb.max.y.to_f + side
    xs = ([x0, x1] + triangles.flatten.map { |p| p.x.to_f }).select { |x| x >= x0 && x <= x1 }.sort.uniq
    ys = ([y0, y1] + triangles.flatten.map { |p| p.y.to_f }).select { |y| y >= y0 && y <= y1 }.sort.uniq
    xs = xs.each_with_index.select { |v,i| i == 0 || v - xs[i-1] > EPS }.map(&:first)
    ys = ys.each_with_index.select { |v,i| i == 0 || v - ys[i-1] > EPS }.map(&:first)
    raise 'Footing is too complex for stepped excavation (over 2500 cells)' if (xs.length - 1) * (ys.length - 1) > 2500
    bottoms = Array.new(xs.length - 1) { Array.new(ys.length - 1) }
    volume = 0.0
    (xs.length - 1).times do |i|
      (ys.length - 1).times do |j|
        x = (xs[i] + xs[i+1]) / 2.0
        y = (ys[j] + ys[j+1]) / 2.0
        # Carry the nearest edge's underside elevation into working-space margins.
        cx = [[x, bb.min.x.to_f + EPS].max, bb.max.x.to_f - EPS].min
        cy = [[y, bb.min.y.to_f + EPS].max, bb.max.y.to_f - EPS].min
        bottom = bottom_at(triangles, cx, cy) || bb.min.z.to_f
        bottom -= depth
        raise 'Excavation top intersects footing bottom' unless top > bottom + EPS
        bottoms[i][j] = bottom
        volume += (xs[i+1] - xs[i]) * (ys[j+1] - ys[j]) * (top - bottom)
      end
    end
    [xs, ys, bottoms, volume]
  end

  # ---------------------------------------------------------------------------
  # Main command
  # ---------------------------------------------------------------------------
  def self.run(register_in_database = false)
    model = Sketchup.active_model
    sel   = model.selection

    if sel.empty?
      UI.messagebox('Please select the footing first.')
      return
    end

    prompts = ['Side offset (working space around the footing, >= 0)',
               'Extra depth below the footing bottom (>= 0)']
    result = UI.inputbox(prompts, [@last_side, @last_depth], MENU_NAME)
    return unless result # cancelled

    side  = result[0].to_l
    depth = result[1].to_l
    if side < 0 || depth < 0
      UI.messagebox('The offsets cannot be negative.')
      return
    end
    @last_side  = side
    @last_depth = depth
    s = side.to_f
    d = depth.to_f

    clusters = clusters_from(sel)

    # Faces of the whole model in world coordinates, minus the selection
    skip_ids = Set.new
    sel.each { |e| skip_ids << e.entityID }
    polys = []
    collect_polys(model.entities, Geom::Transformation.new, skip_ids, polys)

    edit_tr = model.edit_transform

    # Work out every excavation first. If any footing has no limit above it,
    # nothing is created.
    plans    = []
    no_limit = 0
    clusters.each do |cluster|
      box = oriented_box(cluster)
      next if box.nil?
      frame, bb = box

      xmin = bb.min.x.to_f - s
      xmax = bb.max.x.to_f + s
      ymin = bb.min.y.to_f - s
      ymax = bb.max.y.to_f + s
      z0   = bb.min.z.to_f # footing bottom

      to_frame = (edit_tr * frame).inverse
      z1 = limit_z(polys, to_frame, xmin, xmax, ymin, ymax, z0)

      if z1.nil? || z1 - z0 <= EPS
        no_limit += 1
      else
        plans << [cluster, frame, bb, z1]
      end
    end

    if plans.empty? && no_limit == 0
      UI.messagebox('Nothing to do: the selection contains no usable geometry.')
      return
    end

    if no_limit > 0
      UI.messagebox("Invalid command: no face was found above #{no_limit} " \
                    "of the selected footing(s) to stop the excavation.\n" \
                    "Nothing was created.\n\n" \
                    'The top of the excavation needs another face above the footing ' \
                    '(for example a slab or the ground surface).')
      return
    end

    new_groups = []
    total_in3  = 0.0
    model.start_operation('Excavation From Footing', true)
    begin
      plans.each_with_index do |(cluster, frame, bb, z1), idx|
        xs, ys, bottoms, vol = shaped_plan(cluster, frame, bb, s, d, z1)
        g = build_shaped_excavation(model.active_entities, frame, xs, ys,
                                    bottoms, z1, "Excavation #{idx + 1}")
        total_in3 += vol
        g.set_attribute(ATTR_DICT, 'generated', true)
        if register_in_database
          g.set_attribute('VariableDB', 'structural_excavation', true)
          g.set_attribute('VariableDB', 'structural_excavation_seq', format('%013d-%06d', (Time.now.to_f * 1000).to_i, idx))
        end
        g.set_attribute(ATTR_DICT, 'side_offset', s)
        g.set_attribute(ATTR_DICT, 'extra_depth', d)
        g.set_attribute(ATTR_DICT, 'height', z1 - bottoms.flatten.min)
        g.set_attribute(ATTR_DICT, 'volume_m3', vol * 1.6387064e-5)
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

    m3  = total_in3 * 1.6387064e-5
    ft3 = total_in3 / 1728.0
    msg = format("%d excavation(s) created.\nTotal volume: %.3f m\u00B3  (%.1f ft\u00B3)",
                 new_groups.size, m3, ft3)
    Sketchup.status_text = msg.tr("\n", ' ')
    UI.messagebox(msg)
    new_groups
  end

  # Register menu item once
  if false && !file_loaded?('excavation_from_footing.rb:menu')
    UI.menu('Extensions').add_item(MENU_NAME) { ExcavationFromFooting.run }
    file_loaded('excavation_from_footing.rb:menu')
  end
end
