const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { unzipSync } = require('fflate');
const { execFileSync } = require('node:child_process');
const output = path.join(__dirname, '..', 'dist', 'variable_tools.rbz');

const root = path.resolve(__dirname, '..');
function sourceFiles(dir, prefix) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const file = path.join(dir, entry.name);
    const name = `${prefix}/${entry.name}`;
    return entry.isDirectory() ? sourceFiles(file, name) : [name];
  });
}
test('RBZ contains exactly the extension files with unchanged contents', { skip: process.platform !== 'win32' }, () => {
  execFileSync('cmd.exe', ['/d', '/s', '/c', 'build.bat'], { cwd: root });
  const archive = unzipSync(fs.readFileSync(output));
  const expected = ['variable_tools.rb', ...sourceFiles(path.join(root, 'variable_tools'), 'variable_tools')].sort();
  assert.deepEqual(Object.keys(archive).sort(), expected);
  for (const file of expected) assert.deepEqual(Buffer.from(archive[file]), fs.readFileSync(path.join(root, file)));
  assert.ok(archive['variable_tools/main.rb']);

  const dialogPath = 'variable_tools/ui/dialog.html';
  assert.ok(archive[dialogPath], 'Missing the Variable Database dialog');
  const html = Buffer.from(archive[dialogPath]).toString('utf8');
  for (const [, asset] of html.matchAll(/<(?:link|script)\b[^>]*\b(?:href|src)="([^"]+)"/g)) {
    if (/^https?:\/\//.test(asset)) continue;
    const archivePath = path.posix.join(path.posix.dirname(dialogPath), asset);
    assert.ok(archive[archivePath], `Missing dialog asset: ${archivePath}`);
  }
});
