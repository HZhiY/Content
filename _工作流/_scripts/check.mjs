#!/usr/bin/env node
/**
 * 闸门校验。每段结束由主 agent 调用，退出码非 0 表示未通过。
 *
 *   node _工作流/_scripts/check.mjs "<项目路径>" --gate=3
 *   node _工作流/_scripts/check.mjs "<项目路径>" --all
 *   node _工作流/_scripts/check.mjs "<项目路径>" --config
 */

import fs from 'fs';
import path from 'path';

const PARA_MAX = 240;
const SENT_MAX = 100;

const args = process.argv.slice(2);
const projectDir = args.find((a) => !a.startsWith('--'));
const gateArg = args.find((a) => a.startsWith('--gate='));
const runAll = args.includes('--all');
const configOnly = args.includes('--config');

if (!projectDir) {
  console.error('用法: node check.mjs "<项目路径>" [--gate=N | --all | --config]');
  process.exit(2);
}

const ROOT = path.resolve(projectDir);
if (!fs.existsSync(ROOT)) {
  console.error(`项目路径不存在: ${ROOT}`);
  process.exit(2);
}

const results = [];
function ok(gate, item, note = '') {
  results.push({ gate, level: 'ok', item, note });
}
function warn(gate, item, note = '') {
  results.push({ gate, level: 'warn', item, note });
}
function fail(gate, item, note = '') {
  results.push({ gate, level: 'fail', item, note });
}

const p = (...parts) => path.join(ROOT, ...parts);
const exists = (...parts) => fs.existsSync(p(...parts));
const read = (...parts) => {
  try {
    return fs.readFileSync(p(...parts), 'utf8');
  } catch {
    return null;
  }
};

function listFiles(dir = '') {
  const d = p(dir);
  if (!fs.existsSync(d)) return [];
  return fs.readdirSync(d).filter((f) => fs.statSync(path.join(d, f)).isFile());
}

// ---------- 状态与形态 ----------

function loadState() {
  const raw = read('状态.json');
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return 'BROKEN';
  }
}

/** 系列级薄配置：项目目录的父目录即系列目录 */
function seriesConfigFile() {
  return path.join(path.dirname(ROOT), '_meta', '系列配置.md');
}

/** 账号级配置目录：从系列配置的「账号：X」字段解析，落在仓库根的 _配置/X/ */
function accountConfigDir() {
  const seriesDir = path.dirname(ROOT);
  let account = '头条号';
  const sc = seriesConfigFile();
  if (fs.existsSync(sc)) {
    const m = fs.readFileSync(sc, 'utf8').match(/账号\s*[:：]\s*(\S+)/);
    if (m) account = m[1];
  }
  return path.join(path.dirname(seriesDir), '_配置', account);
}

function detectForm() {
  const state = loadState();
  if (state && state !== 'BROKEN' && state.形态) return state.形态;
  const cfg = path.join(accountConfigDir(), '文风与格式.md');
  if (fs.existsSync(cfg)) {
    const m = fs.readFileSync(cfg, 'utf8').match(/形态\s*[:：]\s*(长文|图文组)/);
    if (m) return m[1];
  }
  return '长文';
}

// ---------- Markdown 辅助 ----------

/** 提取表格行为对象数组，按表头列名索引 */
function parseTables(md) {
  const tables = [];
  const lines = md.split(/\r?\n/);
  let header = null;
  let rows = [];
  const flush = () => {
    if (header && rows.length) tables.push({ header, rows });
    header = null;
    rows = [];
  };
  for (const line of lines) {
    const t = line.trim();
    if (!t.startsWith('|')) {
      flush();
      continue;
    }
    const cells = t.split('|').slice(1, -1).map((c) => c.trim());
    if (/^[-: ]+$/.test(cells.join(''))) continue; // 分隔行
    if (!header) header = cells;
    else rows.push(cells);
  }
  flush();
  return tables;
}

function findTable(md, ...requiredCols) {
  return parseTables(md).find((tb) =>
    requiredCols.every((c) => tb.header.some((h) => h.includes(c)))
  );
}

function col(table, row, name) {
  const i = table.header.findIndex((h) => h.includes(name));
  return i === -1 ? '' : row[i] ?? '';
}

/** 去掉标题行与顶部元信息引用块，得到正文 */
function bodyOf(md) {
  const lines = md.split(/\r?\n/);
  let i = 0;
  while (i < lines.length && !lines[i].trim()) i++;
  if (lines[i] && /^#\s/.test(lines[i])) i++;
  while (i < lines.length && (!lines[i].trim() || lines[i].trim().startsWith('>'))) i++;
  return lines.slice(i).join('\n');
}

// ---------- 各段闸门 ----------

function gate0() {
  const G = 0;
  if (!exists('00_立项.md')) return fail(G, '00_立项.md', '文件不存在');
  ok(G, '00_立项.md');

  const md = read('00_立项.md');
  if (/赌注[:：]\s*读者读完会明白.+而他现在以为是/.test(md.replace(/\r?\n/g, ' '))) {
    ok(G, '赌注格式');
  } else {
    fail(G, '赌注格式', '未找到「赌注：读者读完会明白【X】，而他现在以为是【Y】。」这一行');
  }

  const state = loadState();
  if (!state) fail(G, '状态.json', '文件不存在');
  else if (state === 'BROKEN') fail(G, '状态.json', 'JSON 解析失败');
  else ok(G, '状态.json', `形态=${state.形态 ?? '未填'}`);

  for (const d of ['05_审阅', '06_成稿']) {
    if (fs.existsSync(p(d))) ok(G, `目录 ${d}`);
    else fail(G, `目录 ${d}`, '不存在');
  }
}

function gate1() {
  const G = 1;
  if (!exists('01_事实包.md')) return fail(G, '01_事实包.md', '文件不存在');
  ok(G, '01_事实包.md');

  const md = read('01_事实包.md');
  const table = findTable(md, '主张', '优先级', '核查');
  if (!table) return fail(G, '主张表', '未找到含「主张/优先级/核查」列的表格');

  const rows = table.rows.filter((r) => /^F\d+/.test(col(table, r, '编号')));
  if (!rows.length) return fail(G, '主张表', '没有 F 开头的事实行');
  ok(G, '主张表', `${rows.length} 条`);

  const p0 = rows.filter((r) => /P0/.test(col(table, r, '优先级')));
  ok(G, 'P0 数量', `${p0.length} 条`);
  if (p0.length === 0) warn(G, 'P0 数量', '一条 P0 都没有，确认是否漏标了论证支点');
  if (p0.length > 15) warn(G, 'P0 数量', `${p0.length} 条偏多，可能没分清支点与细节`);

  const bad = [];
  const pending = [];
  for (const r of p0) {
    const id = col(table, r, '编号');
    const src = col(table, r, '来源');
    const chk = col(table, r, '核查');
    if (/待补/.test(chk) || /待补/.test(src)) {
      pending.push(id);
      continue;
    }
    if (!/https?:\/\//.test(src)) bad.push(`${id} 无来源链接`);
    else if (!/已核实/.test(chk)) bad.push(`${id} 核查=${chk || '空'}`);
  }
  if (bad.length) fail(G, 'P0 核查', bad.join('；'));
  else ok(G, 'P0 核查', '全部已核实');

  if (pending.length) warn(G, 'P0 待补', `${pending.join('、')} —— 不得作为论证支点`);

  if (/##\s*五、复核结论/.test(md) || /复核员\s*[:：]\s*fact-audit/.test(md)) ok(G, '复核结论');
  else fail(G, '复核结论', 'fact-audit 未追加「五、复核结论」，说明复核没跑');
}

function gate2() {
  const G = 2;
  if (!exists('02_角度.md')) return fail(G, '02_角度.md', '文件不存在');
  ok(G, '02_角度.md');

  const md = read('02_角度.md');
  const m = md.match(/##\s*已选角度\s*```text\s*([\s\S]*?)```/);
  if (!m) fail(G, '已选角度', '未找到「## 已选角度」代码块');
  else if (/待用户选择|待选/.test(m[1])) fail(G, '已选角度', '仍是「待用户选择」，需要人工选定后才能进段 3');
  else ok(G, '已选角度', m[1].trim().split('\n')[0]);

  const cands = md.match(/^##\s*候选\s*[A-Z\d]/gm) || [];
  if (cands.length >= 3) ok(G, '候选数量', `${cands.length} 个`);
  else fail(G, '候选数量', `只有 ${cands.length} 个，至少 3 个`);

  const errCount = (md.match(/如果错了[，,]?\s*错在/g) || []).length;
  if (errCount >= cands.length) ok(G, '可证伪性', '每个候选都写了「如果错了，错在」');
  else fail(G, '可证伪性', `${cands.length} 个候选只有 ${errCount} 个写了「如果错了，错在」`);

  for (const field of ['文章发动机', '三个独立收获', '最强现场', '首屏耗尽测试']) {
    const count = (md.match(new RegExp(`\\*\\*${field}\\*\\*`, 'g')) || []).length;
    if (count >= cands.length) ok(G, field, `${count}/${cands.length}`);
    else fail(G, field, `${cands.length} 个候选只有 ${count} 个填写`);
  }

  if (/首屏耗尽测试[\s\S]{0,80}(?:判为|：)\s*耗尽/.test(md))
    warn(G, '长文寿命', '存在候选被判「首屏耗尽」；不得推荐为长文角度');
}

function gate3() {
  const G = 3;
  if (!exists('03_大纲.md')) return fail(G, '03_大纲.md', '文件不存在');
  ok(G, '03_大纲.md');

  if (!exists('05_审阅', '结构反审.md')) fail(G, '结构反审.md', '未找到；大纲不能用普通盲读替代结构反审');
  else {
    const review = read('05_审阅', '结构反审.md') ?? '';
    if (/^结论\s*[:：]\s*可进草稿\s*$/m.test(review)) ok(G, '结构反审', '可进草稿');
    else fail(G, '结构反审', '结论不是「可进草稿」');
  }

  const md = read('03_大纲.md');
  const refs = md.match(/F\d+/g) || [];
  if (refs.length) ok(G, '事实引用', `引用了 ${new Set(refs).size} 条事实`);
  else fail(G, '事实引用', '大纲没有引用任何 F 编号，无法核对事实与节的对应');

  if (/要证明什么/.test(md)) ok(G, '节命题');
  else fail(G, '节命题', '各节缺少「要证明什么」');

  if (/读者路径/.test(md)) ok(G, '读者路径');
  else fail(G, '读者路径', '缺少 300-500 字无施工术语的读者路径');

  for (const field of ['新增信息', '具体载体', '删节测试', '信息增量表']) {
    if (new RegExp(field).test(md)) ok(G, field);
    else fail(G, field, `大纲缺少「${field}」`);
  }

  if (/升维边界/.test(md)) ok(G, '升维边界');
  else warn(G, '升维边界', '结尾未写升维边界，容易拔高');
}

function gate4() {
  const G = 4;
  const drafts = listFiles().filter((f) => /^04_草稿 v\d+\.md$/.test(f));
  if (!drafts.length) return fail(G, '04_草稿 v1.md', '文件不存在');
  ok(G, '草稿', drafts.join('、'));

  const latest = drafts.sort((a, b) => draftNum(a) - draftNum(b)).at(-1);
  const md = read(latest);
  if (/写作执行说明|自检清单|待补或风险提示/.test(md))
    fail(G, '草稿纯净度', `${latest} 正文里混入了执行说明/自检清单，应只在对话里汇报`);
  else ok(G, '草稿纯净度');

  if (/^>\s*(?:阶段|依据|说明)\s*[:：]/m.test(md))
    fail(G, '读者输入纯净度', `${latest} 含「阶段/依据/说明」施工元信息，盲读会被污染`);
  else ok(G, '读者输入纯净度');
}

const draftNum = (f) => parseInt(f.match(/v(\d+)/)?.[1] ?? '0', 10);

function gate5() {
  const G = 5;
  const drafts = listFiles()
    .filter((f) => /^04_草稿 v\d+\.md$/.test(f))
    .sort((a, b) => draftNum(a) - draftNum(b));
  if (!drafts.length) return fail(G, '草稿', '不存在');

  const reviews = listFiles('05_审阅');
  const hardN = reviews
    .filter((f) => /^硬审 v\d+\.md$/.test(f))
    .map((f) => draftNum(f))
    .sort((a, b) => a - b);

  if (!hardN.length) return fail(G, '硬审', '一轮都没跑');

  // 配对校验
  const problems = [];
  for (const n of hardN) {
    if (!drafts.some((d) => draftNum(d) === n)) problems.push(`硬审 v${n} 没有对应的 04_草稿 v${n}.md`);
    if (!reviews.includes(`盲读 v${n}.md`)) problems.push(`硬审 v${n} 没有对应的 盲读 v${n}.md`);
  }
  const maxDraft = draftNum(drafts.at(-1));
  if (!hardN.includes(maxDraft)) problems.push(`最新草稿 v${maxDraft} 还没有硬审`);
  if (problems.length) fail(G, '版本配对', problems.join('；'));
  else ok(G, '版本配对', `v${hardN.join('、v')}`);

  if (hardN.length > 2) fail(G, '轮次上限', `已跑 ${hardN.length} 轮，上限 2 轮，应写 人工介入.md 停止`);
  else ok(G, '轮次上限', `${hardN.length}/2`);

  const last = read('05_审阅', `硬审 v${Math.max(...hardN)}.md`) ?? '';
  const blind = read('05_审阅', `盲读 v${Math.max(...hardN)}.md`) ?? '';
  if (!/##\s*读者判票/.test(blind)) fail(G, '读者判票', '同轮盲读缺少机器可读判票，不能冻结');
  else {
    ok(G, '读者判票', '已填写');
    const redFlags = [];
    if (/主旨提前耗尽\s*[:：]\s*是/.test(blind)) redFlags.push('主旨提前耗尽');
    if (/明显跳读区\s*[:：]\s*2\+/.test(blind)) redFlags.push('明显跳读区 2+');
    if (/独立收获数\s*[:：]\s*(?:0|1)(?!\d)/.test(blind)) redFlags.push('独立收获不足 2');
    if (/具体载体数\s*[:：]\s*(?:0|1)(?!\d)/.test(blind)) redFlags.push('具体载体不足 2');
    if (/推荐动作\s*[:：]\s*无/.test(blind)) redFlags.push('无推荐动作');
    if (redFlags.length) fail(G, '读者价值', redFlags.join('；'));
    else ok(G, '读者价值', '无阻塞信号');
  }

  const releaseGates = ['V1 主旨寿命', 'V2 信息推进', 'V3 具体载体', 'V4 读者利害', 'V5 作者隐身', 'S1 事实', 'S2 成稿卫生'];
  const failedGates = releaseGates.filter((name) => !new RegExp(`\\|\\s*${name}\\s*\\|\\s*通过\\s*\\|`).test(last));
  if (failedGates.length) fail(G, '发布七闸', `未明确通过：${failedGates.join('、')}`);
  else ok(G, '发布七闸', '7/7');

  if (/^结论\s*[:：]\s*可冻结\s*$/m.test(last)) ok(G, '硬审结论', '可冻结');
  else if (/^结论\s*[:：]\s*退回角度\s*$/m.test(last)) fail(G, '硬审结论', '退回角度，需重新人工选角度');
  else if (/^结论\s*[:：]\s*退回大纲\s*$/m.test(last)) fail(G, '硬审结论', '退回大纲，需重做结构反审');
  else fail(G, '硬审结论', '不是「可冻结」，需继续处理');

  if (exists('06_成稿', '终稿.md')) ok(G, '终稿.md', '已从草稿复制');
  else fail(G, '终稿.md', '冻结后应复制最终草稿到 06_成稿/终稿.md');
}

function gate6() {
  const G = 6;
  const form = detectForm();
  ok(G, '形态', form);

  if (!exists('06_成稿', '标题.md')) fail(G, '标题.md', '文件不存在');
  else {
    const md = read('06_成稿', '标题.md');
    const m = md.match(/##\s*已选标题\s*```text\s*([\s\S]*?)```/);
    if (!m) fail(G, '已选标题', '未找到「## 已选标题」代码块');
    else if (/待用户选择|待选/.test(m[1])) fail(G, '已选标题', '仍是「待用户选择」');
    else ok(G, '已选标题', m[1].trim());
  }

  if (!exists('06_成稿', '终稿.md')) return fail(G, '终稿.md', '文件不存在');
  const finalMd = read('06_成稿', '终稿.md');
  const body = bodyOf(finalMd);

  // 成稿卫生
  const hygiene = [
    { id: 'H1', re: /【[^】]*】/g, desc: '方括号施工标记' },
    { id: 'H4', re: /刺点|膝盖句|母题句|本版必处理|待补资料|施工标记/g, desc: '审稿术语' },
    { id: 'H5', re: /工作标题|非最终标题|占位符|TODO|TBD/g, desc: '占位符残留' },
    { id: 'H3', re: /写作执行说明|修订执行说明|质量自检|自检清单/g, desc: '执行说明表' },
  ];
  let hygieneFail = false;
  for (const h of hygiene) {
    const hits = body.match(h.re);
    if (hits) {
      hygieneFail = true;
      fail(G, `成稿卫生 ${h.id}`, `${h.desc}：${[...new Set(hits)].slice(0, 5).join('、')}`);
    }
  }
  const h1 = finalMd.match(/^#\s+(.+)$/m)?.[1] ?? '';
  if (/工作标题|非最终标题|占位|【/.test(h1)) {
    hygieneFail = true;
    fail(G, '成稿卫生 H5', `标题行仍是占位：「${h1}」`);
  }

  const idHits = body.match(/(?:^|[\s（(、，,])F\d{1,2}(?![0-9A-Za-z])/g);
  if (idHits) warn(G, '成稿卫生 H2', `疑似内部编号 ${[...new Set(idHits.map((s) => s.trim()))].join('、')}，确认是否为正文内容`);
  if (!hygieneFail) ok(G, '成稿卫生', '通过');

  // 字数与段落
  const plain = body.replace(/[#>*`_\-|]/g, '');
  const charCount = (plain.match(/[\u4e00-\u9fa5]/g) || []).length;
  ok(G, '正文字数', `${charCount} 字（中文字符）`);

  const paras = body
    .split(/\n{2,}/)
    .map((s) => s.trim())
    .filter((s) => s && !s.startsWith('#') && !s.startsWith('|') && !s.startsWith('>'));
  const longParas = paras.filter((s) => (s.match(/[\u4e00-\u9fa5]/g) || []).length > PARA_MAX);
  if (longParas.length)
    warn(G, '段落长度', `${longParas.length} 段超过 ${PARA_MAX} 字，首段开头：「${longParas[0].slice(0, 20)}…」`);
  else ok(G, '段落长度', `全部 ≤ ${PARA_MAX} 字`);

  const longSents = body
    .split(/[。！？；\n]/)
    .filter((s) => (s.match(/[\u4e00-\u9fa5]/g) || []).length > SENT_MAX);
  if (longSents.length) warn(G, '句子长度', `${longSents.length} 句超过 ${SENT_MAX} 字`);
  else ok(G, '句子长度', `全部 ≤ ${SENT_MAX} 字`);

  // HTML
  const htmls = listFiles('06_成稿').filter((f) => f.endsWith('.html'));
  if (form === '长文') {
    if (htmls.length === 1) ok(G, 'HTML 数量', htmls[0]);
    else if (htmls.length === 0) fail(G, 'HTML 数量', '未生成，跑 build-html.mjs');
    else fail(G, 'HTML 数量', `长文形态应只有 1 个，实际 ${htmls.length} 个：${htmls.join('、')}`);

    if (htmls.length === 1) {
      const html = read('06_成稿', htmls[0]);
      const htmlText = html
        .replace(/<script[\s\S]*?<\/script>/g, '')
        .replace(/<style[\s\S]*?<\/style>/g, '')
        .replace(/<[^>]+>/g, '')
        .replace(/&[a-z]+;/g, '')
        .replace(/\s/g, '');
      const mdText = body.replace(/[#>*`_|\-!\[\]()]/g, '').replace(/\s/g, '');
      const missing = [];
      for (let i = 0; i < mdText.length; i += 60) {
        const chunk = mdText.slice(i, i + 60);
        if (chunk.length >= 30 && !htmlText.includes(chunk)) missing.push(chunk.slice(0, 20));
      }
      if (missing.length)
        fail(G, 'HTML 正文一致', `${missing.length} 处正文片段在 HTML 中找不到，首处：「${missing[0]}…」`);
      else ok(G, 'HTML 正文一致');
    }
  } else {
    if (htmls.length >= 1) ok(G, 'HTML 数量', `${htmls.length} 个（图文组形态，每条一个）`);
    else fail(G, 'HTML 数量', '未生成');
  }
}

function checkConfig() {
  let bad = false;

  const sc = seriesConfigFile();
  console.log(`系列配置：${sc}`);
  if (fs.existsSync(sc)) {
    console.log('  ✓ 系列配置.md');
    if (!/账号\s*[:：]\s*\S+/.test(fs.readFileSync(sc, 'utf8'))) {
      console.log('      ✗ 缺少「账号：X」字段，无法定位账号级配置');
      bad = true;
    }
  } else {
    console.log('  ✗ 系列配置.md 不存在');
    bad = true;
  }

  const dir = accountConfigDir();
  console.log(`\n账号配置目录：${dir}`);
  for (const f of ['读者与平台.md', '文风与格式.md']) {
    const fp = path.join(dir, f);
    if (!fs.existsSync(fp)) {
      console.log(`  ✗ ${f} 不存在`);
      bad = true;
      continue;
    }
    console.log(`  ✓ ${f}`);
    if (f === '文风与格式.md') {
      const m = fs.readFileSync(fp, 'utf8').match(/形态\s*[:：]\s*(长文|图文组)/);
      if (m) console.log(`      形态 = ${m[1]}`);
      else {
        console.log('      ✗ 缺少「形态：长文 / 图文组」字段');
        bad = true;
      }
    }
  }

  const oldDir = path.join(path.dirname(ROOT), '_meta', '_config');
  if (fs.existsSync(oldDir))
    console.log(`\n  ! 仍存在旧配置目录 ${oldDir}，确认已迁移后移入 _archive/`);

  process.exit(bad ? 1 : 0);
}

// ---------- 执行 ----------

if (configOnly) checkConfig();

const GATES = { 0: gate0, 1: gate1, 2: gate2, 3: gate3, 4: gate4, 5: gate5, 6: gate6 };

let toRun;
if (runAll) toRun = Object.keys(GATES).map(Number);
else if (gateArg) toRun = [Number(gateArg.split('=')[1])];
else {
  console.error('需要 --gate=N 或 --all 或 --config');
  process.exit(2);
}

for (const g of toRun) {
  const fn = GATES[g];
  if (!fn) {
    console.error(`没有段 ${g}`);
    process.exit(2);
  }
  fn();
}

const ICON = { ok: '✓', warn: '!', fail: '✗' };
console.log(`\n项目：${ROOT}\n`);
let lastGate = null;
for (const r of results) {
  if (r.gate !== lastGate) {
    console.log(`── 段 ${r.gate} ──`);
    lastGate = r.gate;
  }
  console.log(`  ${ICON[r.level]} ${r.item}${r.note ? `：${r.note}` : ''}`);
}

const fails = results.filter((r) => r.level === 'fail');
const warns = results.filter((r) => r.level === 'warn');
console.log(
  `\n结论：${fails.length ? '未通过' : '通过'}（${results.filter((r) => r.level === 'ok').length} 项通过，${warns.length} 项提醒，${fails.length} 项不通过）`
);
if (fails.length) {
  console.log('\n必须处理：');
  for (const f of fails) console.log(`  - [段${f.gate}] ${f.item}：${f.note}`);
}
process.exit(fails.length ? 1 : 0);
