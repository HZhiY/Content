#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');

const CARD_STYLE = `    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html { font-size: 16px; }
    body {
      font-family: "PingFang SC", "Microsoft YaHei", "Helvetica Neue", sans-serif;
      background: linear-gradient(180deg, #f0f2f5 0%, #e8eaed 100%);
      color: #1a1a1a; line-height: 1.6; -webkit-font-smoothing: antialiased; min-height: 100vh;
    }
    .preview-wrap { max-width: 420px; margin: 0 auto; padding: 1.5rem 1rem 3rem; }
    .header { text-align: center; margin-bottom: 1.75rem; }
    .series-tag {
      display: inline-block; font-size: 0.72rem; color: #666; background: #fff;
      border: 1px solid #e0e0e0; border-radius: 999px; padding: 0.25rem 0.75rem;
      margin-bottom: 0.85rem;
    }
    h1 { font-size: 1.35rem; font-weight: 700; color: #111; line-height: 1.35; margin-bottom: 0.45rem; }
    .subtitle { font-size: 0.95rem; color: #2563eb; font-weight: 500; }
    .entry-label { font-size: 0.78rem; color: #888; margin-bottom: 1rem; }
    .cards-grid { display: flex; flex-direction: column; gap: 1.25rem; }
    .card-item { display: flex; flex-direction: column; gap: 0.5rem; }
    .card-label { font-size: 0.75rem; font-weight: 600; color: #555; }
    .card-label span { color: #2563eb; margin-right: 0.35rem; }
    .card-frame { position: relative; width: 100%; aspect-ratio: 3 / 4; border-radius: 12px; overflow: hidden;
      box-shadow: 0 4px 20px rgba(0,0,0,0.08); background: #fff; }
    .card-frame img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; display: none; }
    .card-frame.has-image img { display: block; }
    .card-frame.has-image .card-fallback { display: none; }
    .card-fallback { position: absolute; inset: 0; display: flex; flex-direction: column;
      padding: 1.5rem 1.25rem; background: #fff; overflow: hidden; }
    .card-fallback.cover { justify-content: center; background: linear-gradient(165deg, #fafafa, #f5f5f5); }
    .page-num { position: absolute; bottom: 1rem; right: 1.1rem; font-size: 0.68rem; color: #bbb; }
    .cover-line1 { font-size: 1.25rem; font-weight: 700; color: #2563eb; margin-bottom: 0.65rem; }
    .cover-line2 { font-size: 1.05rem; font-weight: 600; color: #1a1a1a; }
    .card-body { font-size: 0.88rem; line-height: 1.65; color: #222; display: flex; flex-direction: column; gap: 0.55rem; }
    .card-body p { margin: 0; }
    .flow-arrow { color: #2563eb; font-weight: 500; }
    code { font-family: Consolas, monospace; font-size: 0.82em; background: #f3f4f6; padding: 0.1em 0.35em; border-radius: 3px; color: #c2410c; }
    .caption-section { margin-top: 1.75rem; padding: 1.1rem; background: #fff; border-radius: 10px; border: 1px solid #e8e8e8; }
    .caption-section h2 { font-size: 0.78rem; color: #888; margin-bottom: 0.65rem; }
    .caption-section p { font-size: 0.85rem; line-height: 1.75; color: #333; }
    .footer-note { margin-top: 1.5rem; text-align: center; font-size: 0.68rem; color: #aaa; }`;

const PROMPT_STYLE =
  'Vertical 3:4 note card, off-white or cream background, minimalist product-doc aesthetic, NOT a marketing poster. Black body text, blue accent on titles, orange for example labels. Clean sans-serif, mobile-friendly. No photos, no stickers, no training-course aesthetics.';

function esc(s) {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function inlineCode(text) {
  return text.split(/(`[^`]+`)/).map((part) => {
    if (part.startsWith('`') && part.endsWith('`')) {
      return `<code>${esc(part.slice(1, -1))}</code>`;
    }
    return esc(part);
  }).join('');
}

function coverHtml(line1, line2) {
  return `<p class="cover-line1">${inlineCode(line1)}</p><p class="cover-line2">${inlineCode(line2)}</p>`;
}

function cardBodyHtml(text, isCover, coverOverride) {
  if (isCover && coverOverride) {
    return coverHtml(coverOverride.line1, coverOverride.line2);
  }
  const lines = text.split('\n').map((l) => l.trim()).filter(Boolean);
  if (isCover) {
    if (lines.length >= 2) return coverHtml(lines[0], lines[1]);
    return `<p class="cover-line1">${inlineCode(lines[0] || '')}</p>`;
  }
  return lines
    .map((ln) => {
      if (ln.startsWith('→')) {
        return `<p><span class="flow-arrow">→</span> ${inlineCode(ln.replace(/^→\s*/, ''))}</p>`;
      }
      return `<p>${inlineCode(ln)}</p>`;
    })
    .join('\n                ');
}

function parseEntries(md) {
  const entries = [];
  const blocks = md.split(/\n## 图文 (\d+)｜/);
  for (let i = 1; i < blocks.length; i += 2) {
    const num = parseInt(blocks[i], 10);
    const body = blocks[i + 1];
    const titleLine = body.split('\n')[0].trim();
    const cards = [];
    const cardRe = /### (图 \d+｜[^\n]+)\n\n([\s\S]*?)(?=\n### |\n---|\Z)/g;
    let m;
    while ((m = cardRe.exec(body)) !== null) {
      cards.push({ label: m[1], text: m[2].trim() });
    }
    const capM = body.match(/### caption\n\n([\s\S]*?)(?=\n---|\n## |\Z)/);
    entries.push({ num, title: titleLine, cards, caption: capM ? capM[1].trim() : '' });
  }
  return entries;
}

function buildHtml(entry, meta, theme) {
  const nn = String(entry.num).padStart(2, '0');
  const total = entry.cards.length;
  const cover = { line1: meta.cover_line1, line2: meta.cover_line2 };
  const cardsHtml = entry.cards
    .map((card, i) => {
      const ci = String(i + 1).padStart(2, '0');
      const isCover = i === 0;
      const fallbackCls = isCover ? 'card-fallback cover' : 'card-fallback';
      const body = cardBodyHtml(card.text, isCover, isCover ? cover : null);
      const img = `../08_插图/images/card_${nn}_${ci}.png`;
      return `
        <article class="card-item">
          <p class="card-label"><span>${ci}</span>${esc(card.label)}</p>
          <div class="card-frame">
            <img src="${img}" alt="${esc(card.label)}">
            <div class="${fallbackCls}">
              <div class="card-body">${body}</div>
              <span class="page-num">${ci} / ${String(total).padStart(2, '0')}</span>
            </div>
          </div>
        </article>`;
    })
    .join('');

  return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${esc(meta.note_title)}</title>
  <style>${CARD_STYLE}</style>
</head>
<body>
  <div class="preview-wrap">
    <header class="header">
      <div class="series-tag">一个人做产品 · 图文 ${nn}</div>
      <h1>${esc(meta.note_title)}</h1>
      <p class="subtitle">${esc(meta.work_title)}</p>
    </header>
    <section class="entry-group">
      <p class="entry-label">主题包：${esc(theme)} · ${total} 张卡片</p>
      <div class="cards-grid">${cardsHtml}
      </div>
    </section>
    <section class="caption-section"><h2>Caption</h2><p>${inlineCode(entry.caption)}</p></section>
    <p class="footer-note">小红书图文预览 · 08_插图/images/card_${nn}_01–${String(total).padStart(2, '0')}.png</p>
  </div>
  <script>
    document.querySelectorAll('.card-frame img').forEach(img => {
      const onLoad = () => { if (img.naturalWidth > 0) img.parentElement.classList.add('has-image'); };
      img.addEventListener('load', onLoad);
      img.addEventListener('error', () => { img.style.display = 'none'; });
      if (img.complete && img.naturalWidth > 0) onLoad();
    });
  </script>
</body>
</html>`;
}

function buildCoverPrompt(meta, total) {
  return `${PROMPT_STYLE} Large bold Chinese text exactly: 「${meta.cover_line1}」 on first line in blue accent, second line 「${meta.cover_line2}」 in black. Generous whitespace, page number 「01 / ${String(total).padStart(2, '0')}」 bottom-right.`;
}

function buildCardPrompt(card, nn, ci, total) {
  const text = card.text.replace(/\n/g, ' newline ');
  return `${PROMPT_STYLE} Chinese text exactly: ${text}. Page number 「${ci} / ${String(total).padStart(2, '0')}」 bottom-right.`;
}

const mdPath = process.argv[2];
const range = process.argv[3] || '01-10';
const [rStart, rEnd] = range.split('-').map(Number);
const wanted = new Set();
for (let n = rStart; n <= rEnd; n++) wanted.add(n);

const absMd = path.isAbsolute(mdPath) ? mdPath : path.join(ROOT, mdPath);
const packDir = path.dirname(path.dirname(absMd));
const outDir = path.join(packDir, '09_终稿');
const promptsPath = path.join(packDir, '08_插图', 'prompts.json');
const titlesPath = path.join(packDir, '07_传播终审与标题', '标题方案_全包.json');

const md = fs.readFileSync(absMd, 'utf8').replace(/\r\n/g, '\n');
const titlePack = JSON.parse(fs.readFileSync(titlesPath, 'utf8'));
const entries = parseEntries(md);

let existing = {};
if (fs.existsSync(promptsPath)) {
  existing = JSON.parse(fs.readFileSync(promptsPath, 'utf8'));
}
const imageMap = new Map((existing.images || []).map((x) => [x.id, x]));

fs.mkdirSync(outDir, { recursive: true });

for (const entry of entries) {
  if (!wanted.has(entry.num)) continue;
  const nn = String(entry.num).padStart(2, '0');
  const meta = titlePack.entries[nn];
  if (!meta) throw new Error(`Missing title meta for entry ${nn}`);

  const htmlPath = path.join(outDir, `${nn}_终稿.html`);
  fs.writeFileSync(htmlPath, buildHtml(entry, meta, '网站上线基础设施'), 'utf8');
  console.log('Wrote', htmlPath);

  const total = entry.cards.length;
  entry.cards.forEach((card, i) => {
    const ci = String(i + 1).padStart(2, '0');
    const id = `card_${nn}_${ci}`;
    const isCover = i === 0;
    imageMap.set(id, {
      id,
      filename: `${id}.png`,
      position: `图文${nn} / ${card.label}`,
      function: card.label,
      description_cn: isCover ? `${meta.cover_line1} / ${meta.cover_line2}` : card.text.slice(0, 120),
      prompt: isCover ? buildCoverPrompt(meta, total) : buildCardPrompt(card, nn, ci, total),
      aspect_ratio: '3:4',
    });
  });
}

const allImages = [...imageMap.values()].sort((a, b) => a.id.localeCompare(b.id));
fs.writeFileSync(
  promptsPath,
  JSON.stringify(
    {
      ...existing,
      article_id: '01-10',
      article_entry: '网站上线基础设施全包',
      series: '一个人做产品',
      theme_pack: '01_网站上线基础设施',
      images: allImages,
    },
    null,
    2,
  ) + '\n',
  'utf8',
);
console.log('Updated prompts.json, total images:', allImages.length);
