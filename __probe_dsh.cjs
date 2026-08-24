const { createRequire } = require('node:module');
const path = require('node:path');

(async () => {
  console.log('node:', process.versions.node);
  const target = path.join(process.cwd(), 'node_modules', '@deepseek-ai', 'dsh', 'lib', 'bin.js');

  try {
    require(target);
    console.log('cjs-ok');
  } catch (e) {
    console.log('cjs-fail:', e.code, '-', e.message.split('\n')[0]);
  }

  try {
    await import(target);
    console.log('esm-ok');
  } catch (e) {
    console.log('esm-fail:', e.code, '-', e.message.split('\n')[0]);
  }
})();