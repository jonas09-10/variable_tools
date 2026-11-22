const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '..');
function rubyFiles(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const name = path.join(dir, entry.name);
    return entry.isDirectory() ? rubyFiles(name) : entry.isFile() && name.endsWith('.rb') ? [name] : [];
  });
}
const files = [path.join(root, 'variable_tools.rb'), ...rubyFiles(path.join(root, 'variable_tools'))];
for (const file of files) {
  const result = spawnSync('ruby', ['-c', file], { encoding: 'utf8' });
  if (result.error) {
    console.error(`Cannot run Ruby syntax checks: ${result.error.message}. Install Ruby and ensure it is on PATH.`);
    process.exit(1);
  }
  if (result.status !== 0) {
    console.error(`${path.relative(root, file)}: ${result.stderr || result.stdout}`);
    process.exit(1);
  }
}
console.log(`Ruby syntax OK (${files.length} files)`);
