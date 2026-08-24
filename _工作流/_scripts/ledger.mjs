#!/usr/bin/env node
/**
 * 表现台账。读 _工作流/_反馈/原始数据.tsv，算派生指标和百分位，写 _工作流/_反馈/表现台账.md。
 * 每次录入新数据后重跑一次。
 *
 *   node _工作流/_scripts/ledger.mjs
 *   node _工作流/_scripts/ledger.mjs --stats   （只打印统计，不写文件）
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const FB = path.resolve(__dirname, '..', '_反馈');
const SRC = path.join(FB, '原始数据.tsv');
const OUT = path.join(FB, '表现台账.md');
const statsOnly = process.argv.includes('--stats');

const rows = fs
  .readFileSync(SRC, 'utf8')
  .trim()
  .split(/\r?\n/)
  .slice(1)
  .map((line) => {
    const [日期, 系列, 标题, 展现量, 阅读量, 点击率, 阅读时长, 点赞, 评论, 收益] = line.split('\t');
    const [mm, ss] = 阅读时长.split(':').map(Number);
    const 阅读 = +阅读量;
    return {
      日期,
      系列,
      标题,
      展现量: +展现量,
      阅读量: 阅读,
      点击率: +点击率,
      时长秒: mm * 60 + ss,
      阅读时长,
      点赞: +点赞,
      评论: +评论,
      收益: +收益,
      点赞率: 阅读 ? (+点赞 / 阅读) * 100 : 0,
      评论率: 阅读 ? (+评论 / 阅读) * 100 : 0,
    };
  });

/** 百分位：该值在全部样本中排第几（0-100，越高越好） */
function pct(values, v) {
  const below = values.filter((x) => x < v).length;
  return Math.round((below / (values.length - 1)) * 100);
}

const ctrs = rows.map((r) => r.点击率);
const durs = rows.map((r) => r.时长秒);
const likes = rows.map((r) => r.点赞率);

for (const r of rows) {
  r.ctrP = pct(ctrs, r.点击率);
  r.durP = pct(durs, r.时长秒);
  r.likeP = pct(likes, r.点赞率);
  r.期 = r.日期.slice(0, 7);
}

// 期内百分位：账号权重与平台分发在不同时期差异极大，跨期比较无效。
// 诊断一律用期内百分位。
for (const 期 of new Set(rows.map((r) => r.期))) {
  const rs = rows.filter((r) => r.期 === 期);
  if (rs.length < 3) {
    for (const r of rs) {
      r.ctrPin = null;
      r.durPin = null;
    }
    continue;
  }
  const c = rs.map((x) => x.点击率);
  const d = rs.map((x) => x.时长秒);
  for (const r of rs) {
    r.ctrPin = pct(c, r.点击率);
    r.durPin = pct(d, r.时长秒);
  }
}

/** 按发布密度自动分期：相邻发布间隔中位数变化处切分 */
function splitPhases(rows) {
  const byDate = [...rows].sort((a, b) => a.日期.localeCompare(b.日期));
  const phases = new Map();
  for (const r of byDate) {
    const month = r.日期.slice(0, 7);
    if (!phases.has(month)) phases.set(month, []);
    phases.get(month).push(r);
  }
  return phases;
}

const phases = splitPhases(rows);

const fmt = (n, d = 1) => n.toFixed(d);
const median = (a) => {
  const s = [...a].sort((x, y) => x - y);
  return s.length % 2 ? s[(s.length - 1) / 2] : (s[s.length / 2 - 1] + s[s.length / 2]) / 2;
};

// ---------- 统计输出 ----------

const lines = [];
const say = (s = '') => lines.push(s);

say('## 分期（按月）');
say('');
say('| 月份 | 篇数 | 发文间隔 | 展现量中位 | 点击率中位 | 阅读时长中位 | 点赞率中位 |');
say('|---|---:|---:|---:|---:|---:|---:|');
for (const [month, rs] of [...phases].sort()) {
  const days = new Set(rs.map((r) => r.日期)).size;
  const span = 30 / Math.max(rs.length, 1);
  say(
    `| ${month} | ${rs.length} | ${fmt(span, 1)} 天/篇 | ${median(rs.map((r) => r.展现量)).toLocaleString()} | ${fmt(median(rs.map((r) => r.点击率)))}% | ${Math.round(median(rs.map((r) => r.时长秒)))}s | ${fmt(median(rs.map((r) => r.点赞率)), 2)}% |`
  );
}

say('');
say('## 点击率与展现量的关系');
say('');
const buckets = [
  ['≥10%', (r) => r.点击率 >= 10],
  ['5-10%', (r) => r.点击率 >= 5 && r.点击率 < 10],
  ['2-5%', (r) => r.点击率 >= 2 && r.点击率 < 5],
  ['<2%', (r) => r.点击率 < 2],
];
say('| 点击率区间 | 篇数 | 展现量中位 | 展现量最大 |');
say('|---|---:|---:|---:|');
for (const [name, f] of buckets) {
  const rs = rows.filter(f);
  if (!rs.length) continue;
  say(
    `| ${name} | ${rs.length} | ${median(rs.map((r) => r.展现量)).toLocaleString()} | ${Math.max(...rs.map((r) => r.展现量)).toLocaleString()} |`
  );
}

say('');
say('## 分系列');
say('');
say('| 系列 | 篇数 | 点击率中位 | 阅读时长中位 | 点赞率中位 | 评论率中位 |');
say('|---|---:|---:|---:|---:|---:|');
const bySeries = new Map();
for (const r of rows) {
  if (!bySeries.has(r.系列)) bySeries.set(r.系列, []);
  bySeries.get(r.系列).push(r);
}
for (const [s, rs] of bySeries) {
  say(
    `| ${s} | ${rs.length} | ${fmt(median(rs.map((r) => r.点击率)))}% | ${Math.round(median(rs.map((r) => r.时长秒)))}s | ${fmt(median(rs.map((r) => r.点赞率)), 2)}% | ${fmt(median(rs.map((r) => r.评论率)), 2)}% |`
  );
}

say('');
say('## 诊断分类');
say('');
say('按「点击率 / 阅读时长」两轴分四象限，**用期内百分位**（同月内比较，剔除账号权重与平台分发的时期差异）。');
say('标题归 title-write，时长归 outline-plan / draft-write / hard-review。');
say('');
say('样本不足 3 篇的月份不参与诊断。阅读量 < 200 的篇目，点赞率/评论率不可用（分母太小）。');
say('');
const quad = (r) => {
  if (r.ctrPin === null) return null;
  const t = r.ctrPin >= 50;
  const d = r.durPin >= 50;
  if (t && d) return '双高（标题与正文都成立）';
  if (t && !d) return '标题赢正文输（改内容）';
  if (!t && d) return '正文赢标题输（改标题）';
  return '双低';
};
for (const q of ['双高（标题与正文都成立）', '正文赢标题输（改标题）', '标题赢正文输（改内容）', '双低']) {
  const rs = rows.filter((r) => quad(r) === q);
  say(`**${q}**：${rs.length} 篇`);
  say('');
  for (const r of rs.sort((a, b) => b.ctrPin - a.ctrPin)) {
    say(
      `- ${r.标题}（${r.期}｜CTR ${r.点击率}% 期内P${r.ctrPin}，时长 ${r.阅读时长} 期内P${r.durPin}）`
    );
  }
  say('');
}
const skipped = rows.filter((r) => r.ctrPin === null);
if (skipped.length) {
  say(`_不参与诊断（该月样本 < 3 篇）：${skipped.map((r) => r.标题).join('；')}_`);
  say('');
}

say('## 同题重发对照');
say('');
const titleGroups = new Map();
for (const r of rows) {
  const k = r.标题.trim();
  if (!titleGroups.has(k)) titleGroups.set(k, []);
  titleGroups.get(k).push(r);
}
let dupFound = false;
for (const [t, rs] of titleGroups) {
  if (rs.length < 2) continue;
  dupFound = true;
  say(`**${t}**`);
  say('');
  say('| 日期 | 展现量 | 阅读量 | 点击率 | 阅读时长 |');
  say('|---|---:|---:|---:|---:|');
  for (const r of rs.sort((a, b) => a.日期.localeCompare(b.日期)))
    say(`| ${r.日期} | ${r.展现量.toLocaleString()} | ${r.阅读量} | ${r.点击率}% | ${r.阅读时长} |`);
  say('');
}
if (!dupFound) say('无同题重发。');

// ---------- 全表 ----------

const full = [];
full.push('| 日期 | 系列 | 标题 | 展现量 | 阅读量 | 点击率 | P | 时长 | P | 点赞率 | P | 评论率 | 收益 |');
full.push('|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
for (const r of [...rows].sort((a, b) => b.展现量 - a.展现量)) {
  full.push(
    `| ${r.日期.slice(5)} | ${r.系列} | ${r.标题} | ${r.展现量.toLocaleString()} | ${r.阅读量.toLocaleString()} | ${r.点击率}% | ${r.ctrP} | ${r.阅读时长} | ${r.durP} | ${fmt(r.点赞率, 2)}% | ${r.likeP} | ${fmt(r.评论率, 2)}% | ${fmt(r.收益, 2)} |`
  );
}

const report = `# 表现台账

> 数据源：\`_工作流/_反馈/原始数据.tsv\`（录入新数据后跑 \`node _工作流/_scripts/ledger.mjs\` 重新生成）
> 样本：${rows.length} 篇｜总阅读 ${rows.reduce((a, r) => a + r.阅读量, 0).toLocaleString()}｜总收益 ¥${fmt(rows.reduce((a, r) => a + r.收益, 0), 2)}
> P = 百分位（在本账号全部样本中的相对位置，0-100，越高越好）。**看百分位不看绝对值**，账号在长大，绝对数跨时间不可比。

---

${lines.join('\n')}

---

## 全表（按展现量降序）

${full.join('\n')}
`;

if (statsOnly) console.log(lines.join('\n'));
else {
  fs.writeFileSync(OUT, report, 'utf8');
  console.log(`✓ 已生成 ${OUT}`);
  console.log(lines.join('\n'));
}
