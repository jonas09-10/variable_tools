const fs = require('node:fs');
const path = require('node:path');
const { zipSync } = require('fflate');

const root = path.resolve(__dirname, '..');
const output = path.join(root, 'dist', 'variable_tools.rbz');

function collect(directory, archive, files) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    const diskPath = path.join(directory, entry.name);
    const zipPath = `${archive}/${entry.name}`;
    if (entry.isDirectory()) collect(diskPath, zipPath, files);
    else if (entry.isFile()) files[zipPath] = fs.readFileSync(diskPath);
    else throw new Error(`Unsupported extension entry: ${diskPath}`);
  }
}

function build() {
  const files = { 'variable_tools.rb': fs.readFileSync(path.join(root, 'variable_tools.rb')) };
  collect(path.join(root, 'variable_tools'), 'variable_tools', files);
  if (!files['variable_tools/main.rb']) throw new Error('Missing variable_tools/main.rb');
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, zipSync(files, { level: 6 }));
  console.log(`Built ${path.relative(root, output)}`);
}
if (require.main === module) build();
module.exports = { build, output };
