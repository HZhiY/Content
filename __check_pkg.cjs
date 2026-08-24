// Probe Node's module resolution for the absolute bin.js path
const path = require('node:path');
const fs = require('node:fs');

const binPath = path.resolve(process.argv[2]);
console.log('cwd:', process.cwd());
console.log('bin:', binPath);

const url = require('node:url').pathToFileURL(binPath).href;
console.log('bin URL:', url);

// Check expected location
const expected = path.join(path.dirname(binPath), 'node_modules', '@deepseek-ai', 'dsh-app-boot', 'package.json');
console.log('expected app-boot pkg:', expected, 'exists?', fs.existsSync(expected));

const nvm = 'C:/Users/aaa/AppData/Roaming/nvm/v12.11.0/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-app-boot/package.json';
console.log('nvm app-boot pkg:', nvm, 'exists?', fs.existsSync(nvm));