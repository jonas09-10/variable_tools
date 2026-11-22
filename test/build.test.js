const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { unzipSync } = require('fflate');
const { build, output } = require('../scripts/build-rbz');

const root = path.resolve(__dirname, '..');
function sourceFiles(dir, prefix) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const file = path.join(dir, entry.name);
    const name = `${prefix}/${entry.name}`;
    return entry.isDirectory() ? sourceFiles(file, name) : [name];
  });
}
test('RBZ contains exactly the extension files with unchanged contents', () => {
  build();
  const archive = unzipSync(fs.readFileSync(output));
  const expected = ['variable_tools.rb', ...sourceFiles(path.join(root, 'variable_tools'), 'variable_tools')].sort();
  assert.deepEqual(Object.keys(archive).sort(), expected);
  for (const file of expected) assert.deepEqual(Buffer.from(archive[file]), fs.readFileSync(path.join(root, file)));
  assert.ok(archive['variable_tools/main.rb']);
});
