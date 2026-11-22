# encoding: UTF-8
# -----------------------------------------------------------------------------
# Variable Database  (SketchUp 2019 / Ruby 2.5 compatible)
#
# An editable table stored INSIDE the .skp file (model attribute dictionary
# "VariableDB"), so the data travels with the model and is saved with it.
#
# TWO SHEETS (tabs at the bottom of the window, like Excel)
#
#   Footing Schedule   - the mark database
#       Mark | Width | Length | Thickness | Shape | Side Forms | Soffit Forms | Volume | Quantity
#       Output columns (read-only, calculated from the mark's component):
#       - Side Forms   : total area of the faces parallel to the global Z axis
#                        (vertical faces) of ONE instance.
#       - Soffit Forms : total area of the bottom faces (horizontal faces looking
#                        down) of ONE instance.
#       - Volume       : volume of ONE instance (shown as - when the component is
#                        not a closed solid).
#                        Areas / volumes are shown in m2 / m3 for metric models and
#                        ft2 / ft3 for imperial models. They follow the table: change a
#                        dimension and they are recalculated.
#       - Quantity     : how many components of that mark exist in the model.
#
#   Footing Tabulation - one row for EVERY individual component in the model
#       Component | Mark | <your input columns> | TOC
#       - Component : name of that one component (its own name, or Mark-01,
#                     Mark-02, ... when it has none)
#       - Mark      : which mark it is
#       - Input columns : variables stored on that specific component. Zone and
#                     Package are there by default.
#                     "+ Column" adds a new column; double-click a column name to
#                     rename it; the x in the header deletes the column (and the
#                     values it holds). Renaming keeps the values.
#       - Several rows at once: select rows (Ctrl-click adds, Shift-click selects
#                     a range) or select the components in the SketchUp model
#                     (the matching rows light up), then type a value in an input
#                     cell of ANY selected row: it is written to all of them.
#       - TOC       : INPUT and OUTPUT. Top of concrete = the global Z elevation
#                     of the highest point of the component's real geometry (not
#                     the bounding box of a group), whatever group / component it
#                     is nested in. It updates by itself when you move components
#                     by hand. Type an elevation (several selected rows at once
#                     works too) and each component moves straight up or down so
#                     its top sits exactly there.
#       - COLOR BY: the "Color by" list above the table picks any column
#         (Component, Mark, your input columns, TOC). Every distinct value gets
#         its own colour, all components sharing a value share it, and the
#         components are painted in the model with those colours. A legend shows
#         each value with its count (click a chip to select those components);
#         a swatch in each row shows the colour. Components with an empty value
#         are painted grey. Colours follow edits (change a Zone and the
#         component changes colour). "Clear colors" (or "None") restores the
#         original materials. Colours are applied to the component instances,
#         so they show in any style that displays materials (not Monochrome).
#       - GRID X / GRID Y (outputs): the labels of the gridlines that cut through
#         the component. Grid X = gridlines at an X inside the component's X
#         extent, Grid Y = gridlines at a Y inside its Y extent (z is ignored, so
#         gridlines may sit at any elevation; a component spanning two gridlines
#         lists both, e.g. "B, C"; empty = no gridline). Gridlines are lines in
#         the model (edges or guide lines): a line parallel to the Y axis is a
#         Grid X line, one parallel to the X axis is a Grid Y line.
#         LABELLING: select the gridlines in the model, click "Label Grid", and
#         type the labels in order of increasing X (and Y): e.g.  A, B, C, D
#         for the X lines and  1, 2, 3  for the Y lines. Leave a field empty to
#         clear the labels. The label is stored on the line itself.
#         MANUAL ENTRY: where no gridline cuts through a component, its Grid X /
#         Grid Y cell is an input: type the value by hand (it is stored on the
#         component, selected rows at once works too). Where a gridline does cut
#         through, the cell shows the gridline's label and is read-only.
#       - COLUMN FILTERS: a drop-down above every column lists that column's
#         distinct values (and "(blank)"). Choosing one hides the rows with any
#         other value; filters on several columns combine. "All" shows the column
#         again. Rows are only hidden in the sheet (nothing changes in the
#         model); Export CSV still writes every row.
#       - Click a row to SELECT that component in the model (double-click also
#         zooms to it). Components inside groups / other components are reached
#         by opening that context.
#       - Values travel with the component (copies keep them). The column list is
#         saved in the model.
#       - "Refresh" re-reads the model; it also refreshes when the window
#         regains focus. "Export CSV" writes this sheet.
#
#   Bulk Excavation    - a database of imported geometries
#       Instance | Volume | Top Elevation | Bot Elevation | <your input columns>
#       - Rows come from "Import Selection" on this sheet only: the selected
#         geometry (one group / component, or several objects / loose faces
#         wrapped in one group) becomes ONE tracked instance in the model, in
#         place. You give it a unique name (the Instance column; edit the cell to
#         rename it). The x on a row only removes it from the sheet.
#       - Volume : OUTPUT. Volume of that instance (shown as - if the geometry is
#                  not a closed solid).
#       - Top Elevation / Bot Elevation : INPUT and OUTPUT. Global Z of the
#                  highest / lowest point of the real geometry. Typing a value
#                  stretches the instance vertically so that face lands on the
#                  new elevation while the opposite face stays put (several
#                  selected rows at once works too). They follow manual moves.
#       - "+ Column" adds input columns (rename by double-click, x deletes), and
#         "Color by" paints the instances by any column, exactly like the
#         Footing Tabulation sheet. Rows can be selected / highlighted the same way.
#       - Column filters work as on the Footing Tabulation sheet (drop-down above
#         each column hides the rows with other values).
#
#   Miscellaneous      - an exact copy of Bulk Excavation (same columns, same
#       functions: Import Selection, Volume, editable Top / Bot Elevation, added
#       columns, Color by, column filters) for any other geometries. An instance
#       belongs to one of the two sheets, not both.
#
# EVERY MARK IS A COMPONENT
#   Each row is backed by a component definition in the model, named after the
#   mark (look for it in the Components window, "In Model"). The component is
#   built from the row: a box of Length x Width x Thickness, or the imported
#   shape stretched to those dimensions. Its origin is the centre of its plan at
#   its bottom face.
#   - Change Width / Length / Thickness in the schedule and the component is
#     rebuilt, so EVERY instance of that mark in the model changes size at once.
#   - Rename a mark and its component is renamed.
#   - Delete a row and its component stays in the model as an ordinary
#     component, no longer driven by the table.
#   - A row with a dimension of 0 has no component yet; it is created as soon as
#     Width, Length and Thickness are all above 0.
#   - Components are created when the table opens, and are rebuilt on every
#     edit. (SketchUp's "Purge Unused" removes components that have no
#     instances; they are recreated automatically.)
#   - One undo step per edit; the table is saved together with the component.
#     After an undo, reopen the table (or click a row) to see the restored values.
#
# QUANTITY (Footing Schedule) = number of instances of each mark's component in
#   the model, copies and nested copies included. Boxes/shapes made by older
#   versions of this plugin (groups tagged "BoxFromMark") and geometry tagged by
#   Import Selection are counted too. It refreshes when the window regains focus
#   and with the "Refresh Quantity" button.
#
# IMPORT SELECTION (button "Import Selection")
#   Captures the selected geometry as a reusable SHAPE for a mark, so shapes that
#   Width x Length x Thickness cannot describe can be stored and placed again.
#   - Select the geometry (loose faces/edges, groups, components - nested
#     groups and components are flattened), click "Import Selection", type a
#     mark (a new mark adds a row; an existing mark asks before it is replaced).
#   - Width, Length and Thickness of the row are filled in from the selection's
#     oriented bounding box (Length = longer plan side). The shape is stored
#     normalised (plan centre at the origin, bottom at Z = 0) and the mark's
#     component is built from it.
#   - Editing the dimensions of a row with a shape STRETCHES the shape to the
#     new size (each direction scaled by new / imported size).
#   - Not stored: textures, back-face materials, smoothing, tags, and the group
#     / component structure (the shape becomes plain geometry in the component).
#   - The ORIGINAL geometry is tagged with the mark so it counts in Quantity
#     (several objects or loose faces/edges are wrapped in one group first).
#   - The x next to a shape removes it; the component becomes a box again.
#
# PLACE MARK (button "Place Mark", also Extensions > Place Box From Mark)
#   No selection needed. Click "Place Mark", pick a mark in the dropdown (only
#   marks in the table can be chosen; the row you last clicked is preselected),
#   then click in the model to place an INSTANCE of the mark's component.
#   A blue preview follows the cursor and snaps like any SketchUp tool; keep
#   clicking to place more. Left / Right arrow rotates 90 degrees, Esc exits.
#   The click point is the centre of the plan and the bottom of the component.
#   The placed instance AND the contents of its component are put on the ACTIVE
#   LAYER (tag) at the moment of placing. The contents belong to the component
#   definition, which every instance of the mark shares, so they follow the layer
#   of the most recent placement; they stay on it when the component is rebuilt
#   after a dimension change.
#
# Usage:
#   Extensions > Variable Database
#   - Click a cell to edit; press Enter / Tab / click away to commit.
#   - Column widths: drag the right edge of a column header (both sheets); the
#     widths are saved in the model.
#   - Keyboard: Tab / Shift+Tab move across cells; Down arrow or Enter moves to
#     the cell below, Up arrow or Shift+Enter to the cell above (Esc cancels).
#   - Reorder (swap) rows of the Footing Schedule: drag the ≡ handle at the
#     start of a row, or press Alt+Up / Alt+Down inside a cell. The tabulation
#     follows the new order.
#   - Type lengths with units ( 300mm, 1.2m, 12", 4' ). A bare number uses the
#     model's current units.
#   - "+ Add Row" appends a row with an auto-generated unique Mark (M1, M2...).
#   - "Export CSV" writes the table (including Quantity and Shape).
#
# Use the data from other Ruby scripts (values are Length):
#   row = VariableDB.find('M1')
#   row[:width], row[:length], row[:thickness]
#   row[:elevation]  # always 0: the Bottom Elevation column was removed; the
#                    # key is kept only so older scripts do not break
#   VariableDB.all   # => array of such hashes
# Optional helpers:
#   VariableDB.definition('M1')   # => the mark's ComponentDefinition (or nil)
#   VariableDB.sync_mark('M1')    # create / rebuild that component from the row
#   VariableDB.quantity('M1')     # => Integer
#   VariableDB.quantities         # => { 'm1' => 3, ... } (lowercase keys)
#   VariableDB.has_shape?('M1')   # => true / false
#   VariableDB.build_shape(entities, 'M1', transformation = identity, name = nil)
#       # builds the stored shape as a plain group (not a component instance)
#
# Install : copy to  %APPDATA%\SketchUp\SketchUp 2019\SketchUp\Plugins\
#           (Mac: ~/Library/Application Support/SketchUp 2019/SketchUp/Plugins/)
# -----------------------------------------------------------------------------

require 'json'
require 'csv'
require 'set'

module VariableDB
  # Lets this file be re-pasted into the Ruby Console without "already initialized constant" warnings
  constants.each { |c| remove_const(c) }

  MENU_NAME = 'Variable Database'.freeze
  DICT      = 'VariableDB'.freeze
  KEY       = 'rows'.freeze
  BOX_DICT  = 'BoxFromMark'.freeze # dictionary written by the box plugins
  NUMERIC   = %w[width length thickness].freeze
  NON_NEG   = %w[width length thickness].freeze
  LABELS    = {
    'width' => 'Width', 'length' => 'Length', 'thickness' => 'Thickness'
  }.freeze

  VERSION   = 'components-v9 (marks are components, no Bottom Elevation)'.freeze
  MAX_FACES = 25_000 # import safety limit (faces + loose edges, after flattening)

  class ImportTooLarge < StandardError; end

  @dialog = nil

  # ---------------------------------------------------------------------------
  # Storage (values kept in inches, the SketchUp internal unit)
  # ---------------------------------------------------------------------------
  def self.rows
    raw = Sketchup.active_model.get_attribute(DICT, KEY)
    return [] unless raw
    JSON.parse(raw)
  rescue JSON::ParserError
    []
  end

  def self.save(rows)
    Sketchup.active_model.set_attribute(DICT, KEY, JSON.generate(rows))
  end

  # Shapes live under their own keys so the table itself stays small
  def self.shape_key(id)
    "shape_#{id}"
  end

  def self.shape_exists?(id)
    return false unless id
    !Sketchup.active_model.get_attribute(DICT, shape_key(id)).nil?
  end

  def self.load_shape(id)
    raw = Sketchup.active_model.get_attribute(DICT, shape_key(id))
    raw && JSON.parse(raw)
  rescue JSON::ParserError
    nil
  end

  def self.save_shape(id, data)
    Sketchup.active_model.set_attribute(DICT, shape_key(id), JSON.generate(data))
  end

  def self.delete_shape(id)
    return unless id
    Sketchup.active_model.delete_attribute(DICT, shape_key(id))
  end

  def self.new_shape_id
    "s#{Time.now.to_i.to_s(36)}#{rand(36**3).to_s(36)}"
  end

  # ---------------------------------------------------------------------------
  # Public API for other scripts
  # ---------------------------------------------------------------------------
  def self.all
    rows.map { |r| to_lengths(r) }
  end

  def self.find(mark)
    r = rows.find { |x| x['mark'].to_s.casecmp(mark.to_s).zero? }
    r && to_lengths(r)
  end

  def self.to_lengths(r)
    {
      mark:      r['mark'],
      width:     r['width'].to_f.to_l,
      length:    r['length'].to_f.to_l,
      thickness: r['thickness'].to_f.to_l,
      elevation: 0.to_l # column removed; kept (always 0) so older scripts keep working
    }
  end

  def self.row_for(mark)
    rows.find { |x| x['mark'].to_s.casecmp(mark.to_s).zero? }
  end

  def self.has_shape?(mark)
    r = row_for(mark)
    !r.nil? && shape_exists?(r['shape'])
  end

  def self.shape(mark)
    r = row_for(mark)
    r && shape_exists?(r['shape']) ? load_shape(r['shape']) : nil
  end

  # ---------------------------------------------------------------------------
  # Geometry builders (stored shapes and boxes)
  # ---------------------------------------------------------------------------

  # Size [length, width, thickness] of a stored shape (its bounding box)
  def self.shape_dims(s)
    xs = s['p'].map { |a| a[0] }
    ys = s['p'].map { |a| a[1] }
    zs = s['p'].map { |a| a[2] }
    [xs.max - xs.min, ys.max - ys.min, zs.max - zs.min]
  end

  # Draws a stored shape into `ents`, stretched by sx, sy, sz
  def self.fill_shape(ents, s, sx = 1.0, sy = 1.0, sz = 1.0)
    pts = s['p'].map { |a| Geom::Point3d.new(a[0] * sx, a[1] * sy, a[2] * sz) }

    (s['f'] || []).each do |fd|
      outer = fd['o'].map { |i| pts[i] }
      next if outer.size < 3
      face = (ents.add_face(outer) rescue nil)
      next unless face

      (fd['h'] || []).each do |loop_idx|
        lp = loop_idx.map { |i| pts[i] }
        next if lp.size < 3
        inner = (ents.add_face(lp) rescue nil)
        inner.erase! if inner && inner.valid?
      end
      next unless face.valid?

      if fd['n']
        n = Geom::Vector3d.new(fd['n'][0], fd['n'][1], fd['n'][2])
        face.reverse! if face.normal.dot(n) < 0
      end
      if fd['c']
        c = fd['c']
        face.material = Sketchup::Color.new(c[0], c[1], c[2], c[3] || 255)
      end
    end

    (s['e'] || []).each { |a, b| ents.add_line(pts[a], pts[b]) }
  end

  # Draws a closed box into `ents`: plan centred on the origin, bottom at Z = 0
  def self.fill_box(ents, length, width, thickness)
    x0 = -length / 2.0
    x1 =  length / 2.0
    y0 = -width / 2.0
    y1 =  width / 2.0
    z0 = 0.0
    z1 = thickness
    c = [
      Geom::Point3d.new(x0, y0, z0), Geom::Point3d.new(x1, y0, z0),
      Geom::Point3d.new(x1, y1, z0), Geom::Point3d.new(x0, y1, z0),
      Geom::Point3d.new(x0, y0, z1), Geom::Point3d.new(x1, y0, z1),
      Geom::Point3d.new(x1, y1, z1), Geom::Point3d.new(x0, y1, z1)
    ]
    center = Geom::Point3d.new(0, 0, thickness / 2.0)
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
  end

  # Builds the stored shape of `mark` as a new plain GROUP inside `entities`.
  # `tr` is applied to the finished group (the shape's origin is its plan
  # centre at the bottom). Returns the group, or nil if the mark has no shape.
  def self.build_shape(entities, mark, tr = Geom::Transformation.new, name = nil)
    s = shape(mark)
    return nil unless s

    group = entities.add_group
    group.name = name || "Shape #{mark}"
    fill_shape(group.entities, s)
    group.transform!(tr) unless tr.nil?
    group
  end

  # ---------------------------------------------------------------------------
  # Marks as components
  # ---------------------------------------------------------------------------

  # The ComponentDefinition that belongs to a mark (nil if there is none yet)
  def self.definition_for(mark)
    Sketchup.active_model.definitions.find do |d|
      !d.image? && d.get_attribute(DICT, 'mark').to_s.casecmp(mark.to_s).zero?
    end
  end

  def self.definition(mark)
    definition_for(mark)
  end

  # Creates the mark's component if it is missing and, when `rebuild` is true,
  # redraws it from the row (box, or the stored shape stretched to the row's
  # size). Every instance in the model follows. Call it inside an operation.
  # Returns the definition, or nil while a dimension is still 0.
  def self.sync_mark(mark, rebuild = true)
    r = row_for(mark)
    return nil unless r

    length    = r['length'].to_f
    width     = r['width'].to_f
    thickness = r['thickness'].to_f
    valid = length > 0 && width > 0 && thickness > 0

    d = definition_for(r['mark'])
    if d.nil?
      return nil unless valid
      d = Sketchup.active_model.definitions.add(r['mark'].to_s)
      d.set_attribute(DICT, 'mark', r['mark'].to_s)
      rebuild = true
    end

    if rebuild && valid
      d.entities.clear!
      s = shape_exists?(r['shape']) ? load_shape(r['shape']) : nil
      if s
        l0, w0, t0 = shape_dims(s)
        sx = l0 > 1e-9 ? length / l0 : 1.0
        sy = w0 > 1e-9 ? width / w0 : 1.0
        sz = t0 > 1e-9 ? thickness / t0 : 1.0
        fill_shape(d.entities, s, sx, sy, sz)
      else
        fill_box(d.entities, length, width, thickness)
      end
      update_metrics(d)

      # new geometry goes back onto the layer the contents were last placed on
      ly_name = d.get_attribute(DICT, 'layer')
      ly = ly_name ? Sketchup.active_model.layers[ly_name] : nil
      assign_layer(d, ly) if ly
    end
    d
  end

  # Puts every element inside a mark's component on `layer` and remembers the
  # layer, so the contents stay on it when the component is rebuilt later
  def self.assign_layer(d, layer)
    return if d.nil? || layer.nil?
    d.entities.each { |e| e.layer = layer if e.respond_to?(:layer=) }
    d.set_attribute(DICT, 'layer', layer.name)
  end

  # Creates the components of marks that have none yet, and measures components
  # that have not been measured (when the table opens)
  def self.ensure_definitions
    todo = rows.select do |x|
      next false unless x['length'].to_f > 0 && x['width'].to_f > 0 && x['thickness'].to_f > 0
      d = definition_for(x['mark'])
      d.nil? || d.get_attribute(DICT, 'side').nil?
    end
    return if todo.empty?

    model = Sketchup.active_model
    model.start_operation('Create mark components', true)
    begin
      todo.each do |x|
        d = definition_for(x['mark'])
        if d.nil?
          sync_mark(x['mark'], true)
        else
          update_metrics(d)
        end
      end
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not create components: #{e.message}"
    end
  end

  def self.rename_definition(old_mark, new_mark)
    d = definition_for(old_mark)
    return unless d
    d.set_attribute(DICT, 'mark', new_mark.to_s)
    begin
      d.name = new_mark.to_s
    rescue => e
      puts "Variable Database: could not rename component: #{e.message}"
    end
  end

  # Releases a component from the table (row deleted): it stays in the model
  def self.detach_definition(mark)
    d = definition_for(mark)
    d.delete_attribute(DICT, 'mark') if d
  end

  # ---------------------------------------------------------------------------
  # Forms and volume of one instance of a mark (output columns)
  # ---------------------------------------------------------------------------
  SIDE_TOL = 0.005 # |normal.z| below this = face parallel to the Z axis
  DOWN_TOL = 0.999 # normal.z below -this = horizontal face looking down

  # true when the model's length unit is mm / cm / m
  def self.metric_units?
    Sketchup.active_model.options['UnitsOptions']['LengthUnit'].to_i >= 2
  rescue
    false
  end

  def self.fmt_area(in2)
    if metric_units?
      format("%.3f m\u00B2", in2 * 0.00064516)
    else
      format("%.2f ft\u00B2", in2 / 144.0)
    end
  end

  def self.fmt_volume(in3)
    if metric_units?
      format("%.3f m\u00B3", in3 * 1.6387064e-5)
    else
      format("%.2f ft\u00B3", in3 / 1728.0)
    end
  end

  # Measures the geometry of a mark's component definition (a single instance)
  # and stores the results on the definition: side, soffit (square inches) and
  # volume (cubic inches, only for a closed solid).
  def self.update_metrics(d)
    data = d.entities.grep(Sketchup::Face).map do |f|
      n = f.normal
      v = 0.0
      mesh = f.mesh
      mesh.polygons.each do |poly|
        pts = poly.map { |i| mesh.point_at(i.abs) }
        next if pts.size < 3
        (1..pts.size - 2).each do |k|
          a = pts[0]
          b = pts[k]
          c = pts[k + 1]
          ab = [b.x.to_f - a.x.to_f, b.y.to_f - a.y.to_f, b.z.to_f - a.z.to_f]
          ac = [c.x.to_f - a.x.to_f, c.y.to_f - a.y.to_f, c.z.to_f - a.z.to_f]
          cx = ab[1] * ac[2] - ab[2] * ac[1]
          cy = ab[2] * ac[0] - ab[0] * ac[2]
          cz = ab[0] * ac[1] - ab[1] * ac[0]
          area = Math.sqrt(cx * cx + cy * cy + cz * cz) / 2.0
          mx = (a.x.to_f + b.x.to_f + c.x.to_f) / 3.0
          my = (a.y.to_f + b.y.to_f + c.y.to_f) / 3.0
          mz = (a.z.to_f + b.z.to_f + c.z.to_f) / 3.0
          # divergence theorem: volume = sum( centroid . normal * area ) / 3
          v += (mx * n.x + my * n.y + mz * n.z) * area / 3.0
        end
      end
      [f, n, v]
    end

    total = data.inject(0.0) { |sum, x| sum + x[2] }
    sign  = total < 0 ? -1.0 : 1.0 # all normals pointing inward -> flip the meaning of "down"

    side   = 0.0
    soffit = 0.0
    data.each do |f, n, _|
      if n.z.abs < SIDE_TOL
        side += f.area
      elsif n.z * sign < -DOWN_TOL
        soffit += f.area
      end
    end

    edges  = d.entities.grep(Sketchup::Edge).select { |e| !e.faces.empty? }
    closed = !edges.empty? && edges.all? { |e| e.faces.size == 2 }

    d.set_attribute(DICT, 'side',   side)
    d.set_attribute(DICT, 'soffit', soffit)
    if closed
      d.set_attribute(DICT, 'volume', total.abs)
    else
      d.delete_attribute(DICT, 'volume')
    end
  end

  # { side:, soffit:, volume: } in square / cubic inches, or nil if not measured yet
  def self.metrics_for(mark)
    d = definition_for(mark)
    return nil unless d
    side = d.get_attribute(DICT, 'side')
    return nil if side.nil?
    {
      side:   side.to_f,
      soffit: d.get_attribute(DICT, 'soffit').to_f,
      volume: d.get_attribute(DICT, 'volume') && d.get_attribute(DICT, 'volume').to_f
    }
  end

  # The four output cells of a schedule row (text)
  def self.output_cells(r, quantities_hash)
    m = metrics_for(r['mark'])
    {
      'side'     => m ? fmt_area(m[:side]) : '',
      'soffit'   => m ? fmt_area(m[:soffit]) : '',
      'volume'   => m ? (m[:volume] ? fmt_volume(m[:volume]) : "\u2014") : '',
      'quantity' => quantities_hash[r['mark'].to_s.downcase].to_s
    }
  end

  # ---------------------------------------------------------------------------
  # Quantity (output column): boxes/shapes tagged with a mark by the box plugins
  # ---------------------------------------------------------------------------
  def self.tally_entities(entities, memo)
    t = Hash.new(0)
    entities.each do |e|
      next unless e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)

      # an instance of a mark's component
      if e.is_a?(Sketchup::ComponentInstance)
        dm = e.definition.get_attribute(DICT, 'mark')
        if dm
          t[dm.to_s.downcase] += 1
          next
        end
      end

      # geometry tagged with a mark (older versions, Import Selection)
      m = e.get_attribute(BOX_DICT, 'mark')
      if m
        t[m.to_s.downcase] += 1
      else
        d = e.definition
        sub = (memo[d.entityID] ||= tally_entities(d.entities, memo))
        sub.each { |k, v| t[k] += v }
      end
    end
    t
  end

  # Share one model traversal across schedule updates in a single synchronous
  # refresh. Outside that scope, quantities always reads the current model.
  # This deliberately avoids stale persistent caches during SketchUp edits.
  def self.with_quantity_snapshot
    return yield if @quantity_snapshot_active
    @quantity_snapshot_active = true
    @quantity_snapshot = nil
    begin
      yield
    ensure
      @quantity_snapshot = nil
      @quantity_snapshot_active = false
    end
  end

  def self.quantities
    if @quantity_snapshot_active
      @quantity_snapshot ||= tally_entities(Sketchup.active_model.entities, {})
    else
      tally_entities(Sketchup.active_model.entities, {})
    end
  end

  def self.quantity(mark)
    quantities[mark.to_s.downcase]
  end

  # ---------------------------------------------------------------------------
  # Import Selection: capture geometry + orientation helpers
  # ---------------------------------------------------------------------------
  def self.container?(e)
    e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
  end

  # Collect faces (with holes, normal, colour) and loose edges in the active
  # context's coordinates. `top` = e is directly in the selection.
  def self.gather(e, tr, sel_ids, top, out)
    return if e.respond_to?(:hidden?) && e.hidden?
    return if e.respond_to?(:layer) && e.layer && !e.layer.visible?

    if e.is_a?(Sketchup::Face)
      outer = e.outer_loop.vertices.map { |v| v.position.transform(tr) }
      holes = e.loops.reject(&:outer?).map do |l|
        l.vertices.map { |v| v.position.transform(tr) }
      end
      n = e.normal.transform(tr)
      n.normalize!
      color = nil
      m = e.material
      if m && m.color
        color = [m.color.red, m.color.green, m.color.blue, (m.alpha * 255).round]
      end
      out[:faces] << { outer: outer, holes: holes, n: n, c: color }
      out[:count] += 1
      raise ImportTooLarge if out[:count] > MAX_FACES
    elsif e.is_a?(Sketchup::Edge)
      loose = top ? e.faces.none? { |f| sel_ids.include?(f.entityID) } : e.faces.empty?
      if loose
        out[:edges] << [e.start.position.transform(tr), e.end.position.transform(tr)]
        out[:count] += 1
        raise ImportTooLarge if out[:count] > MAX_FACES
      end
    elsif container?(e)
      sub = tr * e.transformation
      ents = e.is_a?(Sketchup::Group) ? e.entities : e.definition.entities
      ents.each { |c| gather(c, sub, sel_ids, false, out) }
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

  # Rotation about Z giving the minimum-area rectangle around pts in plan.
  # Angle 0 is the starting candidate, so aligned geometry keeps its axes.
  def self.plan_rotation(pts)
    hull = convex_hull(pts.map { |p| [p.x.to_f, p.y.to_f] }.uniq)
    return Geom::Transformation.new if hull.empty?

    # Dense hulls (curved shapes) would make the search very slow: evaluate the
    # areas on a decimated copy and only try a limited number of edge angles.
    # The final bounding box is still computed from every point afterwards.
    full_hull = hull
    if hull.size > 1500
      k = (hull.size / 1500.0).ceil
      hull = hull.each_with_index.select { |_, i| (i % k).zero? }.map(&:first)
    end
    edge_step = [hull.size / 360, 1].max

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
        next unless (i % edge_step).zero?
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

  def self.bbox_in(frame, pts)
    inv = frame.inverse
    bb = Geom::BoundingBox.new
    pts.each { |p| bb.add(p.transform(inv)) }
    bb
  end

  # Returns { dims: [length, width, thickness, elevation] (inches),
  #           shape: {...}, faces: n, edges: m }  or nil when nothing usable
  def self.capture(selection)
    model = Sketchup.active_model
    sel_ids = Set.new
    selection.each { |e| sel_ids << e.entityID }

    out = { faces: [], edges: [], count: 0 }
    selection.each { |e| gather(e, Geom::Transformation.new, sel_ids, true, out) }
    return nil if out[:faces].empty? && out[:edges].empty?

    pts_all = []
    out[:faces].each { |f| pts_all.concat(f[:outer]) }
    out[:edges].each { |a, b| pts_all << a << b }

    # orientation: group axes (tilt), then tightest rotation in plan
    sel_arr = selection.to_a
    base = if sel_arr.size == 1 && container?(sel_arr[0])
             frame_from(sel_arr[0].transformation)
           else
             Geom::Transformation.new
           end
    base_inv = base.inverse
    local = pts_all.map { |p| p.transform(base_inv) }
    frame = base * plan_rotation(local)

    bb = bbox_in(frame, pts_all)
    # keep the longer plan side along X (= Length)
    if (bb.max.x - bb.min.x) < (bb.max.y - bb.min.y)
      rot90 = Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0),
                                            Geom::Vector3d.new(0, 0, 1), 90.degrees)
      frame = frame * rot90
      bb = bbox_in(frame, pts_all)
    end

    inv = frame.inverse
    cx = (bb.min.x.to_f + bb.max.x.to_f) / 2.0
    cy = (bb.min.y.to_f + bb.max.y.to_f) / 2.0
    z0 = bb.min.z.to_f

    edit_tr = model.edit_transform
    elevation = pts_all.map { |p| p.transform(edit_tr).z.to_f }.min

    # normalised, de-duplicated point table
    table = []
    index = {}
    add_pt = lambda do |p|
      q = p.transform(inv)
      x = (q.x.to_f - cx).round(6)
      y = (q.y.to_f - cy).round(6)
      z = (q.z.to_f - z0).round(6)
      key = [x, y, z]
      unless index.key?(key)
        index[key] = table.size
        table << [x, y, z]
      end
      index[key]
    end

    faces = out[:faces].map do |f|
      n = f[:n].transform(inv)
      n.normalize!
      fd = {
        'o' => f[:outer].map { |p| add_pt.call(p) },
        'n' => [n.x.to_f.round(6), n.y.to_f.round(6), n.z.to_f.round(6)]
      }
      fd['h'] = f[:holes].map { |l| l.map { |p| add_pt.call(p) } } unless f[:holes].empty?
      fd['c'] = f[:c] if f[:c]
      fd
    end

    edges = out[:edges].map { |a, b| [add_pt.call(a), add_pt.call(b)] }

    {
      dims:  [bb.max.x.to_f - bb.min.x.to_f,
              bb.max.y.to_f - bb.min.y.to_f,
              bb.max.z.to_f - bb.min.z.to_f,
              elevation],
      shape: { 'p' => table, 'f' => faces, 'e' => edges },
      faces: faces.size,
      edges: edges.size
    }
  end

  # ---------------------------------------------------------------------------
  # Place Mark (built-in "Place Box From Mark"): pick a mark, click to place it
  # ---------------------------------------------------------------------------
  EDGE_PAIRS = [
    [0, 1], [1, 2], [2, 3], [3, 0],
    [4, 5], [5, 6], [6, 7], [7, 4],
    [0, 4], [1, 5], [2, 6], [3, 7]
  ].freeze

  # 8 corner points of an axis-aligned box in world coordinates
  def self.box_corners_world(cx, cy, dx, dy, z0, z1)
    x0 = cx - dx / 2.0
    x1 = cx + dx / 2.0
    y0 = cy - dy / 2.0
    y1 = cy + dy / 2.0
    [
      Geom::Point3d.new(x0, y0, z0), Geom::Point3d.new(x1, y0, z0),
      Geom::Point3d.new(x1, y1, z0), Geom::Point3d.new(x0, y1, z0),
      Geom::Point3d.new(x0, y0, z1), Geom::Point3d.new(x1, y0, z1),
      Geom::Point3d.new(x1, y1, z1), Geom::Point3d.new(x0, y1, z1)
    ]
  end

  # Closed box group in the active context from 8 world-space corners
  def self.build_box_from_corners(model, world_corners, name)
    to_local = model.edit_transform.inverse
    c = world_corners.map { |p| p.transform(to_local) }
    center = Geom::Point3d.new(
      c.map { |p| p.x.to_f }.inject(:+) / 8.0,
      c.map { |p| p.y.to_f }.inject(:+) / 8.0,
      c.map { |p| p.z.to_f }.inject(:+) / 8.0
    )

    group = model.active_entities.add_group
    group.name = name
    ents = group.entities

    faces = [
      ents.add_face(c[0], c[1], c[2], c[3]), # bottom
      ents.add_face(c[4], c[5], c[6], c[7]), # top
      ents.add_face(c[0], c[1], c[5], c[4]),
      ents.add_face(c[1], c[2], c[6], c[5]),
      ents.add_face(c[2], c[3], c[7], c[6]),
      ents.add_face(c[3], c[0], c[4], c[7])
    ]
    # every face normal points away from the box centre
    faces.compact.each do |f|
      f.reverse! if f.normal.dot(center.vector_to(f.bounds.center)) < 0
    end
    group
  end

  def self.dialog_visible?
    !@dialog.nil? && @dialog.visible?
  end

  # The interactive placing tool
  class PlaceTool
    # row: { mark:, width:, length:, thickness: (inches) }
    def initialize(row)
      @row = row
      @ip  = Sketchup::InputPoint.new
      @rot = 0 # 0 / 1 : toggles which of Width / Length lies along X
    end

    def activate
      update_status
      Sketchup.active_model.active_view.invalidate
    end

    def deactivate(view)
      view.invalidate
    end

    def resume(view)
      update_status
      view.invalidate
    end

    # Esc
    def onCancel(_reason, _view)
      Sketchup.active_model.select_tool(nil)
    end

    def onMouseMove(_flags, x, y, view)
      @ip.pick(view, x, y)
      view.tooltip = @ip.tooltip
      view.invalidate
    end

    def onLButtonDown(_flags, x, y, view)
      @ip.pick(view, x, y)
      return unless @ip.valid?
      place(@ip.position)
      view.invalidate
    end

    def onKeyDown(key, _repeat, _flags, view)
      if key == VK_RIGHT || key == VK_LEFT
        @rot = (@rot + 1) % 2
        view.invalidate
      end
    end

    def draw(view)
      return unless @ip.valid?
      pts = box_corners(@ip.position)
      lines = []
      EDGE_PAIRS.each { |a, b| lines << pts[a] << pts[b] }
      view.drawing_color = Sketchup::Color.new(0, 110, 255)
      view.line_width = 2
      view.draw(GL_LINES, lines)
      @ip.draw(view)
    end

    def getExtents
      bb = Geom::BoundingBox.new
      bb.add(box_corners(@ip.position)) if @ip.valid?
      bb
    end

    private

    def dims
      @rot.even? ? [@row[:length], @row[:width]] : [@row[:width], @row[:length]]
    end

    # preview: the click point is the centre of the plan and the bottom
    def box_corners(pos)
      dx, dy = dims
      z0 = pos.z.to_f
      VariableDB.box_corners_world(pos.x.to_f, pos.y.to_f, dx, dy, z0, z0 + @row[:thickness])
    end

    # inserts an instance of the mark's component at the click point
    def place(pos)
      model = Sketchup.active_model
      model.start_operation("Place #{@row[:mark]}", true)
      begin
        d = VariableDB.sync_mark(@row[:mark], false) # exists (created if missing)
        raise "The component for mark '#{@row[:mark]}' is not available." if d.nil?

        rot = @rot.odd? ? Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0),
                                                       Geom::Vector3d.new(0, 0, 1), 90.degrees)
                        : Geom::Transformation.new
        world_tr = Geom::Transformation.new(
          Geom::Point3d.new(pos.x.to_f, pos.y.to_f, pos.z.to_f)
        ) * rot
        local_tr = model.edit_transform.inverse * world_tr

        inst = model.active_entities.add_instance(d, local_tr)

        # the instance and the component's contents go on the current active layer
        layer = model.active_layer
        inst.layer = layer
        VariableDB.assign_layer(d, layer)
        model.commit_operation
        model.selection.clear
        model.selection.add(inst)
        VariableDB.push_quantities if VariableDB.dialog_visible?
      rescue => e
        model.abort_operation
        UI.messagebox("Error: #{e.message}")
      end
    end

    def update_status
      Sketchup.status_text =
        "#{@row[:mark]}  " \
        "(L #{VariableDB.fmt(@row[:length])} x W #{VariableDB.fmt(@row[:width])} x " \
        "T #{VariableDB.fmt(@row[:thickness])}).  " \
        "Click: place   Left/Right arrow: rotate 90\u00B0   Esc: exit"
    end
  end

  # Errors are reported instead of hanging
  def self.safe_place_mark
    place_mark
  rescue => e
    puts "Variable Database place failed: #{e.class}: #{e.message}"
    puts e.backtrace.first(8)
    UI.messagebox("Place Mark failed: #{e.message}")
  end

  # Choose a mark from a dropdown, then start the placing tool
  def self.place_mark
    r = rows
    if r.empty?
      UI.messagebox("The Variable Database is empty.\nAdd a mark first (+ Add Row or Import Selection).")
      return
    end

    marks = r.map { |x| x['mark'].to_s }
    default =
      if @selected_index && r[@selected_index]
        r[@selected_index]['mark'].to_s
      elsif marks.include?(@last_place_mark)
        @last_place_mark
      else
        marks.first
      end

    # Dropdown only: the user cannot type a mark that is not in the table
    result = UI.inputbox(['Mark'], [default], [marks.join('|')], 'Place Mark')
    return unless result # cancelled

    mark = result[0]
    row  = row_for(mark)
    if row.nil?
      UI.messagebox("Mark '#{mark}' was not found in the database.")
      return
    end
    @last_place_mark = mark

    width     = row['width'].to_f
    length    = row['length'].to_f
    thickness = row['thickness'].to_f

    if width <= 0 || length <= 0 || thickness <= 0
      UI.messagebox("Mark '#{mark}' needs Width, Length and Thickness greater than 0.\n" \
                    "Currently: Width #{fmt(width)}, Length #{fmt(length)}, Thickness #{fmt(thickness)}.")
      return
    end

    # make sure the mark's component exists
    model = Sketchup.active_model
    model.start_operation('Create mark component', true)
    begin
      sync_mark(row['mark'], false)
      model.commit_operation
    rescue => e
      model.abort_operation
      UI.messagebox("Could not create the component: #{e.message}")
      return
    end

    model.select_tool(
      PlaceTool.new(mark: row['mark'].to_s, width: width, length: length,
                    thickness: thickness)
    )
  end

  # Runs a block once, outside the HtmlDialog callback. SketchUp (Windows) can
  # fire a timer again while a modal box opened inside it is still showing, so
  # the timer is stopped on its first tick and a busy flag blocks re-entry.
  def self.defer(key, &blk)
    @busy ||= {}
    return if @busy[key]
    @busy[key] = true
    timer_id = nil
    timer_id = UI.start_timer(0.1, false) do
      UI.stop_timer(timer_id) if timer_id
      begin
        blk.call
      ensure
        @busy[key] = false
      end
    end
  end

  # Runs the import with errors reported instead of hanging
  def self.safe_import
    Sketchup.status_text = 'Importing selection...'
    import_selection
  rescue ImportTooLarge
    UI.messagebox("The selection is too large to import (more than #{MAX_FACES} faces/edges " \
                  "after flattening).\nSelect a smaller shape, or raise VariableDB::MAX_FACES.")
  rescue => e
    puts "Variable Database import failed: #{e.class}: #{e.message}"
    puts e.backtrace.first(8)
    UI.messagebox("Import failed: #{e.message}")
  ensure
    Sketchup.status_text = ''
  end

  # The imported geometry (the "origin" of the shape) counts as one placed item
  # in the Quantity column: it is tagged with the mark, exactly like the boxes
  # and shapes placed by the box plugins. A single selected group/component is
  # tagged directly; anything else (several objects, loose faces/edges) is
  # first wrapped in one group so it can carry the tag. One undo step.
  # Returns the tagged group/component, or nil if tagging was not possible.
  def self.tag_origin(model, selection, mark, dims)
    arr = selection.to_a
    return nil if arr.empty?

    model.start_operation('Count imported geometry in Quantity', true)
    begin
      if arr.size == 1 && container?(arr[0])
        target = arr[0]
      else
        target = model.active_entities.add_group(arr)
        target.name = "Shape #{mark}"
      end
      target.set_attribute(BOX_DICT, 'mark',      mark)
      target.set_attribute(BOX_DICT, 'length',    dims[0])
      target.set_attribute(BOX_DICT, 'width',     dims[1])
      target.set_attribute(BOX_DICT, 'thickness', dims[2])
      model.commit_operation
      selection.clear
      selection.add(target)
      target
    rescue => e
      model.abort_operation
      puts "Variable Database: could not tag imported geometry: #{e.message}"
      nil
    end
  end

  # Button handler
  def self.import_selection
    model = Sketchup.active_model
    sel   = model.selection

    if sel.empty?
      UI.messagebox('Select the geometry to import first, then click "Import Selection".')
      return
    end

    data = capture(sel)
    if data.nil?
      UI.messagebox('The selection contains no faces or edges to import.')
      return
    end

    r = rows
    result = UI.inputbox(['Mark'], [next_mark(r)],
                         "Import Selection (#{data[:faces]} faces, #{data[:edges]} loose edges)")
    return unless result # cancelled

    mark = result[0].to_s.strip
    if mark.empty?
      UI.messagebox('Mark cannot be empty.')
      return
    end

    idx = r.index { |x| x['mark'].to_s.casecmp(mark).zero? }
    if idx
      ask = UI.messagebox("Mark '#{r[idx]['mark']}' already exists.\n" \
                          'Replace its dimensions and shape with the selection?', MB_YESNO)
      return unless ask == IDYES
      row = r[idx]
    else
      row = { 'mark' => mark }
      r << row
    end

    id = row['shape'] || new_shape_id
    length, width, thickness = data[:dims]

    row['length']    = length
    row['width']     = width
    row['thickness'] = thickness
    row['shape']     = id
    row['faces']     = data[:faces]

    save_shape(id, data[:shape])
    save(r)

    # (re)build the mark's component from the new shape / dimensions
    model.start_operation('Update mark component', true)
    begin
      sync_mark(row['mark'], true)
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not update the component: #{e.message}"
    end

    # count the original geometry in Quantity
    tagged = tag_origin(model, sel, row['mark'], [length, width, thickness])
    push_all

    UI.messagebox("Imported '#{row['mark']}':\n" \
                  "Length #{fmt(length)}, Width #{fmt(width)}, Thickness #{fmt(thickness)}\n" \
                  "Component '#{row['mark']}' updated; all its instances follow.\n" \
                  "#{data[:faces]} faces, #{data[:edges]} loose edges stored.\n" \
                  + (tagged ? 'The original geometry now counts in Quantity.' \
                            : 'The original geometry could not be counted in Quantity.'))
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------
  def self.fmt(inches)
    inches.to_f.to_l.to_s
  end

  def self.shape_label(r)
    return '' unless shape_exists?(r['shape'])
    r['faces'] ? "#{r['faces']} faces" : 'shape'
  end

  def self.display_rows
    q = quantities
    rows.map do |r|
      {
        'mark'      => r['mark'].to_s,
        'width'     => fmt(r['width']),
        'length'    => fmt(r['length']),
        'thickness' => fmt(r['thickness']),
        'shape'     => shape_label(r)
      }.merge(output_cells(r, q))
    end
  end

  def self.next_mark(rows)
    used = rows.map { |r| r['mark'].to_s.downcase }
    n = rows.size + 1
    n += 1 while used.include?("m#{n}")
    "M#{n}"
  end

  def self.push_all
    return unless @dialog
    @dialog.execute_script("render(#{JSON.generate(display_rows)})")
  end

  # ---------------------------------------------------------------------------
  # Footing Tabulation: every individual component of every mark
  # ---------------------------------------------------------------------------
  ZONE_KEY    = 'zone'.freeze
  PACKAGE_KEY = 'package'.freeze

  # Finds every instance that represents a mark (an instance of a mark's
  # component, or geometry tagged with a mark), together with the chain of
  # groups / components that contains it.
  def self.collect_items(entities, path, out)
    entities.each do |e|
      next unless e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)

      mark = nil
      mark = e.definition.get_attribute(DICT, 'mark') if e.is_a?(Sketchup::ComponentInstance)
      mark ||= e.get_attribute(BOX_DICT, 'mark')

      if mark
        out << { entity: e, parents: path.dup, mark: mark.to_s }
      else
        collect_items(e.definition.entities, path + [e], out)
      end
    end
  end

  # Items sorted by the order of the marks in the schedule
  def self.tabulation_items
    out = []
    collect_items(Sketchup.active_model.entities, [], out)
    order = rows.map { |r| r['mark'].to_s.downcase }
    out.each_with_index
       .sort_by { |it, i| [order.index(it[:mark].downcase) || order.size, i] }
       .map(&:first)
  end

  # Unique local vertex positions ([x, y, z]) of a definition, including nested
  # groups / components. `memo` caches them per definition.
  def self.definition_points(d, memo)
    memo[d.entityID] ||= begin
      pts = []
      collect_definition_points(d.entities, Geom::Transformation.new, pts)
      pts.map { |p| [p.x.to_f, p.y.to_f, p.z.to_f] }.uniq
    end
  end

  def self.collect_definition_points(entities, tr, pts)
    entities.each do |e|
      if e.is_a?(Sketchup::Edge)
        pts << e.start.position.transform(tr)
        pts << e.end.position.transform(tr)
      elsif e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
        collect_definition_points(e.definition.entities, tr * e.transformation, pts)
      end
    end
  end

  # Global Z (inches) of the HIGHEST POINT of one tabulated component's real
  # geometry (every vertex, with all parent transformations applied); not the
  # bounding box. nil if the component has no geometry.
  def self.toc_z(item, memo = {})
    e = item[:entity]
    pts = definition_points(e.definition, memo)
    return nil if pts.empty?

    tr = Geom::Transformation.new
    item[:parents].each { |pa| tr *= pa.transformation }
    tr *= e.transformation

    m = tr.to_a # column-major: z' = m[2] x + m[6] y + m[10] z + m[14]
    top = nil
    pts.each do |x, y, z|
      zz = m[2] * x + m[6] * y + m[10] * z + m[14]
      top = zz if top.nil? || zz > top
    end
    top
  end

  # Moves a component straight up / down so its top is at `target` (global Z, inches).
  # Returns true if it moved.
  def self.move_item_top_to(item, target, memo)
    cur = toc_z(item, memo)
    return false if cur.nil?
    dz = target - cur
    return false if dz.abs < 0.0005

    parent_tr = Geom::Transformation.new
    item[:parents].each { |pa| parent_tr *= pa.transformation }
    vec = Geom::Vector3d.new(0, 0, dz).transform(parent_tr.inverse) # global vertical in the parent's axes
    item[:entity].transform!(Geom::Transformation.translation(vec))
    true
  end

  # ---- remembered column widths (both sheets) ----
  def self.col_widths
    raw = Sketchup.active_model.get_attribute(DICT, 'col_widths')
    raw ? JSON.parse(raw) : {}
  rescue JSON::ParserError
    {}
  end

  def self.save_col_widths(msg)
    sheet = msg['sheet'].to_s
    return unless %w[schedule tab bulk misc structural].include?(sheet)
    widths = {}
    (msg['widths'] || {}).each { |k, v| widths[k.to_s] = v.to_f.round if v.to_f > 0 }
    all = col_widths
    all[sheet] = widths
    Sketchup.active_model.set_attribute(DICT, 'col_widths', JSON.generate(all))
  end

  def self.push_widths
    return unless @dialog
    @dialog.execute_script("setWidths(#{JSON.generate(col_widths)})")
  end

  # ---- input columns of the tabulation (variables stored on each component) ----
  DEFAULT_TAB_COLUMNS = [
    { 'id' => 'zone',    'name' => 'Zone' },
    { 'id' => 'package', 'name' => 'Package' }
  ].freeze

  # [{ 'id' => ..., 'name' => ... }]; the id is also the attribute key on the component
  def self.tab_columns
    raw = Sketchup.active_model.get_attribute(DICT, 'tab_columns')
    if raw
      cols = JSON.parse(raw)
      return cols if cols.is_a?(Array)
    end
    DEFAULT_TAB_COLUMNS.map(&:dup)
  rescue JSON::ParserError
    DEFAULT_TAB_COLUMNS.map(&:dup)
  end

  def self.save_tab_columns(cols)
    Sketchup.active_model.set_attribute(DICT, 'tab_columns', JSON.generate(cols))
  end

  # ---------------------------------------------------------------------------
  # Color by column: one colour per distinct value, painted on the instances
  # (shared by the Footing Tabulation ('tab') and Bulk Excavation ('bulk') sheets)
  # ---------------------------------------------------------------------------
  FILTER_PREFIXES = { 'tab' => 'VDB Filter - ', 'bulk' => 'VDB Bulk Filter - ', 'misc' => 'VDB Misc Filter - ', 'structural' => 'VDB Structural Filter - ' }.freeze
  FILTER_ATTRS    = { 'tab' => 'filter_col',    'bulk' => 'bulk_filter_col', 'misc' => 'misc_filter_col', 'structural' => 'structural_filter_col' }.freeze
  FILTER_FIXED    = %w[component mark toc gridx gridy name volume top bot perimeter height].freeze

  # ---- helpers that let the colour filter serve every sheet ('tab', 'bulk', 'misc') ----
  SHEET_JS = { 'tab' => '', 'bulk' => 'Bulk', 'misc' => 'Misc', 'structural' => 'Structural' }.freeze

  def self.bulklike?(sheet)
    sheet == 'bulk' || sheet == 'misc' || sheet == 'structural'
  end

  # true when an entity already belongs to the Bulk Excavation or Miscellaneous sheet
  def self.sheet_member?(e)
    e.get_attribute(DICT, 'bulk') || e.get_attribute(DICT, 'misc') || e.get_attribute(DICT, 'structural_excavation')
  end

  def self.sheet_items_cached(sheet)
    { 'tab' => @tab_items, 'bulk' => @bulk_items, 'misc' => @misc_items, 'structural' => @structural_items }[sheet]
  end

  def self.sheet_items_fresh(sheet)
    case sheet
    when 'bulk' then bulk_items
    when 'misc' then misc_items
    when 'structural' then structural_items
    else tabulation_items
    end
  end

  def self.sheet_columns(sheet)
    case sheet
    when 'bulk' then bulk_columns
    when 'misc' then misc_columns
    when 'structural' then structural_columns
    else tab_columns
    end
  end

  def self.sheet_rows(sheet, items, cols)
    sheet == 'tab' ? build_tab_rows(items, cols) : build_bulk_rows(items, cols)
  end

  def self.push_sheet(sheet)
    case sheet
    when 'bulk' then push_bulk
    when 'misc' then push_misc
    when 'structural' then push_structural
    else push_tabulation
    end
  end

  def self.msg_fn(sheet)
    sheet == 'tab' ? 'tabMsg' : "#{sheet}Msg"
  end

  def self.filter_fn(sheet)
    sheet == 'tab' ? 'setFilter' : "set#{SHEET_JS[sheet]}Filter"
  end

  def self.filter_col(sheet = 'tab')
    c = Sketchup.active_model.get_attribute(DICT, FILTER_ATTRS[sheet]).to_s
    c.empty? ? nil : c
  end

  # id => name of every column that can be coloured by
  def self.filter_names(sheet = 'tab')
    if bulklike?(sheet)
      h = { 'name' => 'Instance', 'volume' => 'Volume', 'top' => 'Top Elevation', 'bot' => 'Bot Elevation' }
      if sheet == 'structural'
        h['perimeter'] = 'Upper Perimeter'
        h['height'] = 'Height'
      end
      sheet_columns(sheet).each { |c| h[c['id']] = c['name'].to_s }
    else
      h = { 'component' => 'Component', 'mark' => 'Mark' }
      tab_columns.each { |c| h[c['id']] = c['name'].to_s }
      h['toc'] = 'TOC'
      h['gridx'] = 'Grid X'
      h['gridy'] = 'Grid Y'
    end
    h
  end

  def self.filter_value(row, col)
    FILTER_FIXED.include?(col) ? row[col].to_s : row['vals'][col].to_s
  end

  def self.hsl_to_rgb(h, s, l)
    c = (1 - (2 * l - 1).abs) * s
    x = c * (1 - ((h / 60.0) % 2 - 1).abs)
    m = l - c / 2.0
    r, g, b = case (h / 60.0).floor % 6
              when 0 then [c, x, 0]
              when 1 then [x, c, 0]
              when 2 then [0, c, x]
              when 3 then [0, x, c]
              when 4 then [x, 0, c]
              else [c, 0, x]
              end
    [r, g, b].map { |v| ((v + m) * 255).round }
  end

  # value => [r, g, b]. Hues step by the golden angle, so neighbouring values
  # always look different; alternate lightness separates them further.
  def self.palette(values)
    map = {}
    values.each_with_index do |v, i|
      map[v] = hsl_to_rgb((i * 137.508) % 360.0, 0.68, i.even? ? 0.46 : 0.58)
    end
    map
  end

  def self.hex(rgb)
    format('#%02x%02x%02x', *rgb)
  end

  def self.filter_material(model, prefix, col_name, value, rgb)
    label = value.empty? ? '(blank)' : value
    name  = "#{prefix}#{col_name} - #{label}".gsub(/[\[\]<>]/, '_')
    mat = model.materials[name] || model.materials.add(name)
    mat.color = Sketchup::Color.new(rgb[0], rgb[1], rgb[2])
    mat
  end

  def self.remove_filter_materials(model, prefix, keep = {})
    model.materials.to_a.each do |m|
      next unless m.name.start_with?(prefix) && !keep[m.name]
      begin
        model.materials.remove(m)
      rescue => e
        puts "Variable Database: could not remove material #{m.name}: #{e.message}"
      end
    end
  end

  # Gives one painted entity its original material back
  def self.restore_material(model, e)
    return true unless e.valid? && e.get_attribute(DICT, 'orig_mat_saved')
    name = e.get_attribute(DICT, 'orig_mat').to_s
    e.material = name.empty? ? nil : model.materials[name]
    e.delete_attribute(DICT, 'orig_mat')
    e.delete_attribute(DICT, 'orig_mat_saved')
    true
  rescue => err
    puts "Variable Database: could not restore a material: #{err.class}: #{err.message}"
    false
  end

  # Paints every item with the colour of its value. The original material is
  # remembered on the entity so it can be restored.
  def self.paint_items(sheet, items, values, rgbs, col_name)
    model  = Sketchup.active_model
    prefix = FILTER_PREFIXES[sheet]
    model.start_operation("Color by #{col_name}", true)
    begin
      used = {}
      items.each_with_index do |it, i|
        e = it[:entity]
        next unless e.valid?
        next if e.respond_to?(:locked?) && e.locked?
        unless e.get_attribute(DICT, 'orig_mat_saved')
          e.set_attribute(DICT, 'orig_mat', e.material ? e.material.name : '')
          e.set_attribute(DICT, 'orig_mat_saved', true)
        end
        mat = filter_material(model, prefix, col_name, values[i], rgbs[i])
        used[mat.name] = true
        e.material = mat
      end
      remove_filter_materials(model, prefix, used)
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not colour the components: #{e.message}"
    end
  end

  # Restores the original materials of every painted item of a sheet
  def self.clear_filter_paint(sheet = 'tab')
    model  = Sketchup.active_model
    failed = 0
    items  = sheet_items_fresh(sheet)
    model.start_operation('Clear colors', true)
    begin
      items.each { |it| failed += 1 unless restore_material(model, it[:entity]) }
      remove_filter_materials(model, FILTER_PREFIXES[sheet])
      model.commit_operation
    rescue => e
      model.abort_operation
      failed += 1
      puts "Variable Database: could not clear the colours: #{e.message}"
    end
    (@filter_sig ||= {})[sheet] = nil
    if failed > 0 && @dialog
      fn = msg_fn(sheet)
      @dialog.execute_script("#{fn}(#{"#{failed} item(s) could not be restored (see the Ruby Console).".to_json})")
    end
  end

  # Called after undo / redo: the model no longer matches what was painted
  def self.invalidate_filter
    @filter_sig = {}
  end

  # Applies the chosen "Color by" column to the model (when something changed)
  # and returns what the window needs: legend + one colour per row.
  # `data` = rows in the order of `items`.
  def self.sync_filter(sheet, items, data)
    model = Sketchup.active_model
    col   = filter_col(sheet)
    names = filter_names(sheet)
    @filter_sig ||= {}

    if col.nil? || !names.key?(col)
      model.delete_attribute(DICT, FILTER_ATTRS[sheet]) if col # the column no longer exists
      clear_filter_paint(sheet) if @filter_sig[sheet]
      @filter_sig[sheet] = nil
      return nil
    end

    values   = data.map { |r| filter_value(r, col) }
    distinct = values.reject(&:empty?).uniq.sort
    pal      = palette(distinct)
    gray     = [150, 150, 150]
    rgbs     = values.map { |v| v.empty? ? gray : pal[v] }

    sig = [col, names[col], values, items.map { |it| it[:entity].entityID }].hash
    if sig != @filter_sig[sheet]
      paint_items(sheet, items, values, rgbs, names[col])
      @filter_sig[sheet] = sig
    end

    legend = distinct.map do |v|
      idx = []
      values.each_with_index { |x, i| idx << i if x == v }
      { 'value' => v, 'color' => hex(pal[v]), 'count' => idx.size, 'rows' => idx }
    end
    blanks = (0...values.size).select { |i| values[i].empty? }
    unless blanks.empty?
      legend << { 'value' => '(blank)', 'color' => hex(gray), 'count' => blanks.size, 'rows' => blanks }
    end

    { 'col' => col, 'name' => names[col], 'legend' => legend, 'colors' => rgbs.map { |c| hex(c) } }
  end

  # "Color by" list: 'none' = clear
  def self.set_filter(sheet, col)
    model = Sketchup.active_model
    if col.nil? || col.to_s.empty? || col.to_s == 'none'
      model.delete_attribute(DICT, FILTER_ATTRS[sheet])
      clear_filter_paint(sheet)
    else
      model.set_attribute(DICT, FILTER_ATTRS[sheet], col.to_s)
      (@filter_sig ||= {})[sheet] = nil
    end
    push_sheet(sheet)
  end

  # After an edit: recolour and update the legend without re-drawing the table
  def self.push_filter_update(sheet = 'tab')
    items = sheet_items_cached(sheet)
    return unless dialog_visible? && items && filter_col(sheet)
    data = sheet_rows(sheet, items, sheet_columns(sheet))
    info = sync_filter(sheet, items, data)
    fn = filter_fn(sheet)
    @dialog.execute_script("#{fn}(#{JSON.generate(info)})") if info
  end

  # ---------------------------------------------------------------------------
  # Grid lines: labelled edges / guide lines, read by the Grid X / Grid Y columns
  #   - A line parallel to the Y axis sits at one X  -> it is a "Grid X" line.
  #   - A line parallel to the X axis sits at one Y  -> it is a "Grid Y" line.
  #   - Z is ignored (the line may be at any elevation) and so is the length of
  #     the line: a gridline is treated as infinite.
  #   - A component "intersects" a gridline when the gridline's X (or Y) lies
  #     within the X (or Y) extent of the component's real geometry.
  # The label (letter / number) is stored on the line itself: see "Label Grid".
  # ---------------------------------------------------------------------------
  GRID_KEY = 'grid_label'.freeze
  GRID_TOL = 0.01 # inches: touching a gridline counts as intersecting it
  GRID_MANUAL_X = 'grid_x_manual'.freeze # typed by hand where no gridline cuts the component
  GRID_MANUAL_Y = 'grid_y_manual'.freeze

  # [:x, position] for a line parallel to the Y axis, [:y, position] for one
  # parallel to the X axis (global coordinates, inches); nil for anything else
  def self.grid_line_info(e, tr)
    if e.is_a?(Sketchup::Edge)
      p1 = e.start.position.transform(tr)
      p2 = e.end.position.transform(tr)
      dx = (p2.x.to_f - p1.x.to_f).abs
      dy = (p2.y.to_f - p1.y.to_f).abs
      pos = p1
    elsif e.is_a?(Sketchup::ConstructionLine)
      pos = e.position.transform(tr)
      d = e.direction.transform(tr)
      dx = d.x.to_f.abs
      dy = d.y.to_f.abs
    else
      return nil
    end

    len = Math.sqrt(dx * dx + dy * dy)
    return nil if len < 1e-6
    return [:x, pos.x.to_f] if dx <= len * 1e-4
    return [:y, pos.y.to_f] if dy <= len * 1e-4
    nil
  end

  # does this definition (or anything nested in it) hold a labelled gridline?
  def self.definition_has_grid?(d, memo)
    return memo[d.entityID] if memo.key?(d.entityID)
    memo[d.entityID] = false # guards against loops
    found = d.entities.any? do |e|
      if e.is_a?(Sketchup::Edge) || e.is_a?(Sketchup::ConstructionLine)
        !e.get_attribute(DICT, GRID_KEY).to_s.empty?
      elsif e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
        definition_has_grid?(e.definition, memo)
      else
        false
      end
    end
    memo[d.entityID] = found
  end

  def self.collect_grid_lines(entities, tr, memo, out)
    entities.each do |e|
      if e.is_a?(Sketchup::Edge) || e.is_a?(Sketchup::ConstructionLine)
        label = e.get_attribute(DICT, GRID_KEY).to_s
        next if label.empty?
        info = grid_line_info(e, tr)
        out[info[0]] << [info[1], label] if info
      elsif e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
        next unless definition_has_grid?(e.definition, memo)
        collect_grid_lines(e.definition.entities, tr * e.transformation, memo, out)
      end
    end
  end

  # { x: [[position, label], ...], y: [...] } sorted by position
  def self.grid_lines
    out = { x: [], y: [] }
    collect_grid_lines(Sketchup.active_model.entities, Geom::Transformation.new, {}, out)
    [:x, :y].each do |k|
      out[k] = out[k].map { |p, l| [p.round(3), l] }.uniq.sort_by { |p, l| [p, l] }
    end
    out
  end

  # [xmin, xmax, ymin, ymax] (global, inches) of an item's real geometry, or nil
  def self.xy_range(item, memo)
    e = item[:entity]
    pts = definition_points(e.definition, memo)
    return nil if pts.empty?
    m = (item_chain(item) * e.transformation).to_a
    x0 = x1 = y0 = y1 = nil
    pts.each do |x, y, z|
      xx = m[0] * x + m[4] * y + m[8] * z + m[12]
      yy = m[1] * x + m[5] * y + m[9] * z + m[13]
      x0 = xx if x0.nil? || xx < x0
      x1 = xx if x1.nil? || xx > x1
      y0 = yy if y0.nil? || yy < y0
      y1 = yy if y1.nil? || yy > y1
    end
    [x0, x1, y0, y1]
  end

  # labels of the gridlines whose position lies within [lo, hi]
  def self.grid_hits(lines, lo, hi)
    lines.select { |p, _| p >= lo - GRID_TOL && p <= hi + GRID_TOL }.map(&:last).uniq.join(', ')
  end

  # "1, 2, 3" -> ['1', '2', '3'];  '' -> n empty labels (clears);  wrong count -> nil
  def self.parse_grid_labels(text, n)
    return Array.new(n, '') if text.to_s.strip.empty?
    parts = text.to_s.split(',').map(&:strip)
    parts.size == n ? parts : nil
  end

  # "Label Grid": give the selected gridlines their letters / numbers
  def self.label_grid
    model = Sketchup.active_model
    sel   = model.selection
    lines = sel.grep(Sketchup::Edge) + sel.grep(Sketchup::ConstructionLine)
    if lines.empty?
      UI.messagebox("Select the gridlines in the model first (lines drawn as edges, or guide lines),\n" \
                    'then click "Label Grid".')
      return
    end

    tr = model.edit_transform # context -> global
    groups  = { x: {}, y: {} }
    ignored = 0
    lines.each do |e|
      info = grid_line_info(e, tr)
      if info.nil?
        ignored += 1
      else
        (groups[info[0]][info[1].round(2)] ||= []) << e
      end
    end
    if groups[:x].empty? && groups[:y].empty?
      UI.messagebox("None of the selected lines runs along the X or the Y axis.\n" \
                    'A gridline must be parallel to the X axis or to the Y axis.')
      return
    end

    xkeys = groups[:x].keys.sort
    ykeys = groups[:y].keys.sort
    current = lambda do |g, keys|
      keys.map { |k| g[k].map { |e| e.get_attribute(DICT, GRID_KEY).to_s }.reject(&:empty?).first.to_s }.join(', ')
    end

    prompts  = []
    defaults = []
    unless xkeys.empty?
      prompts  << "Grid X: #{xkeys.size} line(s) from lowest X, e.g. A, B, C"
      defaults << current.call(groups[:x], xkeys)
    end
    unless ykeys.empty?
      prompts  << "Grid Y: #{ykeys.size} line(s) from lowest Y, e.g. 1, 2, 3"
      defaults << current.call(groups[:y], ykeys)
    end
    yidx = xkeys.empty? ? 0 : 1

    labels_x = labels_y = nil
    loop do
      result = UI.inputbox(prompts, defaults, 'Label Grid')
      return unless result # cancelled
      ok = true
      unless xkeys.empty?
        defaults[0] = result[0].to_s
        labels_x = parse_grid_labels(result[0], xkeys.size)
        if labels_x.nil?
          UI.messagebox("Enter exactly #{xkeys.size} label(s) for Grid X, separated by commas " \
                        '(or leave it empty to clear them).')
          ok = false
        end
      end
      if ok && !ykeys.empty?
        defaults[yidx] = result[yidx].to_s
        labels_y = parse_grid_labels(result[yidx], ykeys.size)
        if labels_y.nil?
          UI.messagebox("Enter exactly #{ykeys.size} label(s) for Grid Y, separated by commas " \
                        '(or leave it empty to clear them).')
          ok = false
        end
      end
      break if ok
    end

    model.start_operation('Label grid', true)
    begin
      apply = lambda do |g, keys, labels|
        keys.each_with_index do |k, i|
          g[k].each do |e|
            if labels[i].empty?
              e.delete_attribute(DICT, GRID_KEY)
            else
              e.set_attribute(DICT, GRID_KEY, labels[i])
            end
          end
        end
      end
      apply.call(groups[:x], xkeys, labels_x) if labels_x
      apply.call(groups[:y], ykeys, labels_y) if labels_y
      model.commit_operation
    rescue => e
      model.abort_operation
      UI.messagebox("Could not label the grid: #{e.message}")
      return
    end

    push_tabulation
    if ignored > 0
      UI.messagebox("#{ignored} selected line(s) were skipped: they are not parallel to the X or Y axis.")
    end
  end

  def self.safe_label_grid
    label_grid
  rescue => e
    puts "Variable Database grid labelling failed: #{e.class}: #{e.message}"
    puts e.backtrace.first(8)
    UI.messagebox("Label Grid failed: #{e.message}")
  end

  # One data row per tabulated component (text as shown in the sheet)
  def self.build_tab_rows(items, cols)
    seq  = Hash.new(0)
    memo = {}
    grid = grid_lines
    items.map do |it|
      e = it[:entity]
      key = it[:mark].downcase
      seq[key] += 1
      name = e.name.to_s
      name = format('%s-%02d', it[:mark], seq[key]) if name.empty?
      vals = {}
      cols.each { |c| vals[c['id']] = e.get_attribute(DICT, c['id']).to_s }
      xr = xy_range(it, memo)
      gx = xr ? grid_hits(grid[:x], xr[0], xr[1]) : ''
      gy = xr ? grid_hits(grid[:y], xr[2], xr[3]) : ''
      {
        'component' => name,
        'mark'      => it[:mark],
        'vals'      => vals,
        'toc'       => (z = toc_z(it, memo)) ? fmt(z) : '',
        # a gridline cuts the component: its label; otherwise what was typed by hand
        'gridx'     => gx.empty? ? e.get_attribute(DICT, GRID_MANUAL_X).to_s : gx,
        'gridy'     => gy.empty? ? e.get_attribute(DICT, GRID_MANUAL_Y).to_s : gy,
        'gx_auto'   => !gx.empty?,
        'gy_auto'   => !gy.empty?
      }
    end
  end

  # Rebuilds the list behind the sheet and sends it to the window
  def self.push_tabulation
    return unless @dialog

    @tab_items = tabulation_items
    cols = tab_columns
    data = build_tab_rows(@tab_items, cols)
    @tab_data = data
    @tab_cols = cols

    info = sync_filter('tab', @tab_items, data)
    info['colors'].each_with_index { |c, i| data[i]['color'] = c } if info

    @dialog.execute_script("renderTab(#{JSON.generate('cols' => cols, 'rows' => data, 'filter' => info)})")
  end

  # Structural Excavation: generated groups, stored on the entities so they
  # survive model saves, undo/redo and reopening the database dialog.
  def self.structural_items
    out = []
    walk = lambda do |entities, parents|
      entities.each do |entity|
        next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
        if entity.get_attribute(DICT, 'structural_excavation')
          out << { entity: entity, parents: parents.dup }
        else
          walk.call(entity.definition.entities, parents + [entity])
        end
      end
    end
    walk.call(Sketchup.active_model.entities, [])
    out.sort_by { |it| it[:entity].get_attribute(DICT, 'structural_excavation_seq').to_s }
  end

  # Custom columns are stored on the model; each generated group's values are
  # stored on that group, just like Bulk Excavation and Miscellaneous.
  def self.structural_columns
    raw = Sketchup.active_model.get_attribute(DICT, 'structural_columns')
    cols = raw ? JSON.parse(raw) : []
    cols.is_a?(Array) ? cols : []
  rescue JSON::ParserError
    []
  end

  def self.save_structural_columns(cols)
    Sketchup.active_model.set_attribute(DICT, 'structural_columns', JSON.generate(cols))
  end

  def self.structural_msg(message)
    @dialog.execute_script("structuralMsg(#{message.to_s.to_json})") if @dialog
  end

  # Bounding-box outputs for Structural Excavation.  Measure vertices in
  # world coordinates, accounting for nesting, rotations, and instance scales.
  # Upper perimeter is the perimeter of the global XY bounding rectangle at
  # the top Z plane, not the outline of an irregular top surface.
  def self.build_structural_rows(items, cols)
    memo = {}
    items.map do |it|
      entity = it[:entity]
      points = definition_points(entity.definition, memo)
      xs = []
      ys = []
      zs = []
      unless points.empty?
        m = (item_chain(it) * entity.transformation).to_a
        points.each do |x, y, z|
          xs << m[0] * x + m[4] * y + m[8] * z + m[12]
          ys << m[1] * x + m[5] * y + m[9] * z + m[13]
          zs << m[2] * x + m[6] * y + m[10] * z + m[14]
        end
      end
      vol = item_volume(it)
      vals = {}
      cols.each { |c| vals[c['id']] = entity.get_attribute(DICT, c['id']).to_s }
      measured = !zs.empty?
      perimeter = measured ? 2.0 * ((xs.max - xs.min) + (ys.max - ys.min)) : nil
      height = measured ? zs.max - zs.min : nil
      {
        'name'      => entity.name.to_s,
        'volume'    => (vol && vol > 1e-9) ? fmt_volume(vol) : "\u2014",
        'top'       => measured ? fmt(zs.max) : '',
        'bot'       => measured ? fmt(zs.min) : '',
        'perimeter' => perimeter ? fmt(perimeter) : '',
        'height'    => height ? fmt(height) : '',
        'vals'      => vals
      }
    end
  end

  def self.push_structural
    return unless @dialog
    @structural_items = structural_items
    cols = structural_columns
    rows = build_structural_rows(@structural_items, cols)
    @structural_data = rows
    @structural_cols = cols
    info = sync_filter('structural', @structural_items, rows)
    info['colors'].each_with_index { |c, i| rows[i]['color'] = c } if info
    @dialog.execute_script("renderStructural(#{JSON.generate('cols' => cols, 'rows' => rows, 'filter' => info)})")
  end

  # Export the complete Structural Excavation registry, including user columns.
  # Do not export only visible/filtered rows, matching the other database sheets.
  def self.export_structural_csv
    path = UI.savepanel('Export Structural Excavation', nil, 'structural_excavation.csv')
    return unless path
    path += '.csv' unless path.downcase.end_with?('.csv')

    cols = structural_columns
    rows = build_structural_rows(structural_items, cols)
    CSV.open(path, 'w') do |csv|
      csv << ['Instance', 'Volume', 'Top Elevation', 'Bot Elevation', 'Upper Perimeter', 'Height'] + cols.map { |c| c['name'] }
      rows.each do |row|
        csv << [row['name'], row['volume'], row['top'], row['bot'], row['perimeter'], row['height']] +
               cols.map { |c| (row['vals'] || {})[c['id']] }
      end
    end
    UI.messagebox("Exported to:\n#{path}")
  rescue => e
    UI.messagebox("Structural Excavation export failed: #{e.message}")
  end

  def self.generate_structural_excavation
    result = ExcavationFromFooting.run(true)
    push_structural if result && !result.empty?
  end

  def self.generate_structural_berm
    result = InvertedTrapezoidBBox.run(true)
    push_structural if result && !result.empty?
  end

  # Delete registered excavation/berm instances, not just their table rows.
  # One operation keeps multi-row deletion undoable as a single SketchUp action.
  def self.delete_structural_rows(indices)
    source = @structural_items
    return unless source
    requested = Array(indices).map do |index|
      index.is_a?(Integer) && index >= 0 && index < source.length ? source[index] : nil
    end.compact
    targets = requested.map { |item| item[:entity] }.uniq.select do |entity|
      entity.valid? && entity.get_attribute(DICT, 'structural_excavation')
    end
    return if targets.empty?

    model = Sketchup.active_model
    model.start_operation(targets.length == 1 ? 'Delete Structural Excavation' : 'Delete Structural Excavations', true)
    begin
      targets.each { |entity| entity.erase! if entity.valid? }
      model.commit_operation
    rescue => error
      model.abort_operation
      structural_msg("Could not delete structural excavation: #{error.message}")
      return
    end
    push_structural
    push_picked(true)
  end

  # Only user-defined input cells and the instance name may be edited here.
  # The excavation and berm geometries themselves are never changed by a
  # custom-column edit; volume and elevations remain calculated outputs.
  def self.handle_structural_edit(msg)
    key = msg['f'].to_s
    items = Array(msg['rows']).map { |i| @structural_items && @structural_items[i.to_i] }.compact
    items.select! { |it| it[:entity].valid? }
    return if items.empty?
    value = msg['v'].to_s.strip
    cols = structural_columns
    return unless key == 'name' || cols.any? { |c| c['id'] == key }
    if key == 'name'
      return if value.empty?
      items = [items.first]
    end
    model = Sketchup.active_model
    model.start_operation(key == 'name' ? 'Rename structural instance' : 'Edit structural column', true)
    begin
      items.each do |it|
        e = it[:entity]
        if key == 'name'
          e.name = value
        elsif value.empty?
          e.delete_attribute(DICT, key)
        else
          e.set_attribute(DICT, key, value)
        end
      end
      model.commit_operation
    rescue => e
      model.abort_operation
      structural_msg("Edit failed: #{e.message}")
    end
    push_structural
  end

  def self.add_structural_column
    cols = structural_columns
    n = cols.size + 1
    n += 1 while cols.any? { |c| c['name'].to_s.casecmp("Column #{n}").zero? }
    id = "s#{Time.now.to_i.to_s(36)}#{rand(36**4).to_s(36)}"
    model = Sketchup.active_model
    model.start_operation('Add structural column', true)
    begin
      save_structural_columns(cols + [{ 'id' => id, 'name' => "Column #{n}" }])
      model.commit_operation
    rescue => e
      model.abort_operation
      structural_msg("Could not add column: #{e.message}")
    end
    push_structural
  end

  def self.rename_structural_column(msg)
    id = msg['id'].to_s
    name = msg['name'].to_s.strip
    cols = structural_columns
    col = cols.find { |c| c['id'] == id }
    reserved = ['instance', 'volume', 'top elevation', 'bot elevation']
    if !col || name.empty? || reserved.include?(name.downcase) ||
       cols.any? { |c| c['id'] != id && c['name'].to_s.casecmp(name).zero? }
      structural_msg('Invalid or duplicate column name.')
      return push_structural
    end
    model = Sketchup.active_model
    model.start_operation('Rename structural column', true)
    begin
      col['name'] = name
      save_structural_columns(cols)
      model.commit_operation
    rescue => e
      model.abort_operation
      structural_msg("Could not rename column: #{e.message}")
    end
    push_structural
  end

  def self.delete_structural_column(id)
    cols = structural_columns
    return unless cols.any? { |c| c['id'] == id }
    model = Sketchup.active_model
    model.start_operation('Delete structural column', true)
    begin
      structural_items.each do |it|
        e = it[:entity]
        e.delete_attribute(DICT, id) if e.valid?
      end
      save_structural_columns(cols.reject { |c| c['id'] == id })
      model.commit_operation
    rescue => e
      model.abort_operation
      structural_msg("Could not delete column: #{e.message}")
    end
    push_structural
  end

  # ===========================================================================
  # Bulk Excavation sheet: geometries added with Import Selection
  #   Instance | Volume | Top Elevation | Bot Elevation | <your input columns>
  # Every row is one group / component instance in the model, tagged with the
  # attribute VariableDB/bulk. Top / Bot Elevation read the highest / lowest
  # point of its real geometry (global Z); typing one stretches the geometry
  # vertically so that face lands on the new elevation (the opposite face stays).
  # ===========================================================================

  def self.collect_bulk_items(entities, path, out)
    entities.each do |e|
      next unless e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
      if e.get_attribute(DICT, 'bulk')
        out << { entity: e, parents: path.dup }
      else
        collect_bulk_items(e.definition.entities, path + [e], out)
      end
    end
  end

  # Imported instances, in the order they were imported
  def self.bulk_items
    out = []
    collect_bulk_items(Sketchup.active_model.entities, [], out)
    out.each_with_index
       .sort_by { |it, i| [it[:entity].get_attribute(DICT, 'bulk_seq').to_i, i] }
       .map(&:first)
  end

  # ---- input columns of the bulk sheet (none to start with) ----
  def self.bulk_columns
    raw = Sketchup.active_model.get_attribute(DICT, 'bulk_columns')
    cols = raw ? JSON.parse(raw) : []
    cols.is_a?(Array) ? cols : []
  rescue JSON::ParserError
    []
  end

  def self.save_bulk_columns(cols)
    Sketchup.active_model.set_attribute(DICT, 'bulk_columns', JSON.generate(cols))
  end

  # product of the transformations of the groups / components around an item
  def self.item_chain(item)
    tr = Geom::Transformation.new
    item[:parents].each { |pa| tr *= pa.transformation }
    tr
  end

  # [lowest, highest] global Z (inches) of an item's real geometry, or nil
  def self.z_range(item, memo)
    e = item[:entity]
    pts = definition_points(e.definition, memo)
    return nil if pts.empty?
    m = (item_chain(item) * e.transformation).to_a
    lo = hi = nil
    pts.each do |x, y, z|
      zz = m[2] * x + m[6] * y + m[10] * z + m[14]
      lo = zz if lo.nil? || zz < lo
      hi = zz if hi.nil? || zz > hi
    end
    [lo, hi]
  end

  # |determinant| of the 3x3 part of a transformation (volume scale factor)
  def self.det3(m)
    (m[0] * (m[5] * m[10] - m[6] * m[9]) -
     m[4] * (m[1] * m[10] - m[2] * m[9]) +
     m[8] * (m[1] * m[6] - m[2] * m[5])).abs
  end

  # Volume of the faces directly inside `entities` (a closed shape), else nil.
  # Divergence theorem: volume = sum( centroid . normal * area ) / 3
  def self.faces_volume(entities)
    faces = entities.grep(Sketchup::Face)
    return 0.0 if faces.empty?
    edges = entities.grep(Sketchup::Edge).select { |e| !e.faces.empty? }
    return nil unless edges.all? { |e| e.faces.size == 2 }

    total = 0.0
    faces.each do |f|
      n = f.normal
      mesh = f.mesh
      mesh.polygons.each do |poly|
        pts = poly.map { |i| mesh.point_at(i.abs) }
        next if pts.size < 3
        (1..pts.size - 2).each do |k|
          a = pts[0]
          b = pts[k]
          c = pts[k + 1]
          ab = [b.x.to_f - a.x.to_f, b.y.to_f - a.y.to_f, b.z.to_f - a.z.to_f]
          ac = [c.x.to_f - a.x.to_f, c.y.to_f - a.y.to_f, c.z.to_f - a.z.to_f]
          cx = ab[1] * ac[2] - ab[2] * ac[1]
          cy = ab[2] * ac[0] - ab[0] * ac[2]
          cz = ab[0] * ac[1] - ab[1] * ac[0]
          area = Math.sqrt(cx * cx + cy * cy + cz * cz) / 2.0
          mx = (a.x.to_f + b.x.to_f + c.x.to_f) / 3.0
          my = (a.y.to_f + b.y.to_f + c.y.to_f) / 3.0
          mz = (a.z.to_f + b.z.to_f + c.z.to_f) / 3.0
          total += (mx * n.x + my * n.y + mz * n.z) * area / 3.0
        end
      end
    end
    total.abs
  end

  # Volume (cubic inches, one unscaled instance) of a definition; nil if it is
  # not a closed solid. Cached until the definition's contents change.
  def self.definition_volume(d)
    b = d.bounds
    sig = [d.entities.length, b.min.to_a.map { |v| v.to_f.round(4) }, b.max.to_a.map { |v| v.to_f.round(4) }]
    @vol_cache ||= {}
    c = @vol_cache[d.entityID]
    return c[1] if c && c[0] == sig

    v = faces_volume(d.entities)
    unless v.nil?
      d.entities.each do |e|
        next unless e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
        cv = definition_volume(e.definition)
        if cv.nil?
          v = nil
          break
        end
        v += cv * det3(e.transformation.to_a)
      end
    end
    @vol_cache[d.entityID] = [sig, v]
    v
  end

  # Volume (cubic inches) of one item with every scale applied
  def self.item_volume(item)
    dv = definition_volume(item[:entity].definition)
    return nil if dv.nil?
    dv * det3((item_chain(item) * item[:entity].transformation).to_a)
  end

  # One data row per bulk instance (text as shown in the sheet)
  def self.build_bulk_rows(items, cols)
    memo = {}
    items.map do |it|
      e   = it[:entity]
      zr  = z_range(it, memo)
      vol = item_volume(it)
      vals = {}
      cols.each { |c| vals[c['id']] = e.get_attribute(DICT, c['id']).to_s }
      {
        'name'   => e.name.to_s,
        'volume' => (vol && vol > 1e-9) ? fmt_volume(vol) : "\u2014",
        'top'    => zr ? fmt(zr[1]) : '',
        'bot'    => zr ? fmt(zr[0]) : '',
        'vals'   => vals
      }
    end
  end

  def self.bulk_msg(text)
    @dialog.execute_script("bulkMsg(#{text.to_s.to_json})") if @dialog
  end

  # Rebuilds the bulk list and sends it to the window
  def self.push_bulk
    return unless @dialog

    @bulk_items = bulk_items
    cols = bulk_columns
    data = build_bulk_rows(@bulk_items, cols)
    @bulk_data = data
    @bulk_cols = cols

    info = sync_filter('bulk', @bulk_items, data)
    info['colors'].each_with_index { |c, i| data[i]['color'] = c } if info

    @dialog.execute_script("renderBulk(#{JSON.generate('cols' => cols, 'rows' => data, 'filter' => info)})")
  end

  # Updates volume / top / bottom of every row without redrawing the table
  def self.push_bulk_values
    return unless dialog_visible? && @bulk_items
    memo = {}
    arr = @bulk_items.map do |it|
      if it[:entity].valid?
        zr  = z_range(it, memo)
        vol = item_volume(it)
        {
          'volume' => (vol && vol > 1e-9) ? fmt_volume(vol) : "\u2014",
          'top'    => zr ? fmt(zr[1]) : '',
          'bot'    => zr ? fmt(zr[0]) : ''
        }
      else
        { 'volume' => '', 'top' => '', 'bot' => '' }
      end
    end
    @dialog.execute_script("setBulkOutputs(#{JSON.generate(arr)})")
  end

  # Stretches an item vertically (global Z) so that its top (:top) or bottom
  # (:bot) face lands on `target` (inches); the opposite face stays where it is.
  # Returns :ok, :same, :invalid, :flat or :empty.
  def self.stretch_item(item, which, target, memo)
    zr = z_range(item, memo)
    return :empty if zr.nil?
    zmin, zmax = zr
    h = zmax - zmin
    return :flat if h < 0.001

    if which == :top
      return :invalid if target <= zmin + 0.001
      s   = (target - zmin) / h
      ref = zmin
    else
      return :invalid if target >= zmax - 0.001
      s   = (zmax - target) / h
      ref = zmax
    end
    return :same if (s - 1.0).abs < 1e-9

    parent = item_chain(item)
    tg = Geom::Transformation.scaling(Geom::Point3d.new(0, 0, ref), 1.0, 1.0, s)
    item[:entity].transform!(parent.inverse * tg * parent)
    :ok
  end

  # Top / Bot Elevation typed in a cell: every chosen item is stretched
  def self.set_bulk_elevation(items, f, text)
    len = text.empty? ? nil : Sketchup.parse_length(text)
    if len.nil?
      push_bulk_values
      bulk_msg("'#{text}' is not a valid elevation.")
      return
    end

    target  = len.to_f
    memo    = {}
    counts  = Hash.new(0)
    model   = Sketchup.active_model
    model.start_operation(f == 'top' ? 'Set Top Elevation' : 'Set Bot Elevation', true)
    begin
      items.each do |it|
        if it[:entity].respond_to?(:locked?) && it[:entity].locked?
          counts[:locked] += 1
        else
          counts[stretch_item(it, f == 'top' ? :top : :bot, target, memo)] += 1
        end
      end
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not set the elevation: #{e.message}"
    end

    notes = []
    notes << "#{counts[:invalid]} instance(s) not changed: the #{f == 'top' ? 'top must stay above the bottom' : 'bottom must stay below the top'}." if counts[:invalid] > 0
    notes << "#{counts[:flat]} flat instance(s) cannot be stretched." if counts[:flat] > 0
    notes << "#{counts[:locked]} locked instance(s) skipped." if counts[:locked] > 0
    push_bulk_values
    bulk_msg(notes.join(' '))
  end

  # Instance name typed in a cell (must be unique)
  def self.rename_bulk(item, text)
    name = text.to_s.strip
    taken = bulk_items.any? do |it|
      !it[:entity].equal?(item[:entity]) && it[:entity].name.to_s.casecmp(name).zero?
    end
    if name.empty?
      push_bulk
      bulk_msg('The instance name cannot be empty.')
    elsif taken
      push_bulk
      bulk_msg("An instance named '#{name}' already exists.")
    else
      model = Sketchup.active_model
      model.start_operation('Rename instance', true)
      begin
        item[:entity].name = name
        model.commit_operation
      rescue => e
        model.abort_operation
        puts "Variable Database: could not rename: #{e.message}"
      end
      bulk_msg('')
    end
  end

  # Input column value typed in a cell: stored on every chosen instance
  def self.set_bulk_value(items, f, text)
    col = bulk_columns.find { |c| c['id'] == f }
    return unless col
    model = Sketchup.active_model
    model.start_operation("Set #{col['name']}", true)
    begin
      items.each do |it|
        if text.empty?
          it[:entity].delete_attribute(DICT, f)
        else
          it[:entity].set_attribute(DICT, f, text)
        end
      end
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not set #{col['name']}: #{e.message}"
    end
  end

  # msg: { rows: [indices], f: 'name' | 'top' | 'bot' | column id, v: value }
  def self.handle_bulk_edit(msg)
    f = msg['f'].to_s
    items = Array(msg['rows']).map { |i| @bulk_items && @bulk_items[i.to_i] }.compact
    items = items.select { |it| it[:entity].valid? }
    return push_bulk if items.empty?

    text = msg['v'].to_s.strip
    case f
    when 'name'        then rename_bulk(items.first, text)
    when 'top', 'bot'  then set_bulk_elevation(items, f, text)
    else                    set_bulk_value(items, f, text)
    end
    push_bulk_values
    push_filter_update('bulk')
  end

  # "Import Selection" on the Bulk Excavation sheet
  def self.bulk_import
    model = Sketchup.active_model
    sel   = model.selection
    if sel.empty?
      UI.messagebox('Select the geometry to import first, then click "Import Selection".')
      return
    end

    arr    = sel.to_a
    entity = (arr.size == 1 && container?(arr[0])) ? arr[0] : nil

    if entity
      if sheet_member?(entity)
        UI.messagebox('This geometry is already listed on another sheet of this database.')
        return
      end
      marked = (entity.is_a?(Sketchup::ComponentInstance) && entity.definition.get_attribute(DICT, 'mark')) ||
               entity.get_attribute(BOX_DICT, 'mark')
      if marked
        UI.messagebox('This is a mark from the Footing Schedule, so it is listed on the Footing Tabulation sheet.')
        return
      end
    end

    existing = bulk_items.map { |it| it[:entity].name.to_s.downcase }
    n = existing.size + 1
    n += 1 while existing.include?(format('be-%02d', n))
    default = format('BE-%02d', n)
    if entity && !entity.name.to_s.empty? && !existing.include?(entity.name.to_s.downcase)
      default = entity.name.to_s
    end

    name = nil
    loop do
      result = UI.inputbox(['Unique instance name'], [default], 'Import to Bulk Excavation')
      return unless result # cancelled
      name = result[0].to_s.strip
      if name.empty?
        UI.messagebox('The instance name cannot be empty.')
      elsif existing.include?(name.downcase)
        UI.messagebox("An instance named '#{name}' already exists. Choose another name.")
        default = name
      else
        break
      end
    end

    seq = (bulk_items.map { |it| it[:entity].get_attribute(DICT, 'bulk_seq').to_i }.max || 0) + 1

    model.start_operation('Import to Bulk Excavation', true)
    begin
      # several objects / loose faces and edges are wrapped in one group first
      entity ||= model.active_entities.add_group(arr)
      entity.name = name
      entity.set_attribute(DICT, 'bulk', true)
      entity.set_attribute(DICT, 'bulk_seq', seq)
      model.commit_operation
    rescue => e
      model.abort_operation
      UI.messagebox("Import failed: #{e.message}")
      return
    end

    sel.clear
    sel.add(entity)
    push_bulk
  end

  def self.safe_bulk_import
    bulk_import
  rescue => e
    puts "Variable Database bulk import failed: #{e.class}: #{e.message}"
    puts e.backtrace.first(8)
    UI.messagebox("Import failed: #{e.message}")
  end

  # The x on a row: the geometry stays in the model, it just leaves the sheet
  def self.remove_bulk_item(idx)
    item = @bulk_items && @bulk_items[idx.to_i]
    return unless item && item[:entity].valid?
    cols = bulk_columns
    model = Sketchup.active_model
    model.start_operation('Remove from Bulk Excavation', true)
    begin
      e = item[:entity]
      restore_material(model, e)
      e.delete_attribute(DICT, 'bulk')
      e.delete_attribute(DICT, 'bulk_seq')
      cols.each { |c| e.delete_attribute(DICT, c['id']) }
      model.commit_operation
    rescue => err
      model.abort_operation
      puts "Variable Database: could not remove the instance: #{err.message}"
    end
    push_bulk
  end

  # "+ Column" on the bulk sheet
  def self.add_bulk_column
    cols = bulk_columns
    n = cols.size + 1
    n += 1 while cols.any? { |c| c['name'].to_s.casecmp("Column #{n}").zero? }
    id = "c#{Time.now.to_i.to_s(36)}#{rand(36**3).to_s(36)}"

    model = Sketchup.active_model
    model.start_operation('Add column', true)
    begin
      save_bulk_columns(cols + [{ 'id' => id, 'name' => "Column #{n}" }])
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not add the column: #{e.message}"
    end
    push_bulk
  end

  def self.rename_bulk_column(msg)
    id   = msg['id'].to_s
    name = msg['name'].to_s.strip
    cols = bulk_columns
    col  = cols.find { |c| c['id'] == id }
    reserved = ['instance', 'volume', 'top elevation', 'bot elevation']

    if col.nil? || name.empty?
      push_bulk
    elsif reserved.include?(name.downcase) || cols.any? { |c| c['id'] != id && c['name'].to_s.casecmp(name).zero? }
      push_bulk
      bulk_msg("A column named '#{name}' already exists.")
    else
      model = Sketchup.active_model
      model.start_operation('Rename column', true)
      begin
        col['name'] = name
        save_bulk_columns(cols)
        model.commit_operation
      rescue => e
        model.abort_operation
        puts "Variable Database: could not rename the column: #{e.message}"
      end
      push_bulk
    end
  end

  def self.delete_bulk_column(id)
    cols = bulk_columns
    return unless cols.any? { |c| c['id'] == id }
    model = Sketchup.active_model
    model.start_operation('Delete column', true)
    begin
      bulk_items.each { |it| it[:entity].delete_attribute(DICT, id) if it[:entity].valid? }
      save_bulk_columns(cols.reject { |c| c['id'] == id })
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not delete the column: #{e.message}"
    end
    push_bulk
  end

  def self.export_bulk_csv
    path = UI.savepanel('Export Bulk Excavation', nil, 'bulk_excavation.csv')
    return unless path
    path += '.csv' unless path.downcase.end_with?('.csv')

    push_bulk
    cols = @bulk_cols || bulk_columns
    CSV.open(path, 'w') do |csv|
      csv << ['Instance', 'Volume', 'Top Elevation', 'Bot Elevation', 'Upper Perimeter', 'Height'] + cols.map { |c| c['name'] }
      (@bulk_data || []).each do |r|
        csv << [r['name'], r['volume'], r['top'], r['bot']] + cols.map { |c| r['vals'][c['id']] }
      end
    end
    UI.messagebox("Exported to:\n#{path}")
  rescue => e
    UI.messagebox("Export failed: #{e.message}")
  end

  # ===========================================================================
  # Miscellaneous sheet: an exact copy of Bulk Excavation (same columns, same
  # functions) for other geometries. Its instances carry the attribute
  # VariableDB/misc instead of VariableDB/bulk.
  # ===========================================================================

  def self.collect_misc_items(entities, path, out)
    entities.each do |e|
      next unless e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
      if e.get_attribute(DICT, 'misc')
        out << { entity: e, parents: path.dup }
      else
        collect_misc_items(e.definition.entities, path + [e], out)
      end
    end
  end

  def self.misc_items
    out = []
    collect_misc_items(Sketchup.active_model.entities, [], out)
    out.each_with_index
       .sort_by { |it, i| [it[:entity].get_attribute(DICT, 'misc_seq').to_i, i] }
       .map(&:first)
  end

  def self.misc_columns
    raw = Sketchup.active_model.get_attribute(DICT, 'misc_columns')
    cols = raw ? JSON.parse(raw) : []
    cols.is_a?(Array) ? cols : []
  rescue JSON::ParserError
    []
  end

  def self.save_misc_columns(cols)
    Sketchup.active_model.set_attribute(DICT, 'misc_columns', JSON.generate(cols))
  end

  def self.misc_msg(text)
    @dialog.execute_script("miscMsg(#{text.to_s.to_json})") if @dialog
  end

  def self.push_misc
    return unless @dialog

    @misc_items = misc_items
    cols = misc_columns
    data = build_bulk_rows(@misc_items, cols)
    @misc_data = data
    @misc_cols = cols

    info = sync_filter('misc', @misc_items, data)
    info['colors'].each_with_index { |c, i| data[i]['color'] = c } if info

    @dialog.execute_script("renderMisc(#{JSON.generate('cols' => cols, 'rows' => data, 'filter' => info)})")
  end

  def self.push_misc_values
    return unless dialog_visible? && @misc_items
    memo = {}
    arr = @misc_items.map do |it|
      if it[:entity].valid?
        zr  = z_range(it, memo)
        vol = item_volume(it)
        {
          'volume' => (vol && vol > 1e-9) ? fmt_volume(vol) : "\u2014",
          'top'    => zr ? fmt(zr[1]) : '',
          'bot'    => zr ? fmt(zr[0]) : ''
        }
      else
        { 'volume' => '', 'top' => '', 'bot' => '' }
      end
    end
    @dialog.execute_script("setMiscOutputs(#{JSON.generate(arr)})")
  end

  def self.set_misc_elevation(items, f, text)
    len = text.empty? ? nil : Sketchup.parse_length(text)
    if len.nil?
      push_misc_values
      misc_msg("'#{text}' is not a valid elevation.")
      return
    end

    target  = len.to_f
    memo    = {}
    counts  = Hash.new(0)
    model   = Sketchup.active_model
    model.start_operation(f == 'top' ? 'Set Top Elevation' : 'Set Bot Elevation', true)
    begin
      items.each do |it|
        if it[:entity].respond_to?(:locked?) && it[:entity].locked?
          counts[:locked] += 1
        else
          counts[stretch_item(it, f == 'top' ? :top : :bot, target, memo)] += 1
        end
      end
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not set the elevation: #{e.message}"
    end

    notes = []
    notes << "#{counts[:invalid]} instance(s) not changed: the #{f == 'top' ? 'top must stay above the bottom' : 'bottom must stay below the top'}." if counts[:invalid] > 0
    notes << "#{counts[:flat]} flat instance(s) cannot be stretched." if counts[:flat] > 0
    notes << "#{counts[:locked]} locked instance(s) skipped." if counts[:locked] > 0
    push_misc_values
    misc_msg(notes.join(' '))
  end

  def self.rename_misc(item, text)
    name = text.to_s.strip
    taken = misc_items.any? do |it|
      !it[:entity].equal?(item[:entity]) && it[:entity].name.to_s.casecmp(name).zero?
    end
    if name.empty?
      push_misc
      misc_msg('The instance name cannot be empty.')
    elsif taken
      push_misc
      misc_msg("An instance named '#{name}' already exists.")
    else
      model = Sketchup.active_model
      model.start_operation('Rename instance', true)
      begin
        item[:entity].name = name
        model.commit_operation
      rescue => e
        model.abort_operation
        puts "Variable Database: could not rename: #{e.message}"
      end
      misc_msg('')
    end
  end

  def self.set_misc_value(items, f, text)
    col = misc_columns.find { |c| c['id'] == f }
    return unless col
    model = Sketchup.active_model
    model.start_operation("Set #{col['name']}", true)
    begin
      items.each do |it|
        if text.empty?
          it[:entity].delete_attribute(DICT, f)
        else
          it[:entity].set_attribute(DICT, f, text)
        end
      end
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not set #{col['name']}: #{e.message}"
    end
  end

  def self.handle_misc_edit(msg)
    f = msg['f'].to_s
    items = Array(msg['rows']).map { |i| @misc_items && @misc_items[i.to_i] }.compact
    items = items.select { |it| it[:entity].valid? }
    return push_misc if items.empty?

    text = msg['v'].to_s.strip
    case f
    when 'name'        then rename_misc(items.first, text)
    when 'top', 'bot'  then set_misc_elevation(items, f, text)
    else                    set_misc_value(items, f, text)
    end
    push_misc_values
    push_filter_update('misc')
  end

  def self.misc_import
    model = Sketchup.active_model
    sel   = model.selection
    if sel.empty?
      UI.messagebox('Select the geometry to import first, then click "Import Selection".')
      return
    end

    arr    = sel.to_a
    entity = (arr.size == 1 && container?(arr[0])) ? arr[0] : nil

    if entity
      if sheet_member?(entity)
        UI.messagebox('This geometry is already listed on another sheet of this database.')
        return
      end
      marked = (entity.is_a?(Sketchup::ComponentInstance) && entity.definition.get_attribute(DICT, 'mark')) ||
               entity.get_attribute(BOX_DICT, 'mark')
      if marked
        UI.messagebox('This is a mark from the Footing Schedule, so it is listed on the Footing Tabulation sheet.')
        return
      end
    end

    existing = misc_items.map { |it| it[:entity].name.to_s.downcase }
    n = existing.size + 1
    n += 1 while existing.include?(format('ms-%02d', n))
    default = format('MS-%02d', n)
    if entity && !entity.name.to_s.empty? && !existing.include?(entity.name.to_s.downcase)
      default = entity.name.to_s
    end

    name = nil
    loop do
      result = UI.inputbox(['Unique instance name'], [default], 'Import to Miscellaneous')
      return unless result # cancelled
      name = result[0].to_s.strip
      if name.empty?
        UI.messagebox('The instance name cannot be empty.')
      elsif existing.include?(name.downcase)
        UI.messagebox("An instance named '#{name}' already exists. Choose another name.")
        default = name
      else
        break
      end
    end

    seq = (misc_items.map { |it| it[:entity].get_attribute(DICT, 'misc_seq').to_i }.max || 0) + 1

    model.start_operation('Import to Miscellaneous', true)
    begin
      # several objects / loose faces and edges are wrapped in one group first
      entity ||= model.active_entities.add_group(arr)
      entity.name = name
      entity.set_attribute(DICT, 'misc', true)
      entity.set_attribute(DICT, 'misc_seq', seq)
      model.commit_operation
    rescue => e
      model.abort_operation
      UI.messagebox("Import failed: #{e.message}")
      return
    end

    sel.clear
    sel.add(entity)
    push_misc
  end

  def self.safe_misc_import
    misc_import
  rescue => e
    puts "Variable Database misc import failed: #{e.class}: #{e.message}"
    puts e.backtrace.first(8)
    UI.messagebox("Import failed: #{e.message}")
  end

  def self.remove_misc_item(idx)
    item = @misc_items && @misc_items[idx.to_i]
    return unless item && item[:entity].valid?
    cols = misc_columns
    model = Sketchup.active_model
    model.start_operation('Remove from Miscellaneous', true)
    begin
      e = item[:entity]
      restore_material(model, e)
      e.delete_attribute(DICT, 'misc')
      e.delete_attribute(DICT, 'misc_seq')
      cols.each { |c| e.delete_attribute(DICT, c['id']) }
      model.commit_operation
    rescue => err
      model.abort_operation
      puts "Variable Database: could not remove the instance: #{err.message}"
    end
    push_misc
  end

  def self.add_misc_column
    cols = misc_columns
    n = cols.size + 1
    n += 1 while cols.any? { |c| c['name'].to_s.casecmp("Column #{n}").zero? }
    id = "c#{Time.now.to_i.to_s(36)}#{rand(36**3).to_s(36)}"

    model = Sketchup.active_model
    model.start_operation('Add column', true)
    begin
      save_misc_columns(cols + [{ 'id' => id, 'name' => "Column #{n}" }])
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not add the column: #{e.message}"
    end
    push_misc
  end

  def self.rename_misc_column(msg)
    id   = msg['id'].to_s
    name = msg['name'].to_s.strip
    cols = misc_columns
    col  = cols.find { |c| c['id'] == id }
    reserved = ['instance', 'volume', 'top elevation', 'bot elevation']

    if col.nil? || name.empty?
      push_misc
    elsif reserved.include?(name.downcase) || cols.any? { |c| c['id'] != id && c['name'].to_s.casecmp(name).zero? }
      push_misc
      misc_msg("A column named '#{name}' already exists.")
    else
      model = Sketchup.active_model
      model.start_operation('Rename column', true)
      begin
        col['name'] = name
        save_misc_columns(cols)
        model.commit_operation
      rescue => e
        model.abort_operation
        puts "Variable Database: could not rename the column: #{e.message}"
      end
      push_misc
    end
  end

  def self.delete_misc_column(id)
    cols = misc_columns
    return unless cols.any? { |c| c['id'] == id }
    model = Sketchup.active_model
    model.start_operation('Delete column', true)
    begin
      misc_items.each { |it| it[:entity].delete_attribute(DICT, id) if it[:entity].valid? }
      save_misc_columns(cols.reject { |c| c['id'] == id })
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not delete the column: #{e.message}"
    end
    push_misc
  end

  def self.export_misc_csv
    path = UI.savepanel('Export Miscellaneous', nil, 'miscellaneous.csv')
    return unless path
    path += '.csv' unless path.downcase.end_with?('.csv')

    push_misc
    cols = @misc_cols || misc_columns
    CSV.open(path, 'w') do |csv|
      csv << ['Instance', 'Volume', 'Top Elevation', 'Bot Elevation', 'Upper Perimeter', 'Height'] + cols.map { |c| c['name'] }
      (@misc_data || []).each do |r|
        csv << [r['name'], r['volume'], r['top'], r['bot']] + cols.map { |c| r['vals'][c['id']] }
      end
    end
    UI.messagebox("Exported to:\n#{path}")
  rescue => e
    UI.messagebox("Export failed: #{e.message}")
  end


  # Moves a schedule row (swap / reorder). msg: { from:, to:, field: (optional) }
  def self.move_row(msg)
    from = msg['from'].to_i
    to   = msg['to'].to_i
    r = rows
    return if from == to || from < 0 || to < 0 || from >= r.size || to >= r.size

    # remember which row was last clicked so it stays the same row after the move
    keep = (@selected_index && r[@selected_index]) ? r[@selected_index]['mark'] : nil

    model = Sketchup.active_model
    model.start_operation('Move row', true)
    begin
      row = r.delete_at(from)
      r.insert(to, row)
      save(r)
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not move the row: #{e.message}"
      return
    end

    @selected_index = r.index { |x| x['mark'] == keep } if keep

    push_all
    @dialog.execute_script("focusCell(#{to}, #{msg['field'].to_s.to_json})") if msg['field']
    push_tabulation # the tabulation follows the schedule order
  end

  # Update only the output cells of the schedule (does not disturb a cell being edited)
  def self.push_schedule_quantities
    return unless @dialog
    q = quantities
    arr = rows.map { |r| output_cells(r, q) }
    @dialog.execute_script("setOutputs(#{JSON.generate(arr)})")
  end

  # Refreshes the quantities and the tabulation (used by the placing tool etc.)
  def self.push_quantities
    with_quantity_snapshot do
      push_schedule_quantities
      push_tabulation
    end
  end

  # A value typed in an input cell: stored on every row it applies to
  # (msg: { rows: [indices], f: column id, v: value })
  def self.handle_tab_edit(msg)
    f = msg['f'].to_s
    return handle_toc_edit(msg) if f == 'toc'
    return handle_grid_edit(msg) if f == 'gridx' || f == 'gridy'

    col = tab_columns.find { |c| c['id'] == f }
    return unless col

    v = msg['v'].to_s.strip
    idxs = Array(msg['rows'] || msg['i']).map(&:to_i)
    items = idxs.map { |i| @tab_items && @tab_items[i] }.compact
    items = items.select { |it| it[:entity].valid? }
    return push_tabulation if items.empty?

    model = Sketchup.active_model
    model.start_operation("Set #{col['name']}", true)
    begin
      items.each do |it|
        if v.empty?
          it[:entity].delete_attribute(DICT, f)
        else
          it[:entity].set_attribute(DICT, f, v)
        end
      end
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not set #{col['name']}: #{e.message}"
    end
    push_filter_update # a changed value may change the colour
  end

  # An elevation typed in the TOC cell: every chosen component moves straight up
  # or down so that its highest point sits at that global Z
  def self.handle_toc_edit(msg)
    idxs  = Array(msg['rows'] || msg['i']).map(&:to_i)
    items = idxs.map { |i| @tab_items && @tab_items[i] }.compact.select { |it| it[:entity].valid? }
    text  = msg['v'].to_s.strip
    len   = text.empty? ? nil : Sketchup.parse_length(text)

    if items.empty? || len.nil?
      push_toc_values
      if len.nil? && @dialog
        @dialog.execute_script("tabMsg(#{"'#{text}' is not a valid elevation.".to_json})")
      end
      return
    end

    target = len.to_f
    memo   = {}
    locked = 0
    model  = Sketchup.active_model
    model.start_operation('Set TOC', true)
    begin
      items.each do |it|
        if it[:entity].respond_to?(:locked?) && it[:entity].locked?
          locked += 1
        else
          move_item_top_to(it, target, memo)
        end
      end
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not set TOC: #{e.message}"
    end

    push_toc_values
    push_filter_update
    note = locked > 0 ? "#{locked} locked component(s) were not moved." : ''
    @dialog.execute_script("tabMsg(#{note.to_json})") if @dialog
  end

  # Grid X / Grid Y typed by hand. Only components that no gridline cuts through
  # accept it; where a gridline does cut through, the gridline's label rules.
  def self.handle_grid_edit(msg)
    f     = msg['f'].to_s
    text  = msg['v'].to_s.strip
    idxs  = Array(msg['rows'] || msg['i']).map(&:to_i)
    items = idxs.map { |i| @tab_items && @tab_items[i] }.compact.select { |it| it[:entity].valid? }
    return push_toc_values if items.empty?

    axis = f == 'gridx' ? :x : :y
    key  = f == 'gridx' ? GRID_MANUAL_X : GRID_MANUAL_Y
    grid = grid_lines
    memo = {}
    skipped = 0

    model = Sketchup.active_model
    model.start_operation("Set #{f == 'gridx' ? 'Grid X' : 'Grid Y'}", true)
    begin
      items.each do |it|
        xr = xy_range(it, memo)
        hits = xr ? (axis == :x ? grid_hits(grid[:x], xr[0], xr[1]) : grid_hits(grid[:y], xr[2], xr[3])) : ''
        if hits.empty?
          if text.empty?
            it[:entity].delete_attribute(DICT, key)
          else
            it[:entity].set_attribute(DICT, key, text)
          end
        else
          skipped += 1 # a gridline cuts through it: the gridline's label is used
        end
      end
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not set #{f}: #{e.message}"
    end

    push_toc_values # also puts back the gridline label where a typed value was refused
    push_filter_update
    note = skipped > 0 ? "#{skipped} component(s) are cut by a gridline, so their label cannot be typed over." : ''
    @dialog.execute_script("tabMsg(#{note.to_json})") if @dialog
  end

  # "+ Column": a new input column
  def self.add_tab_column
    cols = tab_columns
    n = cols.size + 1
    n += 1 while cols.any? { |c| c['name'].to_s.casecmp("Column #{n}").zero? }
    id = "c#{Time.now.to_i.to_s(36)}#{rand(36**3).to_s(36)}"

    model = Sketchup.active_model
    model.start_operation('Add column', true)
    begin
      save_tab_columns(cols + [{ 'id' => id, 'name' => "Column #{n}" }])
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not add the column: #{e.message}"
    end
    push_tabulation
  end

  # Double-click a column name: rename it (the values stay)
  def self.rename_tab_column(msg)
    id   = msg['id'].to_s
    name = msg['name'].to_s.strip
    cols = tab_columns
    col  = cols.find { |c| c['id'] == id }

    if col.nil? || name.empty?
      push_tabulation
    elsif cols.any? { |c| c['id'] != id && c['name'].to_s.casecmp(name).zero? }
      push_tabulation
      @dialog.execute_script("tabMsg(#{"A column named '#{name}' already exists.".to_json})") if @dialog
    else
      model = Sketchup.active_model
      model.start_operation('Rename column', true)
      begin
        col['name'] = name
        save_tab_columns(cols)
        model.commit_operation
      rescue => e
        model.abort_operation
        puts "Variable Database: could not rename the column: #{e.message}"
      end
      push_tabulation
    end
  end

  # The x in a column header: removes the column and the values it holds
  def self.delete_tab_column(id)
    cols = tab_columns
    return unless cols.any? { |c| c['id'] == id }

    model = Sketchup.active_model
    model.start_operation('Delete column', true)
    begin
      tabulation_items.each do |it|
        it[:entity].delete_attribute(DICT, id) if it[:entity].valid?
      end
      save_tab_columns(cols.reject { |c| c['id'] == id })
      model.commit_operation
    rescue => e
      model.abort_operation
      puts "Variable Database: could not delete the column: #{e.message}"
    end
    push_tabulation
  end

  # ---- model selection -> highlighted rows ----
  class SelObserver < Sketchup::SelectionObserver
    def onSelectionBulkChange(_sel); VariableDB.selection_changed; end
    def onSelectionCleared(_sel); VariableDB.selection_changed; end
    def onSelectionAdded(_sel, _e); VariableDB.selection_changed; end
    def onSelectionRemoved(_sel, _e); VariableDB.selection_changed; end
  end

  # Fires when something in the model changes (a move, an undo, ...)
  class ModelObs < Sketchup::ModelObserver
    def onTransactionCommit(_model); VariableDB.model_changed; end
    def onTransactionUndo(_model); VariableDB.invalidate_filter; VariableDB.model_changed; end
    def onTransactionRedo(_model); VariableDB.invalidate_filter; VariableDB.model_changed; end
  end

  def self.attach_selection_observer
    detach_selection_observer
    @sel_obs   ||= SelObserver.new
    @model_obs ||= ModelObs.new
    @obs_selection = Sketchup.active_model.selection
    @obs_selection.add_observer(@sel_obs)
    @obs_model = Sketchup.active_model
    @obs_model.add_observer(@model_obs)
  rescue => e
    puts "Variable Database: could not watch the model: #{e.message}"
  end

  def self.detach_selection_observer
    @obs_selection.remove_observer(@sel_obs) if @obs_selection && @sel_obs
    @obs_model.remove_observer(@model_obs) if @obs_model && @model_obs
    @obs_selection = nil
    @obs_model = nil
  rescue => e
    puts "Variable Database: could not stop watching the model: #{e.message}"
  end

  # Called (in bursts) after any change in the model; refreshes once things settle
  def self.model_changed
    @quantity_snapshot = nil
    return unless dialog_visible?
    return if @chg_timer
    @chg_timer = UI.start_timer(0.4, false) do
      UI.stop_timer(@chg_timer) if @chg_timer
      @chg_timer = nil
      refresh_live
    end
  end

  # Updates the TOC cells (and the schedule outputs) after a change in the model.
  # If components were added / removed the whole tabulation is rebuilt instead.
  def self.refresh_live
    return unless dialog_visible?
    items = tabulation_items
    same = @tab_items && items.size == @tab_items.size &&
           items.each_with_index.all? { |it, i| it[:entity] == @tab_items[i][:entity] }
    if same
      push_toc_values
      push_filter_update
    else
      push_tabulation
    end
    push_schedule_quantities

    push_structural if @structural_items

    if @bulk_items # the bulk sheet has been opened
      bitems = bulk_items
      bsame = bitems.size == @bulk_items.size &&
              bitems.each_with_index.all? { |it, i| it[:entity] == @bulk_items[i][:entity] }
      if bsame
        push_bulk_values
        push_filter_update('bulk')
      else
        push_bulk
      end
    end

    if @misc_items # the misc sheet has been opened
      bitems = misc_items
      bsame = bitems.size == @misc_items.size &&
              bitems.each_with_index.all? { |it, i| it[:entity] == @misc_items[i][:entity] }
      if bsame
        push_misc_values
        push_filter_update('misc')
      else
        push_misc
      end
    end
  end

  # Sends the current TOC, Grid X and Grid Y of every row (does not touch the cell being typed in)
  def self.push_toc_values
    return unless dialog_visible? && @tab_items
    memo = {}
    grid = grid_lines
    arr = @tab_items.map do |it|
      e = it[:entity]
      next { 'toc' => '', 'gridx' => '', 'gridy' => '', 'gx_auto' => false, 'gy_auto' => false } unless e.valid?
      z  = toc_z(it, memo)
      xr = xy_range(it, memo)
      gx = xr ? grid_hits(grid[:x], xr[0], xr[1]) : ''
      gy = xr ? grid_hits(grid[:y], xr[2], xr[3]) : ''
      {
        'toc'     => z ? fmt(z) : '',
        'gridx'   => gx.empty? ? e.get_attribute(DICT, GRID_MANUAL_X).to_s : gx,
        'gridy'   => gy.empty? ? e.get_attribute(DICT, GRID_MANUAL_Y).to_s : gy,
        'gx_auto' => !gx.empty?,
        'gy_auto' => !gy.empty?
      }
    end
    @dialog.execute_script("setToc(#{JSON.generate(arr)})")
  end

  # Called (many times in a burst) when the model selection changes
  def self.selection_changed
    return unless dialog_visible?
    return if @sel_timer
    @sel_timer = UI.start_timer(0.15, false) do
      UI.stop_timer(@sel_timer) if @sel_timer
      @sel_timer = nil
      push_picked
    end
  end

  # Highlights, in the sheet, the rows whose component is selected in the model
  def self.push_picked(force = false)
    return unless dialog_visible?
    return if !force && @suppress_picked_until && Time.now < @suppress_picked_until

    sel = Sketchup.active_model.selection
    { 'setPicked' => @tab_items, 'setBulkPicked' => @bulk_items, 'setMiscPicked' => @misc_items, 'setStructuralPicked' => @structural_items }.each do |fn, items|
      next unless items
      idx = []
      items.each_with_index do |it, i|
        idx << i if it[:entity].valid? && sel.include?(it[:entity])
      end
      @dialog.execute_script("#{fn}(#{JSON.generate(idx)})")
    end
  end

  # Selects the chosen components in the model (opens their context first)
  def self.select_items(indices, zoom, source = @tab_items, msg_fn = 'tabMsg')
    items = indices.map { |i| source && source[i.to_i] }.compact
    items = items.select { |it| it[:entity].valid? }
    return if items.empty?

    @suppress_picked_until = Time.now + 0.8 # the sheet already shows this selection

    model   = Sketchup.active_model
    parents = items.first[:parents]
    same    = items.select { |it| it[:parents] == parents }
    wanted  = parents.empty? ? nil : parents

    if (model.active_path || []) != (wanted || [])
      begin
        model.active_path = wanted
      rescue => e
        puts "Variable Database: could not open the context: #{e.message}"
      end
    end

    model.selection.clear
    same.each { |it| model.selection.add(it[:entity]) }
    if zoom
      # View#zoom accepts entities or a zoom factor, not a Geom::BoundingBox.
      # Frame the selected entities first, then zoom out to retain context.
      view = model.active_view
      view.zoom(same.map { |it| it[:entity] })
      view.zoom(0.4)
    end

    skipped = items.size - same.size
    msg = skipped > 0 ? "#{same.size} selected. #{skipped} lie inside other groups/components and were not selected; select them separately." : ''
    @dialog.execute_script("#{msg_fn}(#{msg.to_json})") if @dialog
  end

  def self.export_tabulation_csv
    path = UI.savepanel('Export Footing Tabulation', nil, 'footing_tabulation.csv')
    return unless path
    path += '.csv' unless path.downcase.end_with?('.csv')

    push_tabulation
    cols = @tab_cols || tab_columns
    CSV.open(path, 'w') do |csv|
      csv << ['Component', 'Mark'] + cols.map { |c| c['name'] } + ['TOC', 'Grid X', 'Grid Y']
      (@tab_data || []).each do |r|
        csv << [r['component'], r['mark']] + cols.map { |c| r['vals'][c['id']] } + [r['toc'], r['gridx'], r['gridy']]
      end
    end
    UI.messagebox("Exported to:\n#{path}")
  rescue => e
    UI.messagebox("Export failed: #{e.message}")
  end

  def self.refresh
    return unless @dialog && @dialog.visible?
    attach_selection_observer # the model may have changed
    with_quantity_snapshot do
      push_all
      push_tabulation
    end
  end

  # ---------------------------------------------------------------------------
  # Dialog
  # ---------------------------------------------------------------------------
  def self.show
    if @dialog && @dialog.visible?
      @dialog.bring_to_front
      push_all
      return
    end

    @dialog = UI::HtmlDialog.new(
      dialog_title:    MENU_NAME,
      scrollable:      true,
      resizable:       true,
      width:           900,
      height:          460,
      min_width:       680,
      min_height:      280,
      style:           UI::HtmlDialog::STYLE_DIALOG
    )
    @dialog.set_file(File.join(__dir__, 'ui', 'dialog.html'))

    @dialog.add_action_callback('ready') { |_ctx| ensure_definitions; push_widths; push_all }

    @dialog.add_action_callback('refresh') { |_ctx| push_schedule_quantities }
    @dialog.add_action_callback('move_row') { |_ctx, payload| move_row(JSON.parse(payload)) }
    @dialog.add_action_callback('col_widths') { |_ctx, payload| save_col_widths(JSON.parse(payload)) }

    # Footing Tabulation sheet
    @dialog.add_action_callback('tab_refresh') { |_ctx| push_tabulation }
    @dialog.add_action_callback('tab_edit') { |_ctx, payload| handle_tab_edit(JSON.parse(payload)) }
    @dialog.add_action_callback('tab_select') do |_ctx, payload|
      m = JSON.parse(payload)
      select_items(m['rows'] || [], m['zoom'])
    end
    @dialog.add_action_callback('tab_add_col') { |_ctx| add_tab_column }
    @dialog.add_action_callback('label_grid') { |_ctx| defer(:label_grid) { safe_label_grid } }
    @dialog.add_action_callback('tab_rename_col') { |_ctx, payload| rename_tab_column(JSON.parse(payload)) }
    @dialog.add_action_callback('tab_delete_col') { |_ctx, id| delete_tab_column(id.to_s) }
    @dialog.add_action_callback('tab_picked') { |_ctx| push_picked(true) }
    @dialog.add_action_callback('clear_sheet_selection') do |_ctx|
      @suppress_picked_until = Time.now + 0.8
      Sketchup.active_model.selection.clear
    end
    @dialog.add_action_callback('tab_filter') { |_ctx, col| set_filter('tab', col.to_s) }

    # Bulk Excavation sheet
    @dialog.add_action_callback('structural_refresh') { |_ctx| push_structural }
    @dialog.add_action_callback('structural_export') { |_ctx| defer(:structural_export) { export_structural_csv } }
    @dialog.add_action_callback('structural_generate') { |_ctx| defer(:structural_generate) { generate_structural_excavation } }
    @dialog.add_action_callback('structural_berm') { |_ctx| defer(:structural_berm) { generate_structural_berm } }
    @dialog.add_action_callback('structural_edit') { |_ctx, payload| handle_structural_edit(JSON.parse(payload)) }
    @dialog.add_action_callback('structural_delete_rows') do |_ctx, payload|
      delete_structural_rows(JSON.parse(payload))
    end
    @dialog.add_action_callback('structural_add_col') { |_ctx| add_structural_column }
    @dialog.add_action_callback('structural_rename_col') { |_ctx, payload| rename_structural_column(JSON.parse(payload)) }
    @dialog.add_action_callback('structural_delete_col') { |_ctx, id| delete_structural_column(id.to_s) }
    @dialog.add_action_callback('structural_filter') { |_ctx, col| set_filter('structural', col.to_s) }
    @dialog.add_action_callback('structural_select') do |_ctx, payload|
      m = JSON.parse(payload)
      select_items(m['rows'] || [], m['zoom'], @structural_items, 'structuralMsg')
    end
    @dialog.add_action_callback('bulk_refresh') { |_ctx| push_bulk }
    @dialog.add_action_callback('bulk_import') { |_ctx| defer(:bulk_import) { safe_bulk_import } }
    @dialog.add_action_callback('bulk_edit') { |_ctx, payload| handle_bulk_edit(JSON.parse(payload)) }
    @dialog.add_action_callback('bulk_select') do |_ctx, payload|
      m = JSON.parse(payload)
      select_items(m['rows'] || [], m['zoom'], @bulk_items, 'bulkMsg')
    end
    @dialog.add_action_callback('bulk_remove') { |_ctx, idx| remove_bulk_item(idx) }
    @dialog.add_action_callback('bulk_add_col') { |_ctx| add_bulk_column }
    @dialog.add_action_callback('bulk_rename_col') { |_ctx, payload| rename_bulk_column(JSON.parse(payload)) }
    @dialog.add_action_callback('bulk_delete_col') { |_ctx, id| delete_bulk_column(id.to_s) }
    @dialog.add_action_callback('bulk_filter') { |_ctx, col| set_filter('bulk', col.to_s) }
    @dialog.add_action_callback('bulk_export') { |_ctx| defer(:bulk_export) { export_bulk_csv } }

    # Miscellaneous sheet
    @dialog.add_action_callback('misc_refresh') { |_ctx| push_misc }
    @dialog.add_action_callback('misc_import') { |_ctx| defer(:misc_import) { safe_misc_import } }
    @dialog.add_action_callback('misc_edit') { |_ctx, payload| handle_misc_edit(JSON.parse(payload)) }
    @dialog.add_action_callback('misc_select') do |_ctx, payload|
      m = JSON.parse(payload)
      select_items(m['rows'] || [], m['zoom'], @misc_items, 'miscMsg')
    end
    @dialog.add_action_callback('misc_remove') { |_ctx, idx| remove_misc_item(idx) }
    @dialog.add_action_callback('misc_add_col') { |_ctx| add_misc_column }
    @dialog.add_action_callback('misc_rename_col') { |_ctx, payload| rename_misc_column(JSON.parse(payload)) }
    @dialog.add_action_callback('misc_delete_col') { |_ctx, id| delete_misc_column(id.to_s) }
    @dialog.add_action_callback('misc_filter') { |_ctx, col| set_filter('misc', col.to_s) }
    @dialog.add_action_callback('misc_export') { |_ctx| defer(:misc_export) { export_misc_csv } }
    @dialog.add_action_callback('tab_export') do |_ctx|
      defer(:tab_export) { export_tabulation_csv }
    end

    # remembers the row the user last clicked (default mark for Place Mark)
    @dialog.add_action_callback('select_row') { |_ctx, idx| @selected_index = idx.to_i }

    # Modal boxes (inputbox / messagebox / savepanel) opened directly inside an
    # HtmlDialog callback can freeze SketchUp, so run them from a timer instead.
    @dialog.add_action_callback('import') do |_ctx|
      defer(:import) { safe_import }
    end

    @dialog.add_action_callback('add') do |_ctx|
      r = rows
      r << { 'mark' => next_mark(r), 'width' => 0.0, 'length' => 0.0,
             'thickness' => 0.0 }
      save(r)
      push_all
      @dialog.execute_script('focusLast()')
    end

    @dialog.add_action_callback('delete') do |_ctx, idx|
      r = rows
      i = idx.to_i
      if i >= 0 && i < r.size
        model = Sketchup.active_model
        model.start_operation('Delete mark', true)
        detach_definition(r[i]['mark']) # the component stays, no longer driven by the table
        delete_shape(r[i]['shape'])
        r.delete_at(i)
        save(r)
        model.commit_operation
      end
      push_all
    end

    @dialog.add_action_callback('clear_shape') do |_ctx, idx|
      r = rows
      i = idx.to_i
      if i >= 0 && i < r.size
        model = Sketchup.active_model
        model.start_operation('Remove shape', true)
        begin
          delete_shape(r[i]['shape'])
          r[i].delete('shape')
          r[i].delete('faces')
          save(r)
          sync_mark(r[i]['mark'], true) # the component becomes a plain box again
          model.commit_operation
        rescue => e
          model.abort_operation
          puts "Variable Database: could not remove the shape: #{e.message}"
        end
      end
      push_all
    end

    @dialog.add_action_callback('edit') do |_ctx, payload|
      handle_edit(JSON.parse(payload))
    end

    @dialog.add_action_callback('place_mark') do |_ctx|
      defer(:place_mark) { safe_place_mark }
    end

    @dialog.add_action_callback('export') do |_ctx|
      defer(:export) { export_csv }
    end

    @dialog.set_on_closed { detach_selection_observer }
    @dialog.show
    attach_selection_observer
  end

  def self.handle_edit(msg)
    i = msg['i'].to_i
    f = msg['f'].to_s
    v = msg['v'].to_s.strip
    r = rows
    return push_all if i < 0 || i >= r.size

    err = nil
    old_mark = r[i]['mark'].to_s

    if f == 'mark'
      if v.empty?
        err = 'Mark cannot be empty.'
      elsif r.each_with_index.any? { |x, k| k != i && x['mark'].to_s.casecmp(v).zero? }
        err = "Mark '#{v}' already exists."
      else
        r[i]['mark'] = v
      end
      shown = r[i]['mark'].to_s
    elsif NUMERIC.include?(f)
      len = Sketchup.parse_length(v)
      if len.nil?
        err = "'#{v}' is not a valid length for #{LABELS[f]}."
      elsif NON_NEG.include?(f) && len < 0
        err = "#{LABELS[f]} cannot be negative."
      else
        r[i][f] = len.to_f
      end
      shown = fmt(r[i][f])
    else
      return
    end

    unless err
      model = Sketchup.active_model
      model.start_operation("Edit #{r[i]['mark']}", true)
      begin
        save(r)
        if f == 'mark'
          rename_definition(old_mark, r[i]['mark'].to_s)
        else
          sync_mark(r[i]['mark'], true) # every instance in the model follows
        end
        model.commit_operation
      rescue => e
        model.abort_operation
        err = "Could not update the component: #{e.message}"
        stored = rows[i]
        shown = f == 'mark' ? old_mark : fmt(stored ? stored[f] : 0)
      end
    end
    @dialog.execute_script(
      "setCell(#{i},#{f.to_json},#{shown.to_json},#{err.to_json})"
    )
    # dimensions / mark changed: the output columns (forms, volume, quantity) follow
    push_quantities if err.nil?
  end

  def self.export_csv
    path = UI.savepanel('Export Footing Schedule', nil, 'footing_schedule.csv')
    return unless path
    path += '.csv' unless path.downcase.end_with?('.csv')

    CSV.open(path, 'w') do |csv|
      csv << ['Mark', 'Width', 'Length', 'Thickness', 'Shape', 'Side Forms', 'Soffit Forms', 'Volume', 'Quantity']
      display_rows.each do |r|
        csv << [r['mark'], r['width'], r['length'], r['thickness'], r['shape'],
                r['side'], r['soffit'], r['volume'], r['quantity']]
      end
    end
    UI.messagebox("Exported to:\n#{path}")
  rescue => e
    UI.messagebox("Export failed: #{e.message}")
  end

  # Refresh the table when the user switches / opens models
  class AppObs < Sketchup::AppObserver
    def onActivateModel(_model)
      VariableDB.refresh
    end

    def onOpenModel(_model)
      VariableDB.refresh
    end

    def onNewModel(_model)
      VariableDB.refresh
    end
  end

  # Register menu item and observer once
  unless file_loaded?('variable_database.rb:menu')
    UI.menu('Extensions').add_item(MENU_NAME) { VariableDB.show }
    Sketchup.add_observer(AppObs.new)
    file_loaded('variable_database.rb:menu')
  end
end
