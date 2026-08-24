import { pathToFileURL } from 'node:url';
const binUrl = pathToFileURL(process.argv[2]).href;
console.log('importing:', binUrl);
try {
  await import(binUrl);
  console.log('bin ok');
} catch (e) {
  console.log('bin err:', e.code, '-', e.message.split('\n')[0]);
}