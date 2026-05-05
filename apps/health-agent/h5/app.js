const app = document.querySelector("#app");
const tabbar = document.querySelector("#tabbar");

const state = {
  tab: "today",
  screen: "tab",
  detail: null,
  anomalyFilter: "全部"
};

const tabs = [
  { id: "today", label: "今日" },
  { id: "explore", label: "探索" },
  { id: "heart", label: "心脏" },
  { id: "reports", label: "报告" },
  { id: "me", label: "我的" }
];

const colors = {
  recovery: "#42b883",
  heart: "#d95f59",
  sleep: "#6e7bd9",
  workout: "#e1a33d",
  amber: "#d4933d",
  green: "#2f7d68"
};

const todayMetrics = [
  { id: "sleep", label: "睡眠", value: "6h12m", detail: "比平时少 42m", color: colors.sleep, values: [4, 7, 5, 8, 4, 6, 3] },
  { id: "heart", label: "心脏", value: "稳定", detail: "静息心率 58 bpm", color: colors.heart, values: [3, 4, 3, 5, 6, 5, 6] },
  { id: "recovery", label: "恢复", value: "偏弱", detail: "Recovery 62", color: colors.recovery, values: [8, 7, 8, 6, 5, 6, 4] },
  { id: "workout", label: "运动", value: "偏高", detail: "负荷 128", color: colors.workout, values: [2, 3, 5, 8, 7, 6, 5] }
];

const questions = [
  { id: "recovery", title: "我最近恢复得好吗？", subtitle: "HRV 下降 · 静息心率略高", category: "恢复", screen: "recovery" },
  { id: "sleep", title: "昨晚睡得怎么样？", subtitle: "睡眠 6h12m · 夜间心率偏高", category: "睡眠", screen: "sleep" },
  { id: "heart", title: "最近心脏状态稳定吗？", subtitle: "有 1 次 ECG 可作为补充证据", category: "心脏", screen: "heart-status", ecg: true },
  { id: "anomaly", title: "最近有什么异常？", subtitle: "发现 3 个值得关注的变化", category: "异常", screen: "anomaly" }
];

const schemas = {
  recovery: {
    title: "我最近恢复得好吗？",
    range: "过去 30 天",
    summaryTitle: "恢复状态偏弱",
    summary: "过去 7 天你的 HRV 下降，静息心率略高，同时睡眠时间减少。主要建议是降低高强度训练，优先补足睡眠。",
    metrics: [
      ["HRV", "-12%", "低于 30 日基线", colors.recovery],
      ["静息心率", "+4 bpm", "连续 4 天略高", colors.heart],
      ["睡眠", "-42m", "比平时少", colors.sleep],
      ["运动负荷", "+32%", "本周上升", colors.workout]
    ],
    charts: [
      { title: "HRV 30 天趋势", subtitle: "最近 7 天低于个人基线", values: [58, 61, 59, 55, 52, 49, 47, 46, 44, 43, 41, 39], color: colors.recovery }
    ],
    timeline: [
      ["周一", "睡眠 7h10m", "HRV 正常"],
      ["周三", "高强度运动", "HRV 开始下降"],
      ["周五", "睡眠 5h48m", "静息心率偏高"]
    ],
    next: ["只看睡眠因素", "加入运动负荷分析", "和状态好的日子对比"]
  },
  sleep: {
    title: "昨晚睡得怎么样？",
    range: "昨晚",
    summaryTitle: "睡眠偏短",
    summary: "昨晚睡眠 6h12m，比平时少 42 分钟。深睡和 REM 占比偏低，夜间心率略高。",
    metrics: [
      ["总睡眠", "6h12m", "少 42m", colors.sleep],
      ["深睡", "48m", "偏低", colors.sleep],
      ["夜间心率", "58 bpm", "略高", colors.heart],
      ["呼吸", "16/min", "平稳", colors.recovery]
    ],
    charts: [
      { title: "过去 14 天睡眠", subtitle: "本周整体低于平时", values: [7.2, 7.0, 6.8, 7.4, 6.4, 6.1, 6.2, 6.0, 5.8, 6.3, 6.1], color: colors.sleep }
    ],
    next: ["看夜间心率", "和前 7 天对比", "睡眠影响恢复吗？"]
  },
  "heart-status": {
    title: "最近心脏状态稳定吗？",
    range: "过去 30 天",
    summaryTitle: "整体平稳，有轻微变化",
    summary: "最近静息心率略高，HRV 略低。昨日 22:14 有一次 ECG，可作为本次回看的补充证据。",
    ecg: true,
    metrics: [
      ["静息心率", "+3 bpm", "近 7 天略高", colors.heart],
      ["HRV", "-9%", "略低", colors.recovery],
      ["ECG", "1 次", "补充证据", colors.heart],
      ["信号质量", "良好", "可分析", colors.recovery]
    ],
    charts: [
      { title: "静息心率趋势", subtitle: "近 7 天略高于个人基线", values: [54, 55, 55, 56, 58, 58, 59, 58, 57, 58, 59], color: colors.heart }
    ],
    next: ["解读 ECG", "查看睡眠影响", "运动后恢复好吗？"]
  }
};

const anomalies = [
  { title: "静息心率连续 4 天偏高", body: "可能相关：睡眠减少、运动负荷增加。", severity: "建议查看", tags: ["心脏", "睡眠"] },
  { title: "HRV 低于 30 天基线", body: "可能提示恢复压力上升。", severity: "轻微变化", tags: ["恢复"] },
  { title: "昨晚夜间心率偏高", body: "建议结合睡眠结构和晚间活动回看。", severity: "建议查看", tags: ["睡眠", "心脏"] }
];

function sparkline(values, color = colors.green, height = 42) {
  const width = 160;
  const min = Math.min(...values);
  const max = Math.max(...values);
  const range = Math.max(max - min, 1);
  const points = values.map((value, index) => {
    const x = (index / (values.length - 1)) * width;
    const y = height - ((value - min) / range) * (height - 6) - 3;
    return `${x.toFixed(1)},${y.toFixed(1)}`;
  }).join(" ");
  return `<svg class="spark" viewBox="0 0 ${width} ${height}" preserveAspectRatio="none" aria-hidden="true">
    <polyline points="${points}" fill="none" stroke="${color}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`;
}

function chart(values, color = colors.green) {
  const width = 360;
  const height = 140;
  const min = Math.min(...values);
  const max = Math.max(...values);
  const range = Math.max(max - min, 1);
  const points = values.map((value, index) => {
    const x = 10 + (index / (values.length - 1)) * (width - 20);
    const y = height - 14 - ((value - min) / range) * (height - 28);
    return `${x.toFixed(1)},${y.toFixed(1)}`;
  }).join(" ");
  return `<svg class="chart-svg" viewBox="0 0 ${width} ${height}" preserveAspectRatio="none">
    <line x1="10" y1="24" x2="${width - 10}" y2="24" stroke="#dde7e1" />
    <line x1="10" y1="70" x2="${width - 10}" y2="70" stroke="#dde7e1" />
    <line x1="10" y1="116" x2="${width - 10}" y2="116" stroke="#dde7e1" />
    <polyline points="${points}" fill="none" stroke="${color}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`;
}

function renderTabbar() {
  tabbar.innerHTML = tabs.map((tab) => `
    <button class="tab-btn ${state.screen === "tab" && state.tab === tab.id ? "active" : ""}" data-tab="${tab.id}">
      <span class="tab-dot"></span>
      <span>${tab.label}</span>
    </button>
  `).join("");
}

function render() {
  renderTabbar();
  if (state.screen === "detail") return renderDetail(state.detail);
  if (state.screen === "ecg") return renderECGDetail();
  if (state.screen === "onboarding") return renderOnboarding();
  if (state.tab === "explore") return renderExplore();
  if (state.tab === "heart") return renderHeart();
  if (state.tab === "reports") return renderReports();
  if (state.tab === "me") return renderMe();
  return renderToday();
}

function renderToday() {
  app.innerHTML = `
    <div class="page">
      <header class="topbar">
        <div>
          <h1 class="title-xl">今日</h1>
          <p class="eyebrow">5 月 5 日 · 星期二</p>
        </div>
        <div class="sync-pill">已与 Apple 健康同步</div>
      </header>

      <section class="hero">
        <div class="hero-content">
          <div class="hero-grid">
            <div>
              <p class="hero-label">今日身体状态</p>
              <h2 class="hero-state">偏弱</h2>
              <p class="hero-copy">你的身体恢复水平偏低，建议关注睡眠与恢复，适当调整今天的计划。</p>
            </div>
            <div class="ring" aria-label="Recovery 62">
              <div class="ring-inner">
                <div>
                  <div class="ring-title">Recovery</div>
                  <div class="ring-score">62</div>
                </div>
              </div>
            </div>
          </div>
          <div class="factor-row">
            <span class="factor">睡眠不足</span>
            <span class="factor">HRV 下降</span>
            <span class="factor">心率略高</span>
          </div>
          <div class="button-row">
            <button class="ghost-btn" data-detail="recovery">查看原因</button>
            <button class="primary-btn" data-detail="recovery">今日建议</button>
          </div>
        </div>
      </section>

      <section class="section-title"><h2>Agent 发现</h2><span>查看</span></section>
      <section class="card agent-card">
        ${agentRow("睡眠减少", "昨晚睡眠比平时少 1 小时 12 分钟，深睡和 REM 占比偏低，可能影响恢复。", "睡眠")}
        ${agentRow("运动负荷上升", "过去 7 天运动负荷比上周上升 32%，身体压力增加，建议注意恢复与放松。", "运动")}
      </section>

      <section class="section-title"><h2>今日模块</h2></section>
      <section class="module-grid">
        ${todayMetrics.map(moduleCard).join("")}
      </section>

      <section class="section-title"><h2>继续探索</h2></section>
      <section class="insight-list">
        ${questions.map(insightCard).join("")}
      </section>

      ${askbar()}
    </div>
  `;
}

function agentRow(title, body, icon) {
  return `<div class="agent-row">
    <div class="mini-icon">${icon.slice(0, 2)}</div>
    <div><h3>${title}</h3><p>${body}</p></div>
  </div>`;
}

function moduleCard(metric) {
  return `<article class="card module-card">
    <h3>${metric.label}</h3>
    <div class="module-value">${metric.value}</div>
    <p>${metric.detail}</p>
    ${sparkline(metric.values, metric.color)}
  </article>`;
}

function insightCard(question) {
  const color = question.category === "睡眠" ? colors.sleep : question.category === "心脏" ? colors.heart : question.category === "异常" ? colors.amber : colors.recovery;
  return `<button class="insight-card" data-detail="${question.screen}">
    <span class="insight-icon" style="color:${color};background:${color}22">${question.category.slice(0, 1)}</span>
    <span>
      <h3>${question.title} ${question.ecg ? `<span class="badge">ECG</span>` : ""}</h3>
      <p>${question.subtitle}</p>
    </span>
    <span class="chev">›</span>
  </button>`;
}

function askbar() {
  return `<div class="askbar">
    <span class="round-icon">问</span>
    <input aria-label="问问你的健康数据" placeholder="问问你的健康数据..." />
    <button class="send-btn" data-detail="recovery">↑</button>
  </div>`;
}

function renderDetail(id) {
  if (id === "anomaly") return renderAnomaly();
  const schema = schemas[id] || schemas.recovery;
  app.innerHTML = `
    <div class="page">
      ${detailHeader(schema.range, schema.title)}
      <section class="card summary-card">
        <h2>${schema.summaryTitle}</h2>
        <p class="body-copy">${schema.summary}</p>
        <p class="notice">本页不是医学诊断，仅帮助你回看 Apple Health 数据。</p>
      </section>
      <section class="section-title"><h2>关键证据</h2></section>
      <section class="delta-grid">
        ${schema.metrics.map(([label, value, detail, color]) => deltaCard(label, value, detail, color)).join("")}
      </section>
      ${schema.ecg ? `<section class="section-title"><h2>ECG 补充证据</h2><span data-screen="ecg">查看详情</span></section>${ecgCard(true)}` : ""}
      ${schema.charts.map((item) => chartCard(item)).join("")}
      ${schema.timeline ? timelineCard(schema.timeline) : ""}
      <section class="section-title"><h2>下一步探索</h2></section>
      <div class="chips">${schema.next.map((text) => `<button class="chip" data-detail="${id}">${text}</button>`).join("")}</div>
    </div>
  `;
}

function detailHeader(range, title) {
  return `<header class="detail-header">
    <button class="back-btn" data-back>‹</button>
    <div>
      <p class="eyebrow">${range}</p>
      <h1 class="title-lg">${title}</h1>
    </div>
  </header>`;
}

function deltaCard(label, value, detail, color) {
  return `<article class="delta-card" style="background:${color}14">
    <h3>${label}</h3>
    <strong>${value}</strong>
    <p>${detail}</p>
  </article>`;
}

function chartCard(item) {
  return `<section class="section-title"><h2>${item.title}</h2></section>
    <section class="card chart-card">
      <p class="body-copy">${item.subtitle}</p>
      ${chart(item.values, item.color)}
    </section>`;
}

function timelineCard(rows) {
  return `<section class="section-title"><h2>时间线</h2></section>
    <section class="card chart-card timeline">
      ${rows.map((row) => `<div class="timeline-row"><span class="timeline-dot"></span><div><h3>${row[0]} · ${row[1]}</h3><p>${row[2]}</p></div></div>`).join("")}
    </section>`;
}

function ecgCard(clickable = false) {
  return `<section class="card ecg-card" ${clickable ? `data-screen="ecg"` : ""}>
    <h2>昨日 22:14 · 本次 ECG 可分析</h2>
    <div class="stat-grid">
      <div class="stat"><span>主要观察</span><strong>节律整体稳定</strong></div>
      <div class="stat"><span>平均心率</span><strong>82 bpm</strong></div>
      <div class="stat"><span>信号质量</span><strong>良好</strong></div>
    </div>
    <img class="ecg-wave" src="./assets/ecg-waveform-sample.png" alt="ECG 波形样例" />
    <p class="notice">本解读仅供参考，不能替代专业医疗建议，不构成医学诊断。</p>
  </section>`;
}

function renderECGDetail() {
  app.innerHTML = `
    <div class="page">
      ${detailHeader("昨日 22:14", "解读最新一次 ECG")}
      ${ecgCard(false)}
      ${chartCard({ title: "RR 间期", subtitle: "平均 731 ms，波动较平稳", values: [720, 738, 714, 731, 744, 729, 718, 735, 728], color: colors.heart })}
      <section class="section-title"><h2>相关背景</h2></section>
      <section class="delta-grid">
        ${deltaCard("昨晚睡眠", "6h12m", "略低", colors.sleep)}
        ${deltaCard("HRV", "32 ms", "略低", colors.recovery)}
        ${deltaCard("静息心率", "58 bpm", "略高", colors.heart)}
        ${deltaCard("质量", "良好", "干扰少", colors.green)}
      </section>
      <section class="section-title"><h2>下一步</h2></section>
      <div class="chips">
        <button class="chip">和上次 ECG 对比</button>
        <button class="chip">查看前 24 小时</button>
        <button class="chip">记录症状</button>
      </div>
    </div>
  `;
}

function renderAnomaly() {
  const filtered = state.anomalyFilter === "全部" ? anomalies : anomalies.filter((item) => item.tags.includes(state.anomalyFilter));
  app.innerHTML = `
    <div class="page">
      ${detailHeader("过去 14 天", "最近有什么异常？")}
      <section class="card summary-card"><h2>发现 ${anomalies.length} 个值得关注的变化</h2><p class="body-copy">这些变化按个人基线、持续时间和数据完整度排序。</p></section>
      <div class="filter-row">
        ${["全部", "睡眠", "心脏", "恢复", "运动"].map((f) => `<button class="filter ${state.anomalyFilter === f ? "active" : ""}" data-filter="${f}">${f}</button>`).join("")}
      </div>
      <section class="list-stack">
        ${filtered.map((item) => `<article class="card insight-card" data-detail="recovery">
          <span class="insight-icon" style="color:${colors.amber};background:${colors.amber}22">变</span>
          <span><h3>${item.title} <span class="badge">${item.severity}</span></h3><p>${item.body}</p></span><span class="chev">›</span>
        </article>`).join("")}
      </section>
    </div>
  `;
}

function renderExplore() {
  const items = [
    ["运动对睡眠有帮助吗？", "对比运动日和非运动日", "sleep"],
    ["状态好的日子有什么共同点？", "提取可复制模式", "recovery"],
    ["工作日和周末有什么不同？", "观察生活节奏影响", "sleep"],
    ["我该关注哪个指标？", "按变化和偏好排序", "anomaly"]
  ];
  app.innerHTML = `<div class="page">
    <header class="topbar"><div><h1 class="title-xl">探索</h1><p class="eyebrow">把健康数据变成可回答的问题</p></div></header>
    <section class="insight-list">${items.map(([title, body, screen]) => `<button class="insight-card" data-detail="${screen}"><span class="insight-icon" style="color:${colors.green};background:${colors.green}22">问</span><span><h3>${title}</h3><p>${body}</p></span><span class="chev">›</span></button>`).join("")}</section>
  </div>`;
}

function renderHeart() {
  app.innerHTML = `<div class="page">
    <header class="topbar"><div><h1 class="title-xl">心脏</h1><p class="eyebrow">连续指标为主，ECG 作为补充证据</p></div></header>
    ${ecgCard(true)}
    ${chartCard({ title: "静息心率", subtitle: "近 7 天略高于个人基线", values: [54,55,55,56,58,58,59,58], color: colors.heart })}
    <section class="insight-list">${insightCard(questions[2])}</section>
  </div>`;
}

function renderReports() {
  app.innerHTML = `<div class="page">
    <header class="topbar"><div><h1 class="title-xl">报告</h1><p class="eyebrow">每周复盘健康状态</p></div></header>
    <section class="card report-card">
      <h2>本周健康报告</h2>
      <p class="body-copy">本周整体偏弱但可恢复。主要变化来自睡眠减少、运动负荷上升和 HRV 下降。</p>
      <div class="delta-grid" style="margin-top:16px">
        ${deltaCard("睡眠", "-42m", "平均每晚", colors.sleep)}
        ${deltaCard("运动", "+32%", "负荷上升", colors.workout)}
        ${deltaCard("HRV", "-12%", "低于基线", colors.recovery)}
        ${deltaCard("ECG", "1 次", "补充证据", colors.heart)}
      </div>
    </section>
    ${chartCard({ title: "本周趋势", subtitle: "睡眠和恢复同步走弱", values: [7,6.8,6.2,5.9,6.1,6.0,6.2], color: colors.green })}
  </div>`;
}

function renderMe() {
  app.innerHTML = `<div class="page">
    <header class="topbar"><div><h1 class="title-xl">我的</h1><p class="eyebrow">数据、隐私和个性化</p></div></header>
    <button class="insight-card" data-screen="onboarding"><span class="insight-icon" style="color:${colors.green};background:${colors.green}22">初</span><span><h3>重新生成我的健康首页</h3><p>选择关注方向、权限和展示偏好。</p></span><span class="chev">›</span></button>
    <section class="section-title"><h2>数据与隐私</h2></section>
    <section class="card permission-card">
      <h2>HealthKit 权限</h2>
      <p class="body-copy">已授权：睡眠、心率、静息心率、运动。待授权：HRV、ECG、血氧。</p>
      <p class="notice">原始健康数据默认留在设备本地。</p>
    </section>
  </div>`;
}

function renderOnboarding() {
  const focus = ["睡眠", "恢复", "心脏", "运动", "压力代理", "ECG", "体重", "整体健康"];
  app.innerHTML = `<div class="page">
    ${detailHeader("初始化", "先让 App 了解你关心什么")}
    <p class="body-copy">Health Agent 会根据你的关注方向渐进式请求 HealthKit 权限，并生成第一批洞察按钮。</p>
    <section class="card permission-card">
      <h2>你最想了解什么？</h2>
      <div class="chip-row" style="margin-top:14px">${focus.map((x, i) => `<button class="chip" style="${i < 3 ? `background:${colors.green};color:white` : ""}">${x}</button>`).join("")}</div>
    </section>
    <section class="card permission-card">
      <h2>权限预览</h2>
      <p class="body-copy">分析恢复状态需要睡眠、HRV、静息心率和运动数据。ECG 会在心脏相关问题中单独请求。</p>
    </section>
  </div>`;
}

tabbar.addEventListener("click", (event) => {
  const button = event.target.closest("[data-tab]");
  if (!button) return;
  state.tab = button.dataset.tab;
  state.screen = "tab";
  state.detail = null;
  render();
});

app.addEventListener("click", (event) => {
  const back = event.target.closest("[data-back]");
  if (back) {
    state.screen = "tab";
    state.detail = null;
    render();
    return;
  }

  const detail = event.target.closest("[data-detail]");
  if (detail) {
    state.screen = "detail";
    state.detail = detail.dataset.detail;
    window.scrollTo({ top: 0, behavior: "smooth" });
    render();
    return;
  }

  const screen = event.target.closest("[data-screen]");
  if (screen) {
    state.screen = screen.dataset.screen;
    window.scrollTo({ top: 0, behavior: "smooth" });
    render();
    return;
  }

  const filter = event.target.closest("[data-filter]");
  if (filter) {
    state.anomalyFilter = filter.dataset.filter;
    render();
  }
});

render();
