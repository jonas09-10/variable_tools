function footingSchedule() {
  const fields = [
    { id: 'mark', name: 'Mark' },
    { id: 'width', name: 'Width' },
    { id: 'length', name: 'Length' },
    { id: 'thickness', name: 'Thickness' }
  ];
  const outputs = [
    { id: 'side', name: 'Side Forms', width: 100, title: 'Total area of the faces parallel to the global Z axis, one instance' },
    { id: 'soffit', name: 'Soffit Forms', width: 100, title: 'Total area of the bottom faces, one instance' },
    { id: 'volume', name: 'Volume', width: 100, title: 'Volume of one instance (— if it is not a closed solid)' },
    { id: 'quantity', name: 'Quantity', width: 80, title: 'Number of components of this mark in the model' }
  ];

  return {
    scheduleFields: fields,
    scheduleOutputs: outputs,
    scheduleColumns: [
      { id: 'handle', width: 26, title: 'Drag to reorder rows (or Alt+Up / Alt+Down)' },
      ...fields,
      { id: 'shape', name: 'Shape', width: 130, title: 'Imported geometry for this mark' },
      ...outputs.map((col) => Object.assign({ numeric: true }, col)),
      { id: 'delete', width: 34 }
    ],
    scheduleRows: [],
    scheduleRevision: 0,
    schedulePicked: null,
    scheduleMessage: '',
    scheduleError: {},
    dragFrom: null,
    dropAt: null,

    renderSchedule(rows) {
      this.scheduleRows = rows;
      this.scheduleRevision++;
      this.schedulePicked = null;
      this.scheduleError = {};
      this.scheduleMessage = '';
      this.endDrag();
    },

    pickScheduleRow(index, input) {
      input.select();
      this.schedulePicked = index;
      this.callRuby('select_row', index);
    },

    editScheduleCell(index, field, input) {
      this.sendJson('edit', { i: index, f: field, v: input.value });
    },

    setScheduleCell(index, field, value, error) {
      const row = this.scheduleRows[index];
      if (!row) return;
      row[field] = value;
      const input = this.scheduleInput(index, field);
      if (input) input.value = value;
      this.scheduleError = error ? { index, field } : {};
      this.scheduleMessage = error || '';
    },

    setScheduleOutputs(rows) {
      rows.slice(0, this.scheduleRows.length).forEach((row, index) => Object.assign(this.scheduleRows[index], row));
    },

    scheduleInput(index, field) {
      const row = document.getElementById('schedule-row-' + index);
      if (!row) return null;
      return row.querySelector(field ? 'input[data-field="' + field + '"]' : 'input');
    },

    focusScheduleCell(index, field) {
      this.$nextTick(() => {
        const input = this.scheduleInput(index, field);
        if (input) input.focus();
      });
    },

    scheduleKey(event, row, index, field) {
      const input = event.target;
      if (event.altKey && ['ArrowUp', 'ArrowDown'].includes(event.key)) {
        event.preventDefault();
        input.blur();
        const offset = event.key === 'ArrowDown' ? 1 : -1;
        this.sendJson('move_row', { from: index, to: index + offset, field });
      } else if (!this.navigate(event) && event.key === 'Escape') {
        input.value = row[field];
        input.blur();
      }
    },

    startDrag(event, index) {
      this.dragFrom = index;
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', String(index));
    },

    dragOver(event, index) {
      if (this.dragFrom === null) return;
      event.preventDefault();
      this.dropAt = index;
    },

    endDrag() {
      this.dragFrom = null;
      this.dropAt = null;
    },

    dropRow(event, index) {
      if (this.dragFrom === null) return;
      event.preventDefault();
      const from = this.dragFrom;
      this.endDrag();
      if (from !== index) this.sendJson('move_row', { from, to: index });
    },

    removeScheduleItem(action, row, index) {
      const label = action === 'clear_shape' ? 'the shape of' : 'row';
      if (confirm('Remove ' + label + ' "' + row.mark + '"?')) this.callRuby(action, index);
    }
  };
}
