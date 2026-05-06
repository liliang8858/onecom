const sceneTabs = document.querySelector("#sceneTabs");
const sceneRoot = document.querySelector("#sceneRoot");

const A = "./assets/";

const scenes = [
  {
    id: "core",
    label: "今日健康核心",
    footer: ["理解数据", "发现关键", "给出建议", "陪你变好"],
    phones: [
      { no: 1, title: "首页 / 今日健康状态", kind: "home" },
      { no: 2, title: "Agent 发现 / 智能洞察", kind: "discover" },
      { no: 3, title: "恢复 / 睡眠深度分析", kind: "recoveryDeep" },
      { no: 4, title: "最新 ECG 解读", kind: "ecg" }
    ]
  },
  {
    id: "onboarding",
    label: "授权与行动",
    footer: ["授权连接", "行动建议", "趋势管理", "偏好提醒"],
    phones: [
      { no: 1, title: "首次引导 / 数据授权", kind: "onboarding" },
      { no: 2, title: "今日建议 / 行动计划", kind: "advice" },
      { no: 3, title: "趋势中心 / 30 天趋势", kind: "trend" },
      { no: 4, title: "偏好与提醒设置", kind: "settings" }
    ]
  },
  {
    id: "weekly",
    label: "异常与心脏",
    footer: ["今日状态", "恢复分析", "异常解释", "心脏 ECG"],
    phones: [
      { no: 1, title: "首页 / 今日健康状态", kind: "homeCompact" },
      { no: 2, title: "恢复与睡眠分析", kind: "recoveryMatrix" },
      { no: 3, title: "异常中心 / 本周解释", kind: "anomaly" },
      { no: 4, title: "心脏状态与 ECG", kind: "heartEcg" }
    ]
  },
  {
    id: "agent",
    label: "问答与周报",
    footer: ["智能问答", "今日时间线", "证据详情", "健康周报"],
    phones: [
      { no: 1, title: "智能问答", kind: "chat" },
      { no: 2, title: "今日时间线", kind: "timeline" },
      { no: 3, title: "证据详情", kind: "evidence" },
      { no: 4, title: "健康周报", kind: "report" }
    ]
  }
];

let activeScene = scenes[0].id;

function iconBars() {
  return `<div class="signals"><i></i><i></i><i></i></div>`;
}

function statusBar() {
  return `<div class="status"><span>9:41</span><span class="island"></span><span>${iconBars()}</span></div>`;
}

function chart(color = "#1264ff", values = [30, 44, 38, 56, 48, 62, 58, 74]) {
  const width = 260;
  const height = 96;
  const max = Math.max(...values);
  const min = Math.min(...values);
  const points = values.map((v, i) => {
    const x = (i / (values.length - 1)) * (width - 20) + 10;
    const y = height - 12 - ((v - min) / Math.max(max - min, 1)) * (height - 24);
    return `${x.toFixed(1)},${y.toFixed(1)}`;
  }).join(" ");
  return `<svg class="chart" viewBox="0 0 ${width} ${height}" preserveAspectRatio="none">
    <line x1="10" y1="28" x2="${width - 10}" y2="28" stroke="#dfeafa"/>
    <line x1="10" y1="58" x2="${width - 10}" y2="58" stroke="#dfeafa"/>
    <line x1="10" y1="88" x2="${width - 10}" y2="88" stroke="#dfeafa"/>
    <polyline points="${points}" fill="none" stroke="${color}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`;
}

function miniChart(color = "#1264ff") {
  return `<svg class="mini-chart" viewBox="0 0 100 32" preserveAspectRatio="none">
    <polyline points="0,20 12,14 24,18 36,10 48,16 60,12 72,18 84,9 100,14" fill="none" stroke="${color}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`;
}

function phone(shell) {
  return `<article class="phone-wrap">
    <div class="phone"><div class="screen">${statusBar()}${renderKind(shell.kind)}</div></div>
    <div class="caption"><span class="badge-num">${shell.no}</span>${shell.title}</div>
  </article>`;
}

function head(title, subtitle = "", mascot = "") {
  return `<div class="screen-head">
    <div class="screen-title"><h2>${title}</h2>${subtitle ? `<p>${subtitle}</p>` : ""}</div>
    ${mascot ? `<img class="mascot" src="${A}${mascot}.png" alt="">` : `<span class="circle-btn">＋</span>`}
  </div>`;
}

function bottomNav(active = "首页", labels = ["首页", "发现", "小智", "趋势", "我的"]) {
  return `<nav class="bottom-nav">${labels.map((label) => label === "小智"
    ? `<span class="nav-item"><span class="agent-orb"><img src="${A}mascot_question.png" alt=""></span></span>`
    : `<span class="nav-item ${label === active ? "active" : ""}"><b>${navIcon(label)}</b><small>${label}</small></span>`).join("")}</nav>`;
}

function navIcon(label) {
  return { 首页: "⌂", 发现: "⌕", 趋势: "▥", 我的: "♙", 对话: "✚", 时间线: "⌘", 数据: "◉" }[label] || "•";
}

function metric(label, value, note, color = "blue") {
  return `<div class="metric panel"><span>${label}</span><b class="${color}">${value}</b><small>${note}</small></div>`;
}

function homeScreen(compact = false) {
  return `${head("早上好，Alex 👋", "数据来自 Apple Health 与 ECG", "mascot_point")}
    <section class="hero-card panel">
      <h3 class="card-title blue">今天身体状态怎么样？</h3>
      <p><b class="red">今日状态：建议关注</b></p>
      <p style="max-width:66%;color:#50627f;font-size:12px;line-height:1.5">你的恢复能力偏低，睡眠不足可能导致心率偏高，建议适度放松。</p>
      <div class="score-ring"><span>62</span></div>
    </section>
    <div class="metric-grid">
      ${metric("睡眠", compact ? "6h12m" : "6h08m", "低于目标", "blue")}
      ${metric("HRV", compact ? "48ms" : "42ms", "低于基线", "red")}
      ${metric("静息心率", "58bpm", "高于基线", "red")}
      ${metric("活动负荷", compact ? "312kcal" : "中等偏低", "较昨日", "green")}
    </div>
    <h4>你可能想了解</h4>
    <div class="question-grid">
      ${["我最近恢复得好吗？", "昨晚睡得怎么样？", "为什么这周状态差？", "解读最新一次 ECG"].map((q) => `<button class="chip">${q}</button>`).join("")}
    </div>
    <section class="panel soft" style="margin-top:10px;padding:10px;display:flex;gap:10px;align-items:center">
      <img src="${A}mascot_question.png" alt="" style="width:48px"><p style="font-size:12px;margin:0;color:#28528d">先别着急，我来帮你一起看看细节吧！</p>
    </section>
    ${bottomNav("首页")}`;
}

function discoverScreen() {
  const items = [
    ["⚠", "恢复下降", "HRV 下降且睡眠偏短，身体恢复不足。", "置信度 78%"],
    ["❤️", "夜间心率偏高", "过去 3 晚静息心率高于你的基线 6-10bpm。", "置信度 72%"],
    ["🌙", "近 3 天睡眠不足", "连续 3 晚低于 6.5 小时，影响恢复与专注力。", "置信度 66%"],
    ["💙", "有新的 ECG 可辅助分析", "5/15 08:23 的 ECG 已传输至本地。", "置信度 80%"]
  ];
  return `${head("Agent 发现", "今天值得关注什么？", "mascot_question")}
    <div class="list">${items.map(([i, t, b, s]) => `<div class="list-item panel"><span class="icon">${i}</span><div><b>${t}</b><p style="margin:4px 0 0;color:#607699;font-size:12px">${b}</p></div><span class="severity">${s}</span></div>`).join("")}</div>
    <p style="text-align:center;color:#8a9bb4;font-size:12px">这些洞察基于过去 7 天的数据趋势</p>
    ${bottomNav("发现")}`;
}

function recoveryDeep() {
  return `${head("恢复 & 睡眠深度分析", "", "")}
    <section class="panel" style="padding:12px;background:linear-gradient(135deg,#1475ff,#42d8ef);color:white">
      <div style="display:flex;justify-content:space-between;align-items:center"><div><b>恢复分数</b><h2 style="margin:4px 0;font-size:42px">72<small>/100</small></h2><span>较昨日 +12</span></div><div class="donut"></div></div>
    </section>
    <section class="panel" style="padding:12px;margin-top:10px"><b>过去 7 天恢复趋势</b>${chart("#1264ff", [56, 60, 70, 74, 60, 72, 72])}</section>
    <section class="panel" style="padding:12px;margin-top:10px"><b>关键指标</b>
      ${["HRV 42ms -18%", "静息心率 58bpm +6", "睡眠时长 6h08m -48m", "活动能量 412kcal -12%"].map((x) => `<div style="display:grid;grid-template-columns:92px 1fr 48px;gap:6px;align-items:center;margin-top:8px;font-size:12px"><span>${x.split(" ")[0]}</span>${miniChart("#2589ff")}<b class="${x.includes("+") ? "red" : "blue"}">${x.split(" ").slice(-1)}</b></div>`).join("")}
    </section>
    <section class="panel" style="padding:12px;margin-top:10px"><b>为什么睡眠影响了我的恢复？</b>${["睡眠时长不足", "入睡时间偏晚", "深睡占比偏低"].map((t, i) => `<div class="bar-row"><span>${i + 1}. ${t}</span><span class="bar"><i style="width:${[64,51,34][i]}%"></i></span><span>${[64,51,34][i]}%</span></div>`).join("")}</section>`;
}

function ecgScreen() {
  return `${head("解读最新一次 ECG", "", "")}
    <section class="panel" style="padding:12px">
      <small>2025/05/15 08:23　时长 30 秒　25 mm/s</small>
      <div style="margin-top:8px;background:#fff4f4;border:1px solid #ffd2d2;border-radius:12px;padding:8px">${ecgWave()}</div>
    </section>
    <div class="metric-grid">${metric("平均心率", "58bpm", "参考范围", "blue")}${metric("节律观察", "窦性心律", "非诊断", "green")}${metric("信号质量", "良好", "92%", "green")}${metric("记录状态", "中等", "静息状态", "orange")}</div>
    <section class="panel" style="padding:12px;margin-top:10px"><b>记录前 / 中 / 后</b><div class="metric-grid">${metric("记录前", "压力中等", "咖啡 1 杯")}${metric("记录中", "静息", "状态平稳")}${metric("记录后", "情绪平稳", "步行 10 分钟")}${metric("置信度", "高", "92%")}</div></section>
    <h4>下一步想了解什么？</h4><div class="question-grid">${["这和睡眠有关吗？", "对恢复有什么影响？", "心律稳定性如何？", "生成今日建议"].map((q) => `<button class="chip">${q}</button>`).join("")}</div>
    <p style="font-size:11px;color:#607699">这不是医学诊断。如持续不适，请咨询医生。</p>`;
}

function onboarding() {
  return `${head("欢迎使用 Health Agent", "每天多一点了解，成就更健康的自己 ✨", "mascot_hero_wave")}
    <section class="panel" style="padding:12px"><b>授权 Apple Health 数据</b><p style="font-size:12px;color:#607699">我们仅读取以下数据，用于生成个性化洞察与建议。</p>${["睡眠", "心率", "HRV（心率变异性）", "活动与运动", "ECG（心电图）", "血氧饱和度"].map((x, i) => `<div class="setting"><span>${x}</span><span class="${i < 4 ? "green" : "blue"}">${i < 4 ? "已授权 ●" : "可选授权 ○"}</span></div>`).join("")}</section>
    <section class="panel soft" style="margin-top:10px;padding:12px"><b>你的数据，始终由你掌控</b><p style="font-size:12px;color:#607699">默认仅在本地处理，除非你明确同意上传摘要。</p></section>
    <button class="primary-btn" style="width:100%;margin-top:14px">继续并授权</button><button class="secondary-btn" style="width:100%;margin-top:8px">先看看体验</button>`;
}

function advice() {
  const rows = [["🌙", "今晚早点休息", "预计提升睡眠质量 +15%"], ["🏃", "降低训练强度", "建议低强度有氧 20 分钟"], ["🚶", "午餐后散步 10 分钟", "预计提升能量水平"], ["🫁", "进行 3 分钟呼吸练习", "预计降低压力水平"]];
  return `${head("今日行动建议", "5月15日 星期四", "mascot_point")}
    <section class="panel soft" style="padding:12px"><b>今天更适合轻恢复</b><span class="score-ring" style="float:right"><span>72</span></span><p style="font-size:12px;color:#607699">恢复状态一般，睡眠不足，训练负荷需略降。</p></section>
    <h4>为你推荐的行动</h4><div class="list">${rows.map(([i, t, b]) => `<div class="list-item panel"><span class="icon">${i}</span><div><b>${t}</b><p style="font-size:12px;color:#607699;margin:4px 0 0">${b}</p></div><span>›</span></div>`).join("")}</div>
    <section class="panel" style="padding:12px;margin-top:10px"><b>今日完成进度</b><div style="display:flex;gap:8px;margin-top:10px">${["", "", "", ""].map(() => `<span style="width:28px;height:28px;border:2px solid #c7d9f2;border-radius:50%"></span>`).join("")}</div></section>`;
}

function trend() {
  return `${head("趋势中心", "", "")}
    <div class="segmented" style="grid-template-columns:repeat(4,1fr)"><button class="active">恢复</button><button>睡眠</button><button>心脏</button><button>异常</button></div>
    <div class="segmented" style="margin-top:8px;grid-template-columns:repeat(3,1fr)"><button class="active">30 天</button><button>7 天</button><button>90 天</button></div>
    <section class="panel" style="padding:12px;margin-top:10px"><b>恢复分数趋势 <span class="blue" style="float:right">72</span></b>${chart("#1264ff", [58, 70, 66, 74, 60, 68, 72])}</section>
    <section class="panel" style="padding:12px;margin-top:10px">${["平均睡眠时长 6h32m", "HRV 平均值 46ms", "静息心率 57bpm", "近期负荷 偏高"].map((t, i) => `<div style="display:grid;grid-template-columns:110px 1fr;gap:8px;align-items:center;margin-top:8px;font-size:12px"><b>${t}</b>${miniChart(i === 2 ? "#f05162" : "#1264ff")}</div>`).join("")}</section>
    ${bottomNav("趋势", ["首页", "发现", "小智", "趋势", "我的"])}`;
}

function settings() {
  return `${head("偏好与提醒设置", "", "")}
    <section class="panel" style="padding:12px"><b>我的关注重点</b><div class="question-grid">${["睡眠质量", "恢复状态", "心脏稳定", "异常提醒"].map((x, i) => `<button class="chip" style="${i < 3 ? "background:#1264ff;color:white" : ""}">${x}</button>`).join("")}</div></section>
    <section class="panel" style="padding:12px;margin-top:10px"><b>提醒设置</b><div class="toggle-row">${["每日健康总结", "行动建议提醒", "喝水提醒", "减少咖啡因提醒"].map((x, i) => `<div class="setting"><span>${x}</span><span class="switch ${i === 3 ? "off" : ""}"></span></div>`).join("")}</div></section>
    <section class="panel" style="padding:12px;margin-top:10px"><b>数据共享与改进</b>${["仅本地处理", "允许上传脱敏摘要", "查看上传记录"].map((x, i) => `<div class="setting"><span>${x}</span><span class="switch ${i === 1 ? "off" : ""}"></span></div>`).join("")}</section>`;
}

function recoveryMatrix() {
  return `${head("我最近恢复得好吗？", "昨晚睡得怎么样？", "mascot_report")}
    <section class="panel soft" style="padding:12px"><b>恢复状态：<span class="orange">中等</span></b><p style="font-size:12px;color:#607699">较上周略下降</p></section>
    <div class="segmented" style="margin-top:10px"><button class="active">近 7 天</button><button>前 7 天</button></div>
    <div class="metric-grid">${metric("HRV", "48ms", "↓18%", "blue")}${metric("静息心率", "58bpm", "↑6%", "red")}${metric("睡眠时长", "6h12m", "↓1h48m", "purple")}${metric("活动能量", "312kcal", "↑12%", "green")}</div>
    <section class="panel" style="padding:12px;margin-top:10px"><b>为什么会这样</b>${["睡眠减少", "运动负荷偏高", "夜间心率偏高"].map((x, i) => `<div class="bar-row"><span>${i + 1}. ${x}</span><span class="bar"><i style="width:${[60,30,10][i]}%"></i></span><span>${[60,30,10][i]}%</span></div>`).join("")}</section>
    <div style="display:flex;gap:8px;margin-top:12px"><button class="secondary-btn">查看本周变化</button><button class="primary-btn">生成今日建议</button></div>`;
}

function anomaly() {
  return `${head("为什么这周状态差？", "最近有什么异常？", "")}
    <section class="panel" style="padding:12px;background:#fff2f5"><b>本周状态较上周下降 <span class="red">18%</span></b>${chart("#f05162", [76, 72, 70, 68, 66, 63, 58])}</section>
    <section class="panel" style="padding:12px;margin-top:10px"><b>影响因素排名</b>${["睡眠时长下降", "HRV 低于30天基线", "静息心率连续4天偏高", "夜间心率升高"].map((x, i) => `<div class="bar-row"><span>${i + 1}. ${x}</span><span class="bar"><i style="width:${[45,30,15,10][i]}%;background:${i===0?"#18c8d8":"#1264ff"}"></i></span><span>${[45,30,15,10][i]}%</span></div>`).join("")}</section>
    <section class="panel" style="padding:12px;margin-top:10px"><b>本周异常（3 项）</b>${["静息心率连续4天偏高", "HRV 低于30天基线", "睡眠时长比上周明显下降"].map((x) => `<div class="setting"><span>${x}</span><span class="severity">中等</span></div>`).join("")}</section>
    <section class="panel soft" style="padding:10px;margin-top:10px;display:flex;gap:8px;align-items:center"><img src="${A}mascot_question.png" style="width:46px"><p style="font-size:12px;color:#28528d">我们按你的问题组织数据与解释，而不是堆砌指标。</p></section>`;
}

function heartEcg() {
  return `${head("最近心脏状态稳定吗？", "解读最新一次 ECG", "mascot_stethoscope")}
    <section class="panel soft" style="padding:12px"><b>近期心脏状态：<span class="green">总体稳定</span></b><p style="font-size:12px;color:#607699">未见明显异常模式，分析置信度中高。</p></section>
    <section class="panel" style="padding:12px;margin-top:10px"><b>最新一次 ECG</b><span class="severity" style="float:right">分享</span>${ecgWave("#2178ff")}</section>
    <div class="metric-grid">${metric("节律稳定性", "稳定", "无明显早搏", "green")}${metric("ECG 平均心率", "66bpm", "正常范围", "blue")}${metric("HRV", "46ms", "中等", "green")}${metric("睡眠", "6h20m", "平均", "blue")}</div>
    <p style="font-size:11px;color:#607699">这不是医学诊断。如持续不适，请咨询医生。</p>`;
}

function chat() {
  return `${head("你好！今天想了解什么？", "", "mascot_hero_wave")}
    <div class="chat"><div class="bubble user">为什么我今天这么累？</div><div class="bubble">可能与睡眠不足和恢复下降有关。</div><div class="bubble">昨晚深睡时间偏少，HRV 下降，静息心率偏高，会让你白天更容易疲劳。</div></div>
    <h4>你可以试试问我：</h4><div class="question-grid">${["查看证据", "给我建议", "看看最近变化", "需要关注什么"].map((q) => `<button class="chip">${q}</button>`).join("")}</div>
    <div class="panel" style="position:absolute;left:14px;right:14px;bottom:62px;padding:9px;color:#8a9bb4">输入问题或描述你的感受... <span style="float:right" class="blue">➤</span></div>
    ${bottomNav("对话", ["对话", "时间线", "数据", "我的"])}`;
}

function timeline() {
  return `${head("今日时间线", "5月15日 星期四", "")}
    <section class="panel soft" style="padding:12px"><b>今天身体节奏</b><div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-top:8px">${["睡眠不足", "午后活动提升", "晚间恢复中"].map((x)=>`<span class="chip">${x}</span>`).join("")}</div></section>
    <div class="timeline" style="margin-top:12px">${[
      ["07:42", "睡眠结束", "睡眠 6h12m，深睡偏少"],
      ["10:30", "上午能量偏低", "HRV 下降，身体负荷偏高"],
      ["14:20", "午后活动量上升", "活动 42 分钟，状态回升"],
      ["19:10", "晚间心率恢复", "静息心率逐步回落"],
      ["22:05", "记录一次心慌/不适", "持续约 3 分钟，已记录"]
    ].map(([t, title, body]) => `<div class="event"><time>${t}</time><div class="panel" style="padding:10px"><b>${title}</b><p style="margin:4px 0 0;font-size:12px;color:#607699">${body}</p>${miniChart()}</div></div>`).join("")}</div>
    ${bottomNav("时间线", ["对话", "时间线", "数据", "我的"])}`;
}

function evidence() {
  return `${head("为什么这周恢复下降？", "证据详情", "")}
    <section class="panel soft" style="padding:12px"><b>综合结论</b><span class="score-ring" style="float:right;background:conic-gradient(#1264ff 0 85%,#e7effa 85% 100%)"><span>85%</span></span><p style="font-size:12px;color:#607699">本周恢复下降，可能与睡眠减少、压力和午后活动有关。</p></section>
    <div class="metric-grid">${metric("恢复分", "58", "-12%")}${metric("HRV", "48ms", "-18%")}${metric("静息心率", "58bpm", "+6%")}${metric("睡眠时长", "6h12m", "-48m")}</div>
    <section class="panel" style="padding:12px;margin-top:10px"><b>HRV 趋势</b>${chart("#1264ff", [66, 60, 58, 54, 52, 49, 48])}</section>
    <section class="panel" style="padding:12px;margin-top:10px"><b>主要影响因素</b>${["睡眠时长减少", "HRV 持续偏低", "压力负荷升高", "活动负荷上升"].map((x,i)=>`<div class="bar-row"><span>${x}</span><span class="bar"><i style="width:${[35,25,20,12][i]}%"></i></span><span>+${[35,25,20,12][i]}%</span></div>`).join("")}</section>`;
}

function report() {
  return `${head("本周健康周报", "5月9日 - 5月15日", "mascot_report")}
    <section class="panel soft" style="padding:12px"><b>综合评分</b><h2 style="margin:4px 0;font-size:46px;color:#1264ff">76<small>/100</small></h2><p style="font-size:12px;color:#607699">本周整体稳定，恢复一般。继续保持规律作息。</p></section>
    <h4>本周亮点</h4><div class="metric-grid">${metric("活动达标", "5/7天", "较好", "green")}${metric("HRV 趋势", "稳中有升", "良好", "blue")}${metric("心率恢复", "夜间良好", "正常", "red")}${metric("ECG", "正常", "5 次", "green")}</div>
    <section class="panel" style="padding:12px;margin-top:10px"><b>习惯建议</b>${["每晚尽量保证 7 小时以上睡眠", "午后适度活动 20-30 分钟", "高压时段尝试 4-7-8 呼吸法"].map((x)=>`<div class="setting"><span>${x}</span><span>›</span></div>`).join("")}</section>
    <button class="primary-btn" style="width:100%;margin-top:12px">分享周报</button>`;
}

function renderKind(kind) {
  const map = {
    home: () => homeScreen(false),
    homeCompact: () => homeScreen(true),
    discover: discoverScreen,
    recoveryDeep,
    ecg: ecgScreen,
    onboarding,
    advice,
    trend,
    settings,
    recoveryMatrix,
    anomaly,
    heartEcg,
    chat,
    timeline,
    evidence,
    report
  };
  return map[kind]();
}

function ecgWave(color = "#ff3243") {
  const pts = "0,42 25,42 30,38 34,42 52,42 58,8 63,72 70,42 96,42 103,36 112,42 150,42 156,10 161,70 168,42 206,42 214,36 222,42 260,42";
  return `<svg viewBox="0 0 260 82" style="width:100%;height:82px;background-image:linear-gradient(#ffd9dd 1px,transparent 1px),linear-gradient(90deg,#ffd9dd 1px,transparent 1px);background-size:10px 10px">
    <polyline points="${pts}" fill="none" stroke="${color}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`;
}

function render() {
  sceneTabs.innerHTML = scenes.map((scene) => `<button class="scene-tab ${scene.id === activeScene ? "active" : ""}" data-scene="${scene.id}">${scene.label}</button>`).join("");
  const scene = scenes.find((item) => item.id === activeScene) || scenes[0];
  sceneRoot.innerHTML = `
    <section class="phone-grid">${scene.phones.map(phone).join("")}</section>
    <section class="foot-strip">${scene.footer.map((item, i) => `<div><span>${["▥", "⌕", "☑", "♡"][i] || "•"}</span>${item}</div>`).join("")}</section>
  `;
}

sceneTabs.addEventListener("click", (event) => {
  const button = event.target.closest("[data-scene]");
  if (!button) return;
  activeScene = button.dataset.scene;
  render();
});

window.addEventListener("keydown", (event) => {
  if (!/^[1-4]$/.test(event.key)) return;
  activeScene = scenes[Number(event.key) - 1].id;
  render();
});

render();
