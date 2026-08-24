import { createRequire } from 'node:module';
import path from 'node:path';

const require = createRequire(import.meta.url);
console.log('node:', process.versions.node);

const target = path.join(process.cwd(), 'node_modules', '@deepseek-ai', 'dsh', 'lib', 'bin.js');

try {
  require(target);
  console.log('cjs-ok');
} catch (e) {
  console.log('cjs-fail:', e.code, e.message.split('\n')[0]);
}

try {
  const m = await import(target);
  console.log('esm-ok');
} catch (e) {
  console.log('esm-fail:', e.code, e.message.split('\n')[0]);
}