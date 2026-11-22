# Project guidance

## Project overview
- This repository contains a SketchUp Ruby extension named Variable Database Tools.
- The extension entry point is `variable_tools.rb`; it registers the extension and loads `variable_tools/main.rb`.
- `variable_tools/main.rb` loads feature files in order. Keep `variable_database` first because other tools depend on it.
- The main interface and sheet behavior live in `variable_tools/variable_database.rb`. Other files implement individual modeling tools.

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
- No automated test suite is currently evident in the repository. For Ruby changes, inspect the affected code paths and perform an appropriate SketchUp smoke check when a SketchUp runtime is available.
- Do not claim a test passed unless it was actually run. For documentation-only changes, review the rendered Markdown and check the symlink target.
