import path from 'node:path';
import url from 'node:url';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const binPath = path.join(process.cwd(), 'node_modules', '@deepseek-ai', 'dsh', 'lib', 'bin.js');
console.log('bin file URL:', url.pathToFileURL(binPath).href);
console.log('exists?', require('node:fs').existsSync(binPath));