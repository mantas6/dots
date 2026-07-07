// Dashboard renderer: fetches ./data/*.json and paints each section.

const PALETTE = [
  "#60a5fa", "#f472b6", "#34d399", "#fbbf24", "#a78bfa",
  "#fb7185", "#22d3ee", "#a3e635", "#f97316", "#e879f9",
  "#2dd4bf", "#facc15",
];

const $ = (sel) => document.querySelector(sel);

async function loadJSON(path) {
  const res = await fetch(path);
  if (!res.ok) throw new Error(`${path}: ${res.status}`);
  return res.json();
}

const nf = new Intl.NumberFormat("en-US");

function card(label, value, sub) {
  return `
    <div class="rounded-lg border border-edge bg-panel p-4">
      <div class="text-2xl font-bold text-zinc-50">${value}</div>
      <div class="mt-1 text-xs uppercase tracking-wide text-zinc-500">${label}</div>
      ${sub ? `<div class="mt-1 text-xs text-zinc-600">${sub}</div>` : ""}
    </div>`;
}

function renderOverview(langs, hosts, modules, scripts) {
  const cur = langs.current;
  const nLangs = Object.keys(cur.by_language).length;
  $("#overview").innerHTML = [
    card("Lines of code", nf.format(cur.total_lines)),
    card("Files", nf.format(cur.total_files)),
    card("Languages", nf.format(nLangs)),
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

function renderModules(modules) {
  const byCat = {};
  for (const m of modules.modules) (byCat[m.category] ??= []).push(m);
  const cats = Object.keys(byCat).sort();
  $("#modules").innerHTML = cats
    .map((cat) => {
      const items = byCat[cat]
        .map(
          (m) => `
          <li class="flex flex-col gap-0.5 border-l border-edge py-1 pl-3">
            <span class="text-zinc-200">${m.name}</span>
            ${m.files.map((f) => `<span class="text-xs text-zinc-500">${f}</span>`).join("")}
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
              <td class="py-1.5 pr-3 text-zinc-200">${name}</td>
              <td class="py-1.5 pr-3"><span class="rounded px-1.5 py-0.5 text-xs ${badge}">${s.lang}</span></td>
              <td class="py-1.5 text-zinc-400">${s.description || '<span class="text-zinc-700">—</span>'}</td>
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
    const [langs, hosts, modules, scripts, meta] = await Promise.all([
      loadJSON("./data/languages.json"),
      loadJSON("./data/hosts.json"),
      loadJSON("./data/modules.json"),
      loadJSON("./data/scripts.json"),
      loadJSON("./data/meta.json"),
    ]);

    renderMeta(meta);
    renderOverview(langs, hosts, modules, scripts);
    renderLangChart(langs, "lines");
    wireMetricButtons(langs);
    renderHostMatrix(hosts);
    renderModules(modules);
    renderScripts(scripts);
  } catch (err) {
    document.body.insertAdjacentHTML(
      "afterbegin",
      `<pre class="m-5 rounded bg-red-950 p-4 text-red-300">Failed to load dashboard data: ${err.message}</pre>`
    );
  }
}

main();
