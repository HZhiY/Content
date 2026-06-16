const fs = require('fs');
const path = process.argv[2];
const content = fs.readFileSync(path, 'utf8');
const cnMatches = content.match(/[一-龥]/g) || [];
console.log('汉字数：' + cnMatches.length);
console.log('字符总数（含标点）：' + content.length);