const A = "./assets/";
const phoneRow = document.querySelector("#phoneRow");

const phoneDefs = [
  { no: 1, caption: "今日健康首页", kind: "home" },
  { no: 2, caption: "Agent 发现 / 智能洞察页", kind: "discover" },
  { no: 3, caption: "恢复 / 睡眠深度分析页", kind: "analysis" },
  { no: 4, caption: "最新 ECG 解读 + 下一步问题页", kind: "ecg" }
];

function signal() {
  return `<span class="phone-signal"><i></i><i></i><i></i></span>`;
}

function statusBar() {
  return `<div class="status-bar"><span>9:41</span><span class="dynamic-island"></span>${signal()}</div>`;
}

function navHead(title, left = "‹", right = "?") {
  return `
    <div class="nav-head">
      <span class="back-action">${left}</span>
      <h2>${title}</h2>
      <span class="circle-action">${right}</span>
    </div>
  `;
}

function metric(icon, color, label, value, note, tone = "") {
  return `
    <div class="metric-card">
      <span class="label"><i class="dot-icon" style="background:${color}">${icon}</i>${label}</span>
      <strong class="${tone}">${value}</strong>
      <span>${note}</span>
    </div>
  `;
}

function homeScreen() {
  return `
    ${statusBar()}
    <div class="home-head">
      <h2>早上好，Alex 👋</h2>
      <p>今天恢复偏低，建议轻量活动</p>
      <span class="circle-action">+</span>
    </div>
    <section class="panel today-card conclusion-first">
      <div>
        <h3>今日身体解释</h3>
        <h4>恢复偏低，建议关注</h4>
        <p>主要关联睡眠不足、HRV 低于个人基线、夜间心率偏高。</p>
        <div class="primary-actions"><button>查看原因</button><button>生成今日计划</button></div>
      </div>
      <div class="recovery-score"><strong>72</strong><span>/100</span><em>较昨日 +12</em></div>
    </section>
    <div class="metric-grid">
      ${metric("☾", "#f2b633", "睡眠", "6h08m", "低于目标 52m")}
      ${metric("◆", "#ffb22d", "HRV", "42ms", "低于基线 18%")}
      ${metric("♥", "#ffb22d", "静息心率", "58bpm", "高于基线 6bpm")}
    </div>
    <div class="question-title">今天只建议先做一件事</div>
    <div class="action-plan">
      <strong>安排 20 分钟轻量活动</strong>
      <span>避免高强度训练，晚间优先补足睡眠。</span>
    </div>
    <section class="memory-card">
      <div class="memory-title"><span>我记住了</span><button>编辑</button></div>
      <p>你连续 3 次在睡眠不足后，上午专注力会下降。今天建议把高强度任务放到下午。</p>
      <small>基于最近 21 天数据 · 可信度 78%</small>
      <div class="feedback-row"><button>有帮助</button><button>不准确</button><button>不想再看到</button></div>
    </section>
    ${bottomNav("home")}
  `;
}

function discoverScreen() {
  const rows = [
    ["⚠", "恢复下降", "发现：恢复分低于 7 日均值 14 分。依据：睡眠少 52 分钟，HRV 低于基线 18%。影响：上午专注与运动恢复可能下降。建议：今天安排 20 分钟轻量活动。", "置信度 78%", ""],
    ["♥", "夜间心率偏高", "发现：过去 3 晚静息心率高于基线。依据：夜间均值高 6-10bpm。影响：可能和压力或睡眠不足相关。建议：今晚减少刺激性活动。", "置信度 72%", ""],
    ["☾", "近 3 天睡眠不足", "发现：连续 3 晚低于 6.5 小时。依据：睡眠记录和醒后心率同步变化。影响：恢复分波动更明显。建议：生成今晚睡眠计划。", "置信度 66%", "blue"]
  ];
  return `
    ${statusBar()}
    ${navHead("Agent 发现")}
    <div class="discover-head">
      <h3>今天值得关注什么？</h3>
      <p>每条洞察都包含依据、影响和下一步</p>
      <img src="${A}mascot_question.png" alt="" />
    </div>
    <div class="insight-list">
      ${rows.map(([icon, title, desc, severity, tone]) => `
        <article class="insight-card ${tone}">
          <span class="big-icon">${icon}</span>
          <div>
            <h4>${title}</h4>
            <p>${desc}</p>
          </div>
          <span class="severity">${severity}</span>
          <div class="insight-actions"><button>看依据</button><button>生成计划</button><button>不适合我</button></div>
        </article>
      `).join("")}
    </div>
    <p class="discover-foot">这些洞察基于过去 7 天的数据趋势</p>
    ${bottomNav("explore")}
  `;
}

function spark(values, color = "#2385ff") {
  const w = 76;
  const h = 22;
  const max = Math.max(...values);
  const min = Math.min(...values);
  const points = values.map((v, i) => {
    const x = i / (values.length - 1) * (w - 4) + 2;
    const y = h - 3 - (v - min) / Math.max(max - min, 1) * (h - 6);
    return `${x.toFixed(1)},${y.toFixed(1)}`;
  }).join(" ");
  return `<svg class="spark" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none"><polyline points="${points}" fill="none" stroke="${color}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
}

function lineChart() {
  const values = [56, 60, 60, 70, 74, 60, 72, 72];
  const w = 255;
  const h = 112;
  const points = values.map((v, i) => {
    const x = 14 + i * 32;
    const y = 94 - (v - 54) * 2.3;
    return `${x},${y}`;
  }).join(" ");
  const labels = values.map((v, i) => `<text x="${14 + i * 32}" y="${yLabel(v)}" text-anchor="middle">${v}</text>`).join("");
  function yLabel(v) { return 94 - (v - 54) * 2.3 - 10; }
  return `
    <svg class="chart" viewBox="0 0 ${w} ${h}">
      <g stroke="#e4edf9" stroke-width="1">
        <line x1="12" y1="32" x2="242" y2="32"/>
        <line x1="12" y1="60" x2="242" y2="60"/>
        <line x1="12" y1="88" x2="242" y2="88"/>
      </g>
      <g fill="#26324f" font-size="10" font-weight="700">${labels}</g>
      <polyline points="${points}" fill="none" stroke="#166eff" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>
      ${values.map((v, i) => `<circle cx="${14 + i * 32}" cy="${94 - (v - 54) * 2.3}" r="3.5" fill="#166eff"/>`).join("")}
      <g fill="#6d778b" font-size="9" font-weight="650">
        <text x="13" y="108">5/9</text><text x="45" y="108">5/10</text><text x="78" y="108">5/11</text><text x="110" y="108">5/12</text>
        <text x="143" y="108">5/13</text><text x="176" y="108">5/14</text><text x="209" y="108">5/15</text>
      </g>
    </svg>
  `;
}

function analysisScreen() {
  const indicators = [
    ["HRV", [4, 8, 5, 11, 6, 10, 4, 13, 8], "42 ms", "-18% ↓"],
    ["静息心率", [3, 7, 4, 9, 5, 10, 6, 11, 7], "58 bpm", "+6 bpm ↑"],
    ["睡眠时长", [8, 5, 7, 4, 6, 3, 5, 4, 7], "6h 08m", "-48m ↓"],
    ["睡眠规律性", [8, 7, 5, 6, 4, 7, 3, 5, 6], "78 分", "-18% ↓"],
    ["活动能量", [5, 8, 7, 10, 6, 11, 9, 12, 8], "412 kcal", "-12% ↓"]
  ];
  return `
    ${statusBar()}
    ${navHead("恢复 & 睡眠深度分析", "‹", "↗")}
    <section class="score-card">
      <h3>恢复分数</h3>
      <div class="score-main">
        <div><strong>72<span style="font-size:22px">/100</span></strong><small>较昨日 +12</small></div>
        <span class="donut"></span>
        <div class="legend"><span><i></i>恢复良好 30%</span><span><i style="background:#ffc34a"></i>一般 40%</span><span><i style="background:#ff9e81"></i>偏低 30%</span></div>
      </div>
    </section>
    <section class="panel trend-panel">
      <h3>过去 7 天恢复趋势</h3>
      ${lineChart()}
    </section>
    <section class="panel data-list">
      <h3>关键指标 <small style="color:#8b96aa">（过去 7 天）</small></h3>
      ${indicators.map(([name, values, value, change]) => `
        <div class="indicator-row"><span>${name}</span>${spark(values)}<span>${value}</span><span class="neg">${change}</span></div>
      `).join("")}
    </section>
    <section class="panel reason-panel">
      <h3>为什么睡眠影响了我的恢复？</h3>
      ${[
        ["睡眠时长不足", 64],
        ["入睡时间偏晚", 51],
        ["深睡占比偏低", 34]
      ].map(([name, pct], i) => `
        <div class="reason-row"><span class="rank">${i + 1}</span><span>${name}</span><span class="reason-bar"><i style="width:${pct}%"></i></span><span>影响 ${pct}%</span></div>
      `).join("")}
      <button class="large-cta">哪些因素最影响我的恢复？ ›</button>
    </section>
  `;
}

function ecgWave() {
  const pts = [
    "0,58 24,58 30,56 35,58 42,58 48,24 52,84 59,58 82,58 91,53 98,58 139,58",
    "148,58 153,55 158,58 166,58 172,23 176,83 184,58 214,58 222,53 230,58 270,58"
  ].join(" ");
  return `<svg class="ecg-wave" viewBox="0 0 270 110" preserveAspectRatio="none"><polyline points="${pts}" fill="none" stroke="#ff3447" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
}

function ecgScreen() {
  return `
    ${statusBar()}
    ${navHead("本次 ECG 解读")}
    <div class="ecg-meta"><span>2025/05/15 08:23</span><span>时长 30 秒</span><span>25 mm/s</span><span>10 mm/mV</span></div>
    <section class="ecg-conclusion">
      <strong>本次记录呈现窦性心律特征</strong>
      <span>状态分级：可观察 · 仅供健康参考，不构成医疗诊断。</span>
    </section>
    <section class="ecg-wave-card">${ecgWave()}</section>
    <div class="ecg-grid">
      ${metric("", "#166eff", "平均心率", "58 bpm", "参考范围")}
      ${metric("", "#14b86a", "节律观察（非诊断）", "窦性心律", "非诊断", "green")}
      ${metric("", "#14b86a", "信号质量", "良好", "92%", "green")}
    </div>
    <section class="panel context-panel">
      <h3 style="margin:0 0 10px;font-size:13px">上下文解释链 <small style="color:#8b96aa">（各 10 分钟）</small></h3>
      <div class="context-grid">
        <div class="context-card">记录前<br><b>压力 中等</b><br>咖啡 1 杯</div>
        <div class="context-card">记录中<br><b>静息状态</b></div>
        <div class="context-card">记录后<br><b>情绪 平静</b><br>步行 10 分钟</div>
      </div>
    </section>
    <section class="panel source-panel">
      数据来源&nbsp;&nbsp;&nbsp;&nbsp;Apple Health + ECG<br>
      时间范围&nbsp;&nbsp;&nbsp;&nbsp;2025/05/09 - 2025/05/15<br>
      记录设备&nbsp;&nbsp;&nbsp;&nbsp;Apple Watch Series 9<br>
      置信度&nbsp;&nbsp;&nbsp;&nbsp;<b style="color:#11a965">高（92%）</b>
    </section>
    <div class="next-title">建议行动</div>
    <div class="single-cta">
      <strong>保存到长期趋势</strong>
      <span>如伴随胸闷、心悸或呼吸困难，请及时就医。</span>
    </div>
  `;
}

function bottomNav(active) {
  const items = [
    ["home", "今日"],
    ["explore", "洞察"],
    ["record", "记录"],
    ["agent", "分身"],
    ["me", "我的"]
  ];
  return `
    <nav class="bottom-nav" aria-label="底部导航">
      ${items.map(([key, label]) => key === "agent"
        ? `<span class="nav-item twin ${active === key ? "active" : ""}"><i></i>${label}</span>`
        : `<span class="nav-item ${active === key ? "active" : ""}"><i></i>${label}</span>`
      ).join("")}
    </nav>
  `;
}

function phone(def) {
  const screens = {
    home: homeScreen,
    discover: discoverScreen,
    analysis: analysisScreen,
    ecg: ecgScreen
  };
  return `
    <article class="phone-block">
      <div class="phone-shell">
        <span class="side-button"></span>
        <div class="phone-screen">${screens[def.kind]()}</div>
      </div>
      <div class="caption"><span class="badge">${def.no}</span>${def.caption}</div>
    </article>
  `;
}

phoneRow.innerHTML = phoneDefs.map(phone).join("");
