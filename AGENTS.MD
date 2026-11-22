# Project guidance

## Project overview

### Entry points and dependencies
- Variable Database Tools is a SketchUp extension targeting SketchUp 2019 / Ruby 2.5 according to its source headers. `variable_tools.rb` registers the extension; `variable_tools/main.rb` requires the feature files. Load `variable_database.rb` first: the other tools use its API. Preserve both the root loader and the `variable_tools/` directory when packaging an RBZ.
- `variable_tools/variable_database.rb` defines `VariableDB`: model storage, geometry helpers, five sheets, observers, the `UI::HtmlDialog`, and its embedded HTML/CSS/JavaScript. Its opening comments describe older behavior and say “two sheets”; check the implementation for current behavior.
- `box_from_mark.rb` is a compatibility wrapper for older `BoxFromMark.run` calls. `place_box_from_mark.rb` retains a menu command and delegates to the database's `PlaceTool`. Make placement changes in `variable_database.rb`.

### Data and component flow
- The active SketchUp model owns the `VariableDB` attribute dictionary. `rows` / `save` store schedule rows as JSON under `rows`; shape data is JSON under separate `shape_<id>` keys. Internal length values are inches. `all`, `find`, `definition`, `sync_mark`, `quantity`, `quantities`, `has_shape?`, and `build_shape` are public integration points; `find` returns lengths and a compatibility `elevation` of zero.
- A schedule mark is backed by a component definition. `sync_mark` builds or rebuilds a box or stored shape; changing dimensions affects its instances. `capture`, `gather`, orientation helpers, and `import_selection` turn selected geometry into a normalized reusable shape and tag its origin. `PlaceTool` places instances. `update_metrics` and `output_cells` calculate forms and volume; `tally_entities`, `quantities`, and `with_quantity_snapshot` calculate quantities, including nested and legacy tagged geometry.
- Instance sheet records are found by traversing model entities and retaining parent paths. Column definitions are stored on the model; user values and membership markers are stored on instances. Preserve dictionary keys and the meaning of stored values when changing these paths, since they persist in existing SKP files.

### Sheets and where to edit
- **Footing Schedule** is the mark database: edit `rows`, `handle_edit`, `sync_mark`, shape import, metrics, and schedule UI for mark dimensions, shapes, or quantities. `move_row` controls order; `export_csv` exports the schedule.
- **Footing Tabulation** lists individual mark instances. `collect_items`, `tabulation_items`, `build_tab_rows`, and `push_tabulation` build its rows. `handle_tab_edit` handles custom values; `toc_z`, `move_item_top_to`, and `handle_toc_edit` read and move top elevation. Grid labeling and intersections use `label_grid`, `grid_lines`, `grid_hits`, and `handle_grid_edit`. Column management is in the `*_tab_column` methods.
- **Bulk Excavation** tracks imported groups/components using `VariableDB/bulk`; **Miscellaneous** follows a parallel implementation using `VariableDB/misc`. Their `*_items`, `*_columns`, `build_bulk_rows`, import, edit, remove, and export methods control each sheet. Both use shared `z_range`, `item_volume`, and `stretch_item` helpers; changing a top or bottom elevation stretches the instance. Removing a row unregisters the entity and leaves geometry in the model.
- **Structural Excavation** finds generated instances marked `VariableDB/structural_excavation` through `structural_items`. `build_structural_rows`, `handle_structural_edit`, column methods, and `export_structural_csv` manage its table. `generate_structural_excavation` delegates to `ExcavationFromFooting.run(true)`; `generate_structural_berm` delegates to `InvertedTrapezoidBBox.run(true)`. These registration-enabled paths add generated geometry to the sheet. `delete_structural_rows` deletes the registered geometry, unlike bulk/misc row removal.
- Color by column is shared through `SHEET_JS`, `FILTER_PREFIXES`, `FILTER_ATTRS`, `sheet_items_fresh`, `sheet_columns`, `sync_filter`, and material restore helpers. Table column filters are implemented in the embedded JavaScript and hide rows rather than alter the model; CSV exports include all rows.

### UI and synchronization
- `show` creates the HtmlDialog, registers Ruby callbacks, and loads the `HTML` heredoc. JavaScript calls `sketchup.<callback>`; Ruby sends state back through `execute_script` and the `push_*` functions. For an interface change, trace both sides of that bridge, including payload fields and sheet-specific callbacks. `defer` schedules modal UI and other work outside callbacks to avoid SketchUp freezes.
- `SelObserver` and `ModelObs` feed `selection_changed` and `model_changed`; `push_picked`, `refresh_live`, and `select_items` coordinate model selection, row highlighting, refresh and zoom. `AppObs` handles model changes. For scroll or selection behavior inspect the embedded JavaScript as well as these Ruby methods; avoid feedback loops and stale cached item lists.

### Modeling tools
- `box_to_next_face.rb` (`BoxToNextFace`) clusters selections, finds an oriented frame, collects and clips candidate face polygons, then builds a box up to a limiting face. Look at `collect_polys`, `limit_z`, and `run` for face detection.
- `excavation_from_footing.rb` (`ExcavationFromFooting`) has similar clustering and face detection, plus `limit_z_over_footing`, `face_below?`, surface triangles, footprint sampling, `shaped_plan`, and `build_shaped_excavation` for stepped or irregular excavation. `cleanup_partition_edges` and `cleanup_extraneous_lines` remove redundant geometry. Inspect `run` for candidate filtering, validation and registration before changing detection.
- `inverted_trapezoid_bbox.rb` (`InvertedTrapezoidBBox`) clusters and orients selections and `build_collar` creates the hollow inverted trapezoid used for berms. `run` handles inputs and optional registration.
- `hollow_solid_intersection.rb` (`HollowSolidIntersection`) reduces a selected solid using the others, with Solid Tools availability and subtraction order checked by `detect_subtract_order`. Its geometry operations require SketchUp Pro Solid Tools.

## Editing rules
- Keep changes scoped to the requested behavior and preserve existing workflows across the database sheets and modeling tools.
- Follow the existing Ruby style and module/constant naming in the file being changed. Avoid introducing global methods or constants.
- Use the SketchUp Ruby API for model, entity, transformation, geometry, and UI operations. Keep API calls compatible with the SketchUp versions already targeted by the extension; do not assume newer Ruby or API methods without checking existing usage and compatibility.
- Treat model coordinates and transformations carefully. Account for nested groups/components and instance transformations when traversing or modifying geometry.
- Wrap user-visible model edits in SketchUp operations so they can be undone, and ensure operations are committed or aborted on every path.
- Preserve extension loading conventions, `file_loaded?` guards, and `variable_tools/main.rb` dependency order when adding or moving features.
- Keep generated geometry valid and clean up temporary entities when an operation completes or fails.
- Preserve user data such as attributes, tags, materials, names, and sheet registrations unless the requested change explicitly affects them.
- Keep UI labels and messages consistent with the existing Variable Database terminology.

## Verification
- Run `npm ci` to install build dependencies, `npm test` for archive and Ruby syntax checks, and `build.bat` on Windows to produce `dist/variable_tools.rbz` without Node. `npm run build` invokes the same batch file. The archive test runs on Windows. Ruby must be on PATH for syntax checks. These checks do not replace a SketchUp smoke check; use Ruby 2.5 to check the oldest supported syntax.
- Do not claim a test passed unless it was actually run. For documentation-only changes, review the rendered Markdown and check the symlink target.
