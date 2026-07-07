// Dashboard renderer: fetches ./data/*.json and paints each section.

const PALETTE = [
  "#60a5fa", "#f472b6", "#34d399", "#fbbf24", "#a78bfa",
  "#fb7185", "#22d3ee", "#a3e635", "#f97316", "#e879f9",
  "#2dd4bf", "#facc15",
];

const $ = (sel) => document.querySelector(sel);

async function loadJSON(path) {
  const v = window.__V && window.__V !== "__VERSION__" ? `?v=${window.__V}` : "";
  const res = await fetch(path + v);
  if (!res.ok) throw new Error(`${path}: ${res.status}`);
  return res.json();
}

const nf = new Intl.NumberFormat("en-US");

// Human-readable relative age from a YYYY-MM-DD date string.
function relativeTime(dateStr) {
  if (!dateStr) return "";
  const then = new Date(dateStr + "T00:00:00Z");
  if (isNaN(then)) return "";
  const days = Math.floor((Date.now() - then.getTime()) / 86400000);
  if (days <= 0) return "today";
  if (days === 1) return "1 day ago";
  if (days < 30) return `${days} days ago`;
  const months = Math.floor(days / 30);
  if (months < 12) return months === 1 ? "1 month ago" : `${months} months ago`;
  const years = Math.floor(days / 365);
  return years === 1 ? "1 year ago" : `${years} years ago`;
}

// Deterministic colored badge for a filetype/extension.
const BADGE_COLORS = [
  "bg-blue-500/15 text-blue-300",
  "bg-pink-500/15 text-pink-300",
  "bg-emerald-500/15 text-emerald-300",
  "bg-amber-500/15 text-amber-300",
  "bg-violet-500/15 text-violet-300",
  "bg-rose-500/15 text-rose-300",
  "bg-cyan-500/15 text-cyan-300",
  "bg-lime-500/15 text-lime-300",
  "bg-orange-500/15 text-orange-300",
  "bg-fuchsia-500/15 text-fuchsia-300",
  "bg-teal-500/15 text-teal-300",
];
function typeBadge(t) {
  let h = 0;
  for (let i = 0; i < t.length; i++) h = (h * 31 + t.charCodeAt(i)) >>> 0;
  return BADGE_COLORS[h % BADGE_COLORS.length];
}

function card(label, value, sub) {
  return `
    <div class="rounded-lg border border-edge bg-panel p-4">
      <div class="text-2xl font-bold text-zinc-50">${value}</div>
      <div class="mt-1 text-xs uppercase tracking-wide text-zinc-500">${label}</div>
      ${sub ? `<div class="mt-1 text-xs text-zinc-600">${sub}</div>` : ""}
    </div>`;
}

// Colored +/- delta vs the previous month.
function delta(cur, prev) {
  if (prev == null) return "";
  const d = cur - prev;
  if (d === 0) return `<span class="text-zinc-600">±0 vs last month</span>`;
  const sign = d > 0 ? "+" : "−";
  const color = d > 0 ? "text-emerald-400" : "text-red-400";
  return `<span class="${color}">${sign}${nf.format(Math.abs(d))}</span> <span class="text-zinc-600">vs last month</span>`;
}

function countLangs(byLang) {
  return Object.values(byLang || {}).filter((v) => v > 0).length;
}

function renderOverview(langs, hosts, modules, scripts) {
  const cur = langs.current;
  const prev = langs.series[langs.series.length - 2] || null;
  const nLangs = countLangs(cur.by_language);
  $("#overview").innerHTML = [
    card("Lines of code", nf.format(cur.total_lines), delta(cur.total_lines, prev?.total_lines ?? null)),
    card("Total lines (wc -l)", nf.format(cur.total_raw_lines), delta(cur.total_raw_lines, prev?.total_raw_lines ?? null)),
    card("Files", nf.format(cur.total_files), delta(cur.total_files, prev?.total_files ?? null)),
    card("Languages", nf.format(nLangs), delta(nLangs, prev ? countLangs(prev.by_language) : null)),
    card("Nix hosts", nf.format(hosts.hosts.length)),
    card("Nix modules", nf.format(modules.modules.length)),
    card("Scripts", nf.format(scripts.length)),
  ].join("");
}

function renderMeta(meta) {
  const short = meta.commit.slice(0, 8);
  const when = new Date(meta.generated).toISOString().replace("T", " ").slice(0, 16);
  $("#meta").textContent = `commit ${short} · generated ${when} UTC`;
}

function renderLanguages(langs) {
  const list = langs.current.languages || [];
  const prev = langs.series[langs.series.length - 2]?.by_language ?? {};
  const rows = list
    .map(
      (l) => `
      <div class="flex items-center justify-between gap-4 px-4 py-3">
        <div class="min-w-0">
          <div class="truncate text-sm font-semibold text-zinc-100" title="${l.name}">${l.name}</div>
          <div class="mt-0.5 text-xs text-zinc-500">${nf.format(l.files)} file${l.files === 1 ? "" : "s"}</div>
        </div>
        <div class="shrink-0 text-right">
          <div class="text-lg font-bold text-zinc-50">${nf.format(l.code)} <span class="text-xs font-normal uppercase tracking-wide text-zinc-500">lines</span></div>
          <div class="mt-0.5 text-xs">${delta(l.code, prev[l.name] ?? null)}</div>
        </div>
      </div>`
    )
    .join("");
  $("#languages").innerHTML = `
    <div class="divide-y divide-edge rounded-lg border border-edge bg-panel">${rows}</div>`;
}

let langChart;
function renderLangChart(langs, metric) {
  const series = langs.series;
  const labels = series.map((s) => s.month);

  // Rank languages by their most-recent value; keep top 11, fold rest into "other".
  const last = series[series.length - 1]?.by_language ?? {};
  const ranked = Object.keys(last).sort((a, b) => (last[b] || 0) - (last[a] || 0));
  const top = ranked.slice(0, 11);
  const useFiles = metric === "files";

  // Per-language value at each month. When showing "files" we only have
  // total_files historically, so we approximate language file split is not
  // available; fall back to code lines proportionally is misleading, so for
  // "files" we render a single total-files line instead.
  let datasets;
  if (useFiles) {
    datasets = [
      {
        label: "files",
        data: series.map((s) => s.total_files),
        borderColor: PALETTE[0],
        backgroundColor: PALETTE[0] + "33",
        fill: true,
        tension: 0.25,
      },
    ];
  } else {
    datasets = top.map((lang, i) => ({
      label: lang,
      data: series.map((s) => s.by_language[lang] || 0),
      borderColor: PALETTE[i % PALETTE.length],
      backgroundColor: PALETTE[i % PALETTE.length] + "55",
      fill: true,
      tension: 0.25,
      pointRadius: 0,
    }));
    const otherLangs = ranked.slice(11);
    if (otherLangs.length) {
      datasets.push({
        label: "other",
        data: series.map((s) =>
          otherLangs.reduce((sum, l) => sum + (s.by_language[l] || 0), 0)
        ),
        borderColor: "#71717a",
        backgroundColor: "#71717a55",
        fill: true,
        tension: 0.25,
        pointRadius: 0,
      });
    }
  }

  const cfg = {
    type: "line",
    data: { labels, datasets },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: "index", intersect: false },
      scales: {
        x: { stacked: !useFiles, grid: { color: "#26262b" }, ticks: { color: "#a1a1aa", maxRotation: 0, autoSkip: true } },
        y: { stacked: !useFiles, grid: { color: "#26262b" }, ticks: { color: "#a1a1aa" } },
      },
      plugins: {
        legend: { labels: { color: "#d4d4d8", boxWidth: 12 } },
        tooltip: { itemSort: (a, b) => b.parsed.y - a.parsed.y },
      },
    },
  };

  if (langChart) langChart.destroy();
  langChart = new Chart($("#langChart"), cfg);
}

function renderHostMatrix(hosts) {
  const { hosts: hs, modules, matrix } = hosts;
  const head = `
    <thead>
      <tr class="text-zinc-400">
        <th class="sticky left-0 z-10 bg-panel px-3 py-2 text-left font-semibold">module</th>
        ${hs.map((h) => `<th class="px-3 py-2 font-semibold">${h}</th>`).join("")}
      </tr>
    </thead>`;
  const rows = modules
    .map((m, i) => {
      const cells = hs
        .map((h) => {
          const on = (matrix[h] || []).includes(m);
          return `<td class="px-3 py-1.5 text-center ${on ? "text-emerald-400" : "text-zinc-700"}">${on ? "●" : "·"}</td>`;
        })
        .join("");
      const zebra = i % 2 ? "bg-white/[0.02]" : "";
      return `<tr class="${zebra}"><td class="sticky left-0 z-10 bg-panel px-3 py-1.5 text-left text-zinc-300">${m}</td>${cells}</tr>`;
    })
    .join("");
  $("#hostMatrix").innerHTML = head + `<tbody>${rows}</tbody>`;
}

// Build a nested tree from a list of {path, last_commit} entries.
function buildFileTree(files) {
  const root = {};
  for (const f of files) {
    const parts = f.path.split("/");
    let node = root;
    parts.forEach((part, i) => {
      node.children ??= {};
      const leaf = i === parts.length - 1;
      node.children[part] ??= leaf
        ? { leaf: true, date: f.last_commit }
        : {};
      node = node.children[part];
    });
  }
  return root;
}

// Collapse chains of single-child directories into one label,
// e.g. nix -> features -> collections -> desktop => "nix/features/collections/desktop".
function collapseChain(name, node) {
  let label = name;
  let cur = node;
  while (cur.children && Object.keys(cur.children).length === 1) {
    const key = Object.keys(cur.children)[0];
    const child = cur.children[key];
    if (child.leaf) break; // stop before a file
    label += "/" + key;
    cur = child;
  }
  return { label, node: cur };
}

function renderFileTree(node, depth = 0) {
  if (!node.children) return "";
  return Object.keys(node.children)
    .sort()
    .map((name) => {
      const child = node.children[name];
      const pad = `padding-left:${depth * 0.9}rem`;
      if (child.leaf) {
        return `
          <div class="flex items-baseline justify-between gap-3 text-xs" style="${pad}">
            <span class="text-zinc-400">${name}</span>
            <span class="shrink-0 text-zinc-600">${child.date || ""}</span>
          </div>`;
      }
      const { label, node: collapsed } = collapseChain(name, child);
      return (
        `<div class="text-xs text-zinc-500" style="${pad}">${label}/</div>` +
        renderFileTree(collapsed, depth + 1)
      );
    })
    .join("");
}

function renderModules(modules) {
  const byCat = {};
  for (const m of modules.modules) (byCat[m.category] ??= []).push(m);
  const cats = Object.keys(byCat).sort();
  $("#modules").innerHTML = cats
    .map((cat) => {
      const items = byCat[cat]
        .map(
          (m) => `
          <li class="flex flex-col gap-1 border-l border-edge py-1 pl-3">
            <span class="text-zinc-200">${m.name}</span>
            <div class="space-y-0.5">${renderFileTree(buildFileTree(m.files))}</div>
          </li>`
        )
        .join("");
      return `
        <div class="rounded-lg border border-edge bg-panel p-4">
          <h3 class="mb-2 text-sm font-semibold uppercase tracking-wide text-zinc-400">${cat}</h3>
          <ul class="space-y-1">${items}</ul>
        </div>`;
    })
    .join("");
}

const LANG_BADGE = {
  bash: "bg-emerald-500/15 text-emerald-300",
  sh: "bg-sky-500/15 text-sky-300",
  php: "bg-violet-500/15 text-violet-300",
  other: "bg-zinc-500/15 text-zinc-300",
};

function renderScripts(scripts) {
  const byFolder = {};
  for (const s of scripts) (byFolder[s.folder] ??= []).push(s);
  const folders = Object.keys(byFolder).sort();
  $("#scripts").innerHTML = folders
    .map((folder) => {
      const rows = byFolder[folder]
        .map((s) => {
          const badge = LANG_BADGE[s.lang] || LANG_BADGE.other;
          const name = s.path.split("/").pop();
          return `
            <tr class="border-t border-edge/60">
              <td class="py-1.5 pr-3 align-top text-zinc-200">${name}</td>
              <td class="py-1.5 pr-3 align-top"><span class="rounded px-1.5 py-0.5 text-xs ${badge}">${s.lang}</span></td>
              <td class="py-1.5 pr-3 align-top text-zinc-400">${s.description || '<span class="text-zinc-700">—</span>'}</td>
              <td class="whitespace-nowrap py-1.5 align-top text-right text-xs text-zinc-600">${s.last_commit || ""}</td>
            </tr>`;
        })
        .join("");
      return `
        <div class="rounded-lg border border-edge bg-panel p-4">
          <h3 class="mb-2 text-sm font-semibold text-zinc-300">bin/${folder} <span class="text-zinc-600">(${byFolder[folder].length})</span></h3>
          <table class="w-full text-sm"><tbody>${rows}</tbody></table>
        </div>`;
    })
    .join("");
}

function renderCommits(commits) {
  $("#commits").innerHTML = commits
    .map((c) => {
      const types = c.filetypes
        .map((t) => `<span class="rounded px-1.5 py-0.5 text-xs ${typeBadge(t)}">${t}</span>`)
        .join(" ");
      return `
        <div class="rounded-lg border border-edge bg-panel p-3">
          <div class="flex items-baseline justify-between gap-3">
            <span class="text-sm text-zinc-200">${escapeHtml(c.subject)}</span>
            <span class="shrink-0 text-sm text-zinc-400">${c.date} · ${relativeTime(c.date)} · ${c.sha}</span>
          </div>
          <div class="mt-2 flex flex-wrap items-center gap-1.5">
            <span class="mr-1 text-xs text-zinc-600">${c.files_changed} file${c.files_changed === 1 ? "" : "s"}:</span>
            ${types}
          </div>
        </div>`;
    })
    .join("");
}

function renderStale(stale) {
  const rows = stale
    .map(
      (f) => `
      <div class="flex items-baseline justify-between gap-4 px-4 py-3">
        <span class="min-w-0 truncate text-base text-zinc-200" title="${escapeHtml(f.path)}">${escapeHtml(f.path)}</span>
        <span class="shrink-0 text-sm text-zinc-400">${f.last_commit || ""} · ${relativeTime(f.last_commit)}</span>
      </div>`
    )
    .join("");
  $("#stale").innerHTML = `<div class="divide-y divide-edge">${rows}</div>`;
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"]/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[ch]));
}

function wireMetricButtons(langs) {
  document.querySelectorAll(".metric-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".metric-btn").forEach((b) => {
        b.classList.remove("bg-zinc-700", "text-zinc-100");
        b.classList.add("text-zinc-400");
      });
      btn.classList.add("bg-zinc-700", "text-zinc-100");
      btn.classList.remove("text-zinc-400");
      renderLangChart(langs, btn.dataset.metric);
    });
  });
}

async function main() {
  try {
    const [langs, hosts, modules, scripts, commits, stale, meta] = await Promise.all([
      loadJSON("./data/languages.json"),
      loadJSON("./data/hosts.json"),
      loadJSON("./data/modules.json"),
      loadJSON("./data/scripts.json"),
      loadJSON("./data/commits.json"),
      loadJSON("./data/stale.json"),
      loadJSON("./data/meta.json"),
    ]);

    renderMeta(meta);
    renderOverview(langs, hosts, modules, scripts);
    renderLangChart(langs, "lines");
    wireMetricButtons(langs);
    renderLanguages(langs);
    renderCommits(commits);
    renderHostMatrix(hosts);
    renderModules(modules);
    renderScripts(scripts);
    renderStale(stale);
  } catch (err) {
    document.body.insertAdjacentHTML(
      "afterbegin",
      `<pre class="m-5 rounded bg-red-950 p-4 text-red-300">Failed to load dashboard data: ${err.message}</pre>`
    );
  }
}

main();
