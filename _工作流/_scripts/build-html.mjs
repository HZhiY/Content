#!/usr/bin/env node
/**
 * 长文成稿 HTML 构建。正文来源唯一：06_成稿/终稿.md，标题来源：06_成稿/标题.md。
 * 纯格式转换，不改动任何文字——所以流程里不需要「正文与终稿一致」这道人工闸门。
 *
 *   node _工作流/_scripts/build-html.mjs "<项目路径>"
 *
 * 图文组形态请用系列自己的 _scripts/（如 一个人做产品/_scripts/batch_build_entries.mjs）。
 */

import fs from 'fs';
import path from 'path';

const projectDir = process.argv.slice(2).find((a) => !a.startsWith('--'));
if (!projectDir) {
  console.error('用法: node build-html.mjs "<项目路径>"');
  process.exit(2);
}

const ROOT = path.resolve(projectDir);
const SRC = path.join(ROOT, '06_成稿', '终稿.md');
const TITLE_FILE = path.join(ROOT, '06_成稿', '标题.md');
const OUT = path.join(ROOT, '06_成稿', '终稿.html');

if (!fs.existsSync(SRC)) {
  console.error(`找不到正文源：${SRC}`);
  process.exit(1);
}

// ---------- 标题 ----------

let title = null;
if (fs.existsSync(TITLE_FILE)) {
  const m = fs.readFileSync(TITLE_FILE, 'utf8').match(/##\s*已选标题\s*```text\s*([\s\S]*?)```/);
  if (m && !/待用户选择|待选/.test(m[1])) title = m[1].trim().split('\n')[0].trim();
}

const raw = fs.readFileSync(SRC, 'utf8');
if (!title) {
  const m = raw.match(/^#\s+(.+)$/m);
  title = m ? m[1].trim() : '未命名';
  console.warn('! 标题.md 里没有已选标题，暂用正文 H1');
}

// ---------- 取正文（去掉 H1 与顶部元信息引用块）----------

function bodyOf(md) {
  const lines = md.split(/\r?\n/);
  let i = 0;
  while (i < lines.length && !lines[i].trim()) i++;
  if (lines[i] && /^#\s/.test(lines[i])) i++;
  while (i < lines.length && (!lines[i].trim() || lines[i].trim().startsWith('>'))) i++;
  return lines.slice(i).join('\n');
}

// ---------- Markdown → HTML ----------

const esc = (s) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

function inline(text) {
  let s = esc(text);
  s = s.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, (_, alt, src) => `<img src="${src}" alt="${alt}">`);
  s = s.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>');
  s = s.replace(/`([^`]+)`/g, '<code>$1</code>');
  s = s.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  s = s.replace(/(?<!\*)\*([^*\n]+)\*(?!\*)/g, '<em>$1</em>');
  return s;
}

function render(md) {
  const out = [];
  const lines = md.split(/\r?\n/);
  let i = 0;
  let listType = null;

  const closeList = () => {
    if (listType) {
      out.push(`</${listType}>`);
      listType = null;
    }
  };

  while (i < lines.length) {
    const line = lines[i];
    const t = line.trim();

    if (!t) {
      closeList();
      i++;
      continue;
    }

    if (/^(---+|\*\*\*+)$/.test(t)) {
      closeList();
      out.push('<hr>');
      i++;
      continue;
    }

    const h = t.match(/^(#{1,4})\s+(.*)$/);
    if (h) {
      closeList();
      const level = Math.min(h[1].length + 1, 5); // 文内标题从 h2 起
      out.push(`<h${level}>${inline(h[2])}</h${level}>`);
      i++;
      continue;
    }

    if (t.startsWith('>')) {
      closeList();
      const buf = [];
      while (i < lines.length && lines[i].trim().startsWith('>')) {
        buf.push(lines[i].trim().replace(/^>\s?/, ''));
        i++;
      }
      out.push(`<blockquote>${inline(buf.join(' '))}</blockquote>`);
      continue;
    }

    if (t.startsWith('|')) {
      closeList();
      const rows = [];
      while (i < lines.length && lines[i].trim().startsWith('|')) {
        const cells = lines[i].trim().split('|').slice(1, -1).map((c) => c.trim());
        if (!/^[-: ]+$/.test(cells.join(''))) rows.push(cells);
        i++;
      }
      if (rows.length) {
        const [head, ...body] = rows;
        out.push('<div class="table-wrap"><table><thead><tr>');
        out.push(head.map((c) => `<th>${inline(c)}</th>`).join(''));
        out.push('</tr></thead><tbody>');
        for (const r of body) out.push(`<tr>${r.map((c) => `<td>${inline(c)}</td>`).join('')}</tr>`);
        out.push('</tbody></table></div>');
      }
      continue;
    }

    const ul = t.match(/^[-*+]\s+(.*)$/);
    const ol = t.match(/^\d+[.)]\s+(.*)$/);
    if (ul || ol) {
      const want = ul ? 'ul' : 'ol';
      if (listType !== want) {
        closeList();
        out.push(`<${want}>`);
        listType = want;
      }
      out.push(`<li>${inline((ul || ol)[1])}</li>`);
      i++;
      continue;
    }

    closeList();
    const buf = [];
    while (i < lines.length && lines[i].trim() && !/^([#>|]|---|\d+[.)]\s|[-*+]\s)/.test(lines[i].trim())) {
      buf.push(lines[i].trim());
      i++;
    }
    out.push(`<p>${inline(buf.join(''))}</p>`);
  }
  closeList();
  return out.join('\n');
}

const CSS = `*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{font-size:17px;-webkit-text-size-adjust:100%}
body{font-family:"PingFang SC","Microsoft YaHei","Helvetica Neue",sans-serif;
  background:#f7f7f5;color:#1a1a1a;line-height:1.85;-webkit-font-smoothing:antialiased}
.wrap{max-width:44rem;margin:0 auto;padding:2.5rem 1.25rem 4rem;background:#fff;min-height:100vh}
h1{font-size:1.6rem;font-weight:700;line-height:1.4;margin-bottom:1.75rem;color:#111}
h2{font-size:1.2rem;font-weight:700;margin:2.5rem 0 1rem;color:#111;
  padding-left:.7rem;border-left:4px solid #2563eb}
h3{font-size:1.05rem;font-weight:600;margin:1.75rem 0 .75rem;color:#222}
h4{font-size:1rem;font-weight:600;margin:1.5rem 0 .6rem;color:#333}
p{margin:0 0 1.15rem;text-align:justify;word-break:break-word}
strong{font-weight:600;color:#000}
em{font-style:normal;color:#2563eb}
a{color:#2563eb;text-decoration:none;border-bottom:1px solid #bfdbfe}
code{font-family:Consolas,Menlo,monospace;font-size:.88em;background:#f3f4f6;
  padding:.12em .4em;border-radius:3px;color:#c2410c}
blockquote{margin:1.5rem 0;padding:.9rem 1.1rem;background:#f8f9fa;
  border-left:3px solid #d1d5db;color:#4b5563;font-size:.95rem;line-height:1.75}
blockquote p{margin:0}
hr{border:0;height:1px;background:#e5e7eb;margin:2.5rem 0}
ul,ol{margin:0 0 1.15rem;padding-left:1.5rem}
li{margin-bottom:.5rem}
img{max-width:100%;height:auto;display:block;margin:1.75rem auto;border-radius:6px}
.table-wrap{overflow-x:auto;margin:1.5rem 0}
table{border-collapse:collapse;width:100%;font-size:.92rem}
th,td{border:1px solid #e5e7eb;padding:.55rem .7rem;text-align:left}
th{background:#f9fafb;font-weight:600}
.meta{font-size:.8rem;color:#9ca3af;margin-bottom:2rem;padding-bottom:1rem;border-bottom:1px solid #f0f0f0}
@media(max-width:480px){html{font-size:16px}.wrap{padding:1.75rem 1rem 3rem}}`;

const body = render(bodyOf(raw));
const charCount = (bodyOf(raw).match(/[\u4e00-\u9fa5]/g) || []).length;

const html = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(title)}</title>
<style>
${CSS}
</style>
</head>
<body>
<article class="wrap">
<h1>${esc(title)}</h1>
${body}
</article>
</body>
</html>
`;

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, html, 'utf8');

console.log(`✓ 已生成 ${OUT}`);
console.log(`  标题：${title}`);
console.log(`  正文：${charCount} 字`);
console.log('\n跑一次闸门确认正文一致：');
console.log(`  node _工作流/_scripts/check.mjs "${ROOT}" --gate=6`);
