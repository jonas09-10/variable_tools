// The Play CDN uses newer syntax than SketchUp 2019's browser supports.
// The jsDelivr mirror serves the same bytes with the CORS headers SRI requires.
if (window.CSS && CSS.supports('selector(:is(*))')) {
  const tailwind = document.createElement('script');
  tailwind.crossOrigin = 'anonymous';
  tailwind.integrity = 'sha384-igm5BeiBt36UU4gqwWS7imYmelpTsZlQ45FZf+XBn9MuJbn4nQr7yx1yFydocC/K';
  tailwind.src = 'https://cdn.jsdelivr.net/npm/unpack-tailwindcss-3.4.17@3.4.17/dist/tailwindcss-3.4.17.js';
  document.head.appendChild(tailwind);
}

function instanceSheets() {
  const action = (id, name, title) => ({ id, name, title });
  const column = (id, name, width, options) => Object.assign({ id, name, width }, options);
  const numeric = (title, edit) => ({ numeric: true, title, edit });
  const color = { id: 'swatch', width: 24 };
  const remove = { id: 'remove', width: 34 };
  const name = column('name', 'Instance', 170, { edit: true, title: 'Unique instance name (edit a cell to rename it)' });
  const volume = column('volume', 'Volume', 100, numeric('Volume of the instance (— if it is not a closed solid)'));
  const elevations = (editable) => [
    column('top', 'Top Elevation', 110, numeric(editable
      ? 'Type an elevation to stretch the upper face while the bottom stays in place.' : 'Global Z of the upper face.', editable)),
    column('bot', 'Bot Elevation', 110, numeric(editable
      ? 'Type an elevation to stretch the lower face while the top stays in place.' : 'Global Z of the lower face.', editable))
  ];
  const imported = [
    color, name, volume, ...elevations(true), 'custom', remove
  ];
  const importAction = action('import', 'Import Selection', 'Add the selected geometry as one unique instance');
  return [
    {
      id: 'tab',
      name: 'Footing Tabulation',
      actions: [action('label_grid', 'Label Grid', 'Select edges or guide lines in the model, then label them for Grid X and Grid Y')],
      columns: [
        column('component', 'Component', 200),
        column('mark', 'Mark', 80),
        'custom',
        column('toc', 'TOC', 110, numeric('Top of concrete. Type an elevation to move the component there.', true)),
        column('gridx', 'Grid X', 90, { grid: 'gx_auto', edit: true, numeric: true }),
        column('gridy', 'Grid Y', 90, { grid: 'gy_auto', edit: true, numeric: true })
      ],
      empty: 'No components found. Use Place Mark or copy a mark’s component in SketchUp.'
    },
    {
      id: 'bulk',
      name: 'Bulk Excavation',
      actions: [importAction],
      columns: imported,
      empty: 'No instances yet. Select geometry in the model and click Import Selection.'
    },
    {
      id: 'structural',
      name: 'Structural Excavation',
      actions: [
        action('generate', 'Generate Excavation', 'Generate a shaped excavation from selected footings'),
        action('berm', 'Generate Berm', 'Create a hollow inverted trapezoid around the selected geometry')
      ],
      columns: [
        color, name, volume, ...elevations(false),
        column('perimeter', 'Upper Perimeter', 90, numeric('Perimeter of the upper face of the world-axis-aligned bounding box.')),
        column('height', 'Height', 90, numeric('Highest minus lowest global Z elevation.')),
        'custom', remove
      ],
      empty: 'No structural excavations or berms yet. Select geometry and click Generate Excavation or Generate Berm.'
    },
    {
      id: 'misc',
      name: 'Miscellaneous',
      actions: [importAction],
      columns: imported,
      empty: 'No instances yet. Select geometry in the model and click Import Selection.'
    }
  ].map((sheet) => Object.assign(sheet, {
    baseColumns: sheet.columns,
    columns: sheet.columns.filter((col) => col !== 'custom'),
    rows: [],
    filters: Object.create(null),
    options: Object.create(null),
    visible: {},
    picked: new Set(),
    lastPicked: null,
    colorBy: 'none',
    legend: [],
    message: '',
    count: 0,
    renaming: null,
    revision: 0,
    outputRevision: 0
  }));
}

document.addEventListener('alpine:init', () => {
  Alpine.data('variableDatabase', () => Object.assign({
    active: 'schedule',
    widths: {},
    sheets: instanceSheets(),

    init() {
      const callbacks = {
        render: (rows) => this.renderSchedule(rows),
        setCell: (...args) => this.setScheduleCell(...args),
        setOutputs: (rows) => this.setScheduleOutputs(rows),
        focusCell: (index, field) => this.focusScheduleCell(index, field),
        focusLast: () => this.focusScheduleCell(this.scheduleRows.length - 1),
        setWidths: (widths) => { this.widths = widths; }
      };
      this.sheets.forEach((sheet) => {
        const suffix = sheet.id === 'tab' ? '' : sheet.id[0].toUpperCase() + sheet.id.slice(1);
        callbacks[suffix ? 'render' + suffix : 'renderTab'] = (data) => this.renderSheet(sheet, data);
        callbacks['set' + suffix + 'Picked'] = (rows) => this.setPicked(sheet, rows);
        callbacks['set' + suffix + 'Filter'] = (filter) => this.setColorFilter(sheet, filter);
        callbacks[sheet.id + 'Msg'] = (message) => { sheet.message = message; };
        if (sheet.id === 'tab') {
          callbacks.setToc = (rows) => this.setSheetOutputs(sheet, rows);
        } else if (sheet.id !== 'structural') {
          callbacks['set' + suffix + 'Outputs'] = (rows) => this.setSheetOutputs(sheet, rows);
        }
      });
      // SketchUp's execute_script calls these by name after the ready handshake.
      Object.assign(window, callbacks);
      this.$nextTick(() => this.callRuby('ready'));
    },

    callRuby(name, value) {
      if (!window.sketchup) return;
      if (value === undefined) window.sketchup[name]();
      else window.sketchup[name](value);
    },

    sendJson(name, value) {
      this.callRuby(name, JSON.stringify(value));
    },

    switchSheet(id) {
      this.active = id;
      if (id !== 'schedule') this.callRuby(id + '_refresh');
    },

    refreshSheet() {
      if (document.activeElement.tagName === 'INPUT') return;
      this.callRuby(this.active === 'schedule' ? 'refresh' : this.active + '_refresh');
    },

    columnWidth(id, col) {
      return (this.widths[id] && this.widths[id][col.id]) || col.width || 90;
    },

    tableWidth(id, columns) {
      return columns.reduce((sum, col) => sum + this.columnWidth(id, col), 0) + 'px';
    },

    resizeColumn(event, id, col) {
      const startX = event.clientX;
      const startWidth = this.columnWidth(id, col);
      if (!this.widths[id]) this.widths[id] = {};
      const move = (e) => {
        this.widths[id][col.id] = Math.max(40, startWidth + e.clientX - startX);
      };
      const finish = () => {
        document.removeEventListener('mousemove', move);
        this.sendJson('col_widths', { sheet: id, widths: this.widths[id] });
      };
      document.addEventListener('mousemove', move);
      document.addEventListener('mouseup', finish, { once: true });
    },

    navigate(event) {
      const input = event.target;
      const down = event.key === 'ArrowDown' || (event.key === 'Enter' && !event.shiftKey);
      if (!down && event.key !== 'ArrowUp' && event.key !== 'Enter') return false;
      event.preventDefault();
      const cell = input.parentElement;
      let row = cell.parentElement;
      do {
        row = down ? row.nextElementSibling : row.previousElementSibling;
      } while (row && (row.tagName !== 'TR' || row.style.display === 'none'));
      const next = row && row.cells[cell.cellIndex] && row.cells[cell.cellIndex].querySelector('input');
      if (next) next.focus();
      else input.blur();
      return true;
    },

    renderSheet(sheet, data) {
      const custom = (data.cols || []).map((col) => Object.assign({ custom: true, edit: true }, col));
      sheet.columns = sheet.baseColumns.flatMap((col) => col === 'custom' ? custom : [col]);
      sheet.rows = data.rows || [];
      sheet.picked = new Set();
      sheet.lastPicked = null;
      sheet.message = '';
      sheet.renaming = null;
      sheet.revision++;
      this.setColorFilter(sheet, data.filter);
      this.rebuildFilters(sheet);
      this.$nextTick(() => this.callRuby('tab_picked'));
    },

    cellValue(row, col) {
      const value = col.custom ? (row.vals || {})[col.id] : row[col.id];
      return value == null ? '' : String(value);
    },

    rebuildFilters(sheet) {
      const options = Object.create(null);
      sheet.columns.filter((col) => col.name).forEach((col) => {
        options[col.id] = [...new Set(sheet.rows.map((row) => this.cellValue(row, col)))];
        options[col.id].sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
      });
      Object.keys(sheet.filters).forEach((id) => {
        if (!options[id] || !options[id].includes(sheet.filters[id])) delete sheet.filters[id];
      });
      sheet.options = options;
      this.applyFilters(sheet);
    },

    applyFilters(sheet) {
      const filters = sheet.columns.filter((col) => this.hasFilter(sheet, col));
      const visible = {};
      sheet.rows.forEach((row, index) => {
        if (filters.every((col) => this.cellValue(row, col) === sheet.filters[col.id])) visible[index] = true;
      });
      sheet.visible = visible;
      sheet.count = Object.keys(visible).length;
      sheet.picked.forEach((index) => {
        if (!visible[index]) sheet.picked.delete(index);
      });
    },

    hasFilter(sheet, col) {
      return Object.prototype.hasOwnProperty.call(sheet.filters, col.id);
    },

    changeFilter(sheet, col, value) {
      // Prefix real values so even a blank or a literal "All" has its own option.
      if (value === '') delete sheet.filters[col.id];
      else sheet.filters[col.id] = value.slice(1);
      this.applyFilters(sheet);
    },

    setColorFilter(sheet, filter) {
      sheet.colorBy = filter ? filter.col : 'none';
      sheet.legend = filter ? filter.legend : [];
      if (filter) {
        sheet.rows.forEach((row, index) => { row.color = filter.colors[index]; });
      }
    },

    selectRows(sheet, rows, zoom = false) {
      sheet.picked = new Set(rows);
      if (rows.length) this.sendJson(sheet.id + '_select', { rows, zoom });
    },

    clickRow(sheet, index, event, fromInput = false) {
      if (!fromInput && event.target.closest('input, button')) return;
      let rows = [index];
      if (event.shiftKey && sheet.lastPicked !== null) {
        const start = Math.min(sheet.lastPicked, index);
        const end = Math.max(sheet.lastPicked, index);
        rows = Object.keys(sheet.visible).map(Number).filter((i) => i >= start && i <= end);
      } else {
        if (event.ctrlKey || event.metaKey) {
          rows = sheet.picked.has(index)
            ? [...sheet.picked].filter((i) => i !== index) : [...sheet.picked, index].sort((a, b) => a - b);
        }
        sheet.lastPicked = index;
      }
      this.selectRows(sheet, rows);
    },

    selectFromInput(sheet, index, event) {
      if (sheet.id === 'tab' || !(event.ctrlKey || event.metaKey || event.shiftKey)) return;
      event.preventDefault();
      this.clickRow(sheet, index, event, true);
    },

    selectVisible(sheet) {
      this.selectRows(sheet, Object.keys(sheet.visible).map(Number));
    },

    clearPicked(sheet) {
      sheet.picked.clear();
      sheet.lastPicked = null;
      this.callRuby('clear_sheet_selection');
    },

    setPicked(sheet, rows) {
      const next = rows.find((index) => sheet.visible[index] && !sheet.picked.has(index));
      sheet.picked = new Set(rows);
      if (this.active !== sheet.id || next === undefined) return;
      this.$nextTick(() => {
        if (this.active !== sheet.id) return;
        const row = document.getElementById(sheet.id + '-row-' + next);
        if (row && row.getClientRects().length) row.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'nearest' });
      });
    },

    editCell(sheet, index, col, input) {
      if (input.readOnly) return;
      const targets = col.id !== 'name' && sheet.picked.has(index)
        ? [...sheet.picked].filter((i) => sheet.visible[i]) : [index];
      // SketchUp supplies canonical values for elevations and manual grid labels.
      if (!col.grid && !['toc', 'top', 'bot'].includes(col.id)) {
        targets.forEach((i) => {
          const row = sheet.rows[i];
          if (col.custom) row.vals[col.id] = input.value;
          else row[col.id] = input.value;
        });
        this.rebuildFilters(sheet);
      }
      this.sendJson(sheet.id + '_edit', { rows: targets, f: col.id, v: input.value });
    },

    syncSheetInput(input, value) {
      // A live update leaves the active editor alone.
      if (document.activeElement !== input && input.value !== value) input.value = value;
    },

    setSheetOutputs(sheet, rows) {
      let changed = false;
      rows.slice(0, sheet.rows.length).forEach((row, index) => {
        const current = sheet.rows[index];
        Object.keys(row).forEach((key) => {
          if (current[key] === row[key]) return;
          current[key] = row[key];
          changed = true;
        });
      });
      // Reapply even unchanged canonical values after SketchUp rejects an edit.
      sheet.outputRevision++;
      if (changed) this.rebuildFilters(sheet);
    },

    finishRename(sheet, col, name) {
      if (sheet.renaming !== col.id) return;
      sheet.renaming = null;
      const trimmed = name.trim();
      if (trimmed && trimmed !== col.name) this.sendJson(sheet.id + '_rename_col', { id: col.id, name: trimmed });
    },

    deleteColumn(sheet, col) {
      if (confirm('Delete the column "' + col.name + '" and its stored values?')) {
        this.callRuby(sheet.id + '_delete_col', col.id);
      }
    },

    removeInstance(sheet, index) {
      const name = sheet.rows[index].name;
      if (sheet.id === 'structural') {
        if (confirm('Permanently delete "' + name + '" and its generated excavation/berm geometry? You can Undo in SketchUp.')) {
          this.sendJson('structural_delete_rows', [index]);
        }
      } else if (confirm('Remove "' + name + '" from this sheet? The geometry stays in the model.')) {
        this.callRuby(sheet.id + '_remove', index);
      }
    },

    deletePickedStructural(sheet) {
      const rows = [...sheet.picked].filter((index) => sheet.visible[index]);
      if (!rows.length) {
        sheet.message = 'Select one or more visible rows first.';
        return;
      }
      if (confirm('Delete ' + rows.length + ' selected excavation/berm instance(s) AND their SketchUp geometry? You can Undo in SketchUp.')) {
        this.sendJson('structural_delete_rows', rows);
      }
    }
  }, footingSchedule()));
});
