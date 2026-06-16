const fs = require('fs');
const path = 'c:\\Users\\27649\\Documents\\myproject\\Content\\美国如何从工业国变成金融国\\10_为什么美联储像是从摩根图书馆里长出来的\\02_洞察及主题\\传播学审查卡.md';
const content = fs.readFileSync(path, 'utf8');
const cnOnly = content.match(/[\u4e00-\u9fff]/g) || [];
const cnPunct = content.match(/[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef]/g) || [];
console.log('Total chars:', content.length);
console.log('Chinese chars only:', cnOnly.length);
console.log('Chinese + punctuation:', cnPunct.length);