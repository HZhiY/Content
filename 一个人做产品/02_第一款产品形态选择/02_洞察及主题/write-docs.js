const fs = require("fs");
const path = require("path");
const vm = require("vm");
const dir = __dirname;
const gen = "C:/Users/aaa/.cursor/projects/empty-window/tp02-gen";
const scan = vm.runInNewContext(
  fs.readFileSync(path.join(dir, "part1-scan.js"), "utf8") + "\nscan;",
  { require, console }
);
let direction = fs.readFileSync(path.join(gen, "direction.md"), "utf8");
const block = "\n\n---\n\n## \u56db\u3001\u7ec4\u5408\u5408\u6cd5\u6027\u68c0\u67e5\n\n| \u68c0\u67e5\u9879 | \u7ed3\u8bba | \u8bf4\u660e |\n|---|---|---|\n| \u662f\u5426\u670d\u52a1\u540c\u4e00\u4e2a\u4e3b\u627f\u8bfa | \u662f | 8 \u6761\u5747\u6307\u5411\u89e6\u8fbe+\u6210\u672c+\u9a8c\u8bc1\u4f18\u5148 |\n| \u526f\u6d1e\u5bdf\u662f\u5426\u62a2\u4e3b\u7ebf | \u9700\u8865\u4fee | \u5019\u9009 3 \u5728 02\u201305 \u987a\u9650\u5e45 |\n\n---\n\n## \u516d\u3001\u76ee\u6807\u5ba2\u6237\u5339\u914d\u5224\u65ad\n\n\u4e3b\u8981\u670d\u52a1\u4e2d\u56fd\u4e2a\u4eba\u5f00\u53d1\u8005\u7b2c\u4e00\u6b3e\u9a8c\u8bc1\u671f\uff1b\u8de8\u7aef/\u66b4\u5bcc/\u7070\u8272\u8bfb\u8005\u5e94\u88ab scope \u8fc7\u6ee4\u3002\n\n---\n\n## \u4e5d\u3001\u5916\u90e8\u540c\u8d28\u5316\u4e0e\u5dee\u5f02\u5316\u7ea6\u675f\n\n\u907f\u5f00 T02 \u4e00\u8fb9\u5012\u3001\u5f62\u6001\u7b49\u7ea7\u8bba\u3001\u4e00\u7bc7\u56db\u5f62\u6001\uff1b\u5dee\u5f02\u5316\uff1a\u89e6\u8fbe+\u6210\u672c+\u56fd\u5185\u8fb9\u754c+8 \u6761\u5355\u70b9\u3002\n";
if (!direction.includes("\u56db\u3001\u7ec4\u5408")) {
  direction = direction.replace("\n---\n\n## \u4e94\u3001", block + "\n---\n\n## \u4e94\u3001");
  fs.writeFileSync(path.join(gen, "direction.md"), direction, "utf8");
}
const insight = fs.readFileSync(path.join(dir, "\u6d1e\u5bdf\u53ca\u4e3b\u9898\u521d\u9009.md"), "utf8");
fs.writeFileSync(path.join(dir, "\u5916\u90e8\u5185\u5bb9\u641c\u7d22.md"), scan, "utf8");
fs.writeFileSync(path.join(dir, "\u6d1e\u5bdf\u53ca\u4e3b\u9898\u521d\u9009.md"), insight, "utf8");
fs.writeFileSync(path.join(dir, "\u65b9\u5411\u628a\u63a7.md"), direction, "utf8");
for (const name of ["\u5916\u90e8\u5185\u5bb9\u641c\u7d22.md", "\u6d1e\u5bdf\u53ca\u4e3b\u9898\u521d\u9009.md", "\u65b9\u5411\u628a\u63a7.md"]) {
  const t = fs.readFileSync(path.join(dir, name), "utf8");
  if (!/^#/.test(t.trim()) || t.includes("\uFFFD")) throw new Error("verify failed: " + name);
}
console.log("OK UTF-8", { scan: scan.length, insight: insight.length, direction: direction.length });
