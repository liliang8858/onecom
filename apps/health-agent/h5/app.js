/**
 * Health Agent H5 Prototype
 * iOS-quality interactive prototype with stack navigation,
 * agency toggle, feedback simulation, and smooth transitions.
 */
(function () {
  'use strict';

  // === DOM References ===
  const app = document.querySelector('#appScreen');
  const pageStack = document.querySelector('#pageStack');
  const tabbarEl = document.querySelector('#tabbar');
  const toastEl = document.querySelector('#toast');
  const skeleton = document.querySelector('#skeletonOverlay');

  // === State ===
  const state = {
    tab: 'today',
    pageStack: [], // navigation stack: [{id, scrollY}]
    agencyMode: 'agentGuided', // 'agentGuided' | 'selfExplore'
  };

  // === Data ===
  const colors = {
    recovery: '#37A779',
    heart: '#D95F59',
    sleep: '#6E7BD9',
    workout: '#E1A33D',
    amber: '#C97A35',
    green: '#2F7D68',
    brandLight: '#42B883',
  };

  const todayMetrics = [
    { id: 'sleep', label: '睡眠', value: '6h12m', detail: '比平时少 42m', color: colors.sleep, values: [4.2, 5, 4.5, 5.5, 4, 5.2, 3.8], status: 'down' },
    { id: 'heart', label: '心脏', value: '稳定', detail: '静息心率 60 bpm', color: colors.heart, values: [2, 3, 2.5, 4, 3.5, 4.2, 3], status: 'normal' },
    { id: 'recovery', label: '恢复', value: '偏弱', detail: 'Recovery 62', color: colors.recovery, values: [7.5, 7, 7.2, 6, 5.5, 5.8, 4.5], status: 'attention' },
    { id: 'workout', label: '运动', value: '偏高', detail: '负荷 128', color: colors.workout, values: [1.5, 2, 3.5, 5, 4.2, 3.8, 3], status: 'up' },
  ];

  const questions = [
    { id: 'recovery', title: '我最近恢复得好吗？', subtitle: 'HRV 下降 · 静息心率略高', category: '恢复', screen: 'recovery', ecg: false },
    { id: 'sleep', title: '昨晚睡得怎么样？', subtitle: '睡眠 6h12m · 夜间心率偏高', category: '睡眠', screen: 'sleepDetail', ecg: false },
    { id: 'heart', title: '最近心脏状态稳定吗？', subtitle: '有 1 次 ECG 可作为补充证据', category: '心脏', screen: 'heart', ecg: true },
    { id: 'anomaly', title: '最近有什么异常？', subtitle: '发现 3 个值得关注的变化', category: '异常', screen: 'anomaly', ecg: false },
  ];

  const discoveryItems = [
    { title: '睡眠减少', body: '昨晚睡眠比平时少 1 小时 12 分钟，深睡和 REM 占比偏低，可能影响恢复。', color: colors.sleep },
    { title: '运动负荷上升', body: '过去 7 天运动负荷比上周上升 32%，身体压力增加，建议注意恢复与放松。', color: colors.workout },
  ];

  const actions = [
    {
      id: 'walk', title: '午后散步 10 分钟',
      detail: '轻度有氧运动，有助于下午精力恢复',
      reason: '你过去这类行动完成率较高 (68%)，且有助于下午能量恢复',
      difficulty: '简单', meta: '完成率 68%'
    },
    {
      id: 'sleep', title: '22:40 开始睡前放松',
      detail: '远离手机屏幕，进行深呼吸练习',
      reason: '你睡眠少于 6.5 小时后，次日 HRV 更容易下降',
      difficulty: '简单', meta: '完成率 55%'
    },
    {
      id: 'hydrate', title: '下午 3 点补充水分',
      detail: '喝 300ml 水，保持水分充足',
      reason: '你最近 3 天饮水量偏低',
      difficulty: '极易', meta: '完成率 82%'
    },
  ];

  const recoveryDetail = {
    title: '我最近恢复得好吗？',
    range: '过去 30 天',
    summary: '过去 7 天你的 HRV 下降 18%，静息心率略高，同时睡眠时间减少。主要建议是降低高强度训练，优先补足睡眠。',
    metrics: [
      { label: 'HRV', value: '-12%', detail: '低于 30 日基线', color: colors.recovery },
      { label: '静息心率', value: '+4 bpm', detail: '连续 4 天略高', color: colors.heart },
      { label: '睡眠', value: '-42m', detail: '比平时少', color: colors.sleep },
      { label: '运动负荷', value: '+32%', detail: '本周上升', color: colors.workout },
    ],
    chart: { title: 'HRV 30 天趋势', subtitle: '最近 7 天低于个人基线', values: [58, 61, 59, 55, 52, 49, 47, 46, 44, 43, 41, 39], color: colors.recovery },
    timeline: [
      { day: '周一', primary: '睡眠 7h10m', secondary: 'HRV 正常' },
      { day: '周二', primary: '运动 30min', secondary: '状态良好' },
      { day: '周三', primary: '高强度训练', secondary: 'HRV 开始下降' },
      { day: '周四', primary: '睡眠不足', secondary: '静息心率偏高' },
      { day: '周五', primary: '睡眠 5h48m', secondary: '恢复偏低' },
    ],
    next: ['只看睡眠因素', '加入运动负荷分析', '和状态好的日子对比'],
  };

  const sleepDetail = {
    title: '昨晚睡得怎么样？',
    range: '昨晚',
    summary: '昨晚睡眠 6h12m，比平时少 42 分钟。深睡和 REM 占比偏低，夜间心率略高。',
    metrics: [
      { label: '总睡眠', value: '6h12m', detail: '少 42m', color: colors.sleep },
      { label: '深睡', value: '48m', detail: '偏低', color: colors.sleep },
      { label: '夜间心率', value: '58 bpm', detail: '略高', color: colors.heart },
      { label: '呼吸', value: '16/min', detail: '平稳', color: colors.recovery },
    ],
    chart: { title: '过去 14 天睡眠', subtitle: '本周整体低于平时', values: [7.2, 7.0, 6.8, 7.4, 6.4, 6.1, 6.2, 6.0, 5.8, 6.3, 6.1], color: colors.sleep },
    next: ['看夜间心率趋势', '和前 7 天对比', '睡眠影响恢复吗？'],
  };

  const heartDetail = {
    title: '最近心脏状态稳定吗？',
    range: '过去 30 天',
    summary: '最近静息心率略高，HRV 略低。昨日 22:14 有一次 ECG，可作为本次回看的补充证据。',
    metrics: [
      { label: '静息心率', value: '+3 bpm', detail: '近 7 天略高', color: colors.heart },
      { label: 'HRV', value: '-9%', detail: '略低', color: colors.recovery },
      { label: 'ECG', value: '1 次', detail: '补充证据', color: colors.heart },
      { label: '信号质量', value: '良好', detail: '可分析', color: colors.recovery },
    ],
    chart: { title: '静息心率趋势', subtitle: '近 7 天略高于个人基线', values: [54, 55, 55, 56, 58, 58, 59, 58, 57, 58, 59], color: colors.heart },
    next: ['解读 ECG', '查看睡眠影响', '运动后恢复好吗？'],
  };

  const anomalies = [
    { title: '静息心率连续 4 天偏高', body: '可能相关：睡眠减少、运动负荷增加。建议查看详细趋势。', severity: '建议查看', tags: ['心脏', '睡眠'] },
    { title: 'HRV 低于 30 天基线', body: '可能提示恢复压力上升。建议关注休息质量。', severity: '轻微变化', tags: ['恢复'] },
    { title: '昨晚夜间心率偏高', body: '建议结合睡眠结构和晚间活动回看。', severity: '建议查看', tags: ['睡眠', '心脏'] },
  ];

  let anomalyFilter = '全部';

  // === Utility Functions ===

  function svgSparkline(values, color, height = 40) {
    const w = 160, pad = 2;
    const min = Math.min(...values), max = Math.max(...values);
    const range = Math.max(max - min, 0.1);
    const pts = values.map((v, i) => {
      const x = pad + (i / (values.length - 1)) * (w - pad * 2);
      const y = height - pad - ((v - min) / range) * (height - pad * 2);
      return `${x.toFixed(1)},${y.toFixed(1)}`;
    }).join(' ');

    // Area fill
    const areaPts = `${pad},${height} ${pts} ${w - pad},${height}`;
    return `<svg class="spark" viewBox="0 0 ${w} ${height}" preserveAspectRatio="none" aria-hidden="true">
      <defs><linearGradient id="grad-${color.replace('#','').slice(0,6)}" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color="${color}" stop-opacity="0.25"/>
        <stop offset="100%" stop-color="${color}" stop-opacity="0.02"/>
      </linearGradient></defs>
      <polygon points="${areaPts}" fill="url(#grad-${color.replace('#','').slice(0,6)})"/>
      <polyline points="${pts}" fill="none" stroke="${color}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>`;
  }

  function svgChart(values, color) {
    const w = 328, h = 140, pad = 16;
    const min = Math.min(...values), max = Math.max(...values);
    const range = Math.max(max - min, 0.1);
    const pts = values.map((v, i) => {
      const x = pad + (i / (values.length - 1)) * (w - pad * 2);
      const y = h - pad - ((v - min) / range) * (h - pad * 2);
      return `${x.toFixed(1)},${y.toFixed(1)}`;
    }).join(' ');

    // Gradient fill
    const areaPts = `${pad},${h} ${pts} ${w - pad},${h}`;
    const gradId = 'chartGrad' + Math.random().toString(36).slice(2, 6);

    // Grid lines
    const lines = [0.25, 0.5, 0.75].map(pct => {
      const y = pad + (h - pad * 2) * (1 - pct);
      return `<line x1="${pad}" y1="${y}" x2="${w - pad}" y2="${y}" stroke="#E8EDEA" stroke-width="0.5"/>`;
    }).join('');

    return `<svg class="chart-svg" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none">
      <defs><linearGradient id="${gradId}" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color="${color}" stop-opacity="0.18"/>
        <stop offset="100%" stop-color="${color}" stop-opacity="0.01"/>
      </linearGradient></defs>
      ${lines}
      <polygon points="${areaPts}" fill="url(#${gradId})"/>
      <polyline points="${pts}" fill="none" stroke="${color}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
      <circle cx="${pts.split(' ')[0].split(',')[0]}" cy="${pts.split(' ')[0].split(',')[1]}" r="3.5" fill="${color}"/>
      <circle cx="${pts.split(' ').pop().split(',')[0]}" cy="${pts.split(' ').pop().split(',')[1]}" r="3.5" fill="${color}"/>
    </svg>`;
  }

  function deltaCard(label, value, detail, color) {
    return `<article class="delta-card" style="background:${color}0D">
      <h3>${label}</h3>
      <strong style="color:${color}">${value}</strong>
      <p>${detail}</p>
    </article>`;
  }

  function agentRow(title, body, color) {
    return `<div class="agent-row">
      <div class="mini-icon" style="background:${color}18;color:${color}">${title.slice(0, 2)}</div>
      <div><h3>${title}</h3><p>${body}</p></div>
    </div>`;
  }

  function insightCard(q) {
    const color = q.category === '睡眠' ? colors.sleep : q.category === '心脏' ? colors.heart : q.category === '异常' ? colors.amber : colors.recovery;
    return `<button class="insight-card" data-detail="${q.screen}">
      <span class="insight-icon" style="color:${color};background:${color}14">${q.category[0]}</span>
      <span>
        <h3>${q.title}${q.ecg ? '<span class="ecg-badge">ECG</span>' : ''}</h3>
        <p>${q.subtitle}</p>
      </span>
      <span class="chev">›</span>
    </button>`;
  }

  function actionRowHtml(action, completed) {
    return `<div class="action-row">
      <button class="action-check ${completed ? 'done' : ''}" data-action="${action.id}">✓</button>
      <div class="action-content">
        <h4>${action.title}</h4>
        <p>${action.reason}</p>
        <div class="action-meta">
          <span class="action-tag">${action.difficulty}</span>
          <span class="action-tag">${action.meta}</span>
        </div>
        <div class="action-feedback">
          <button class="feedback-btn" data-fb="tooHard">太难了</button>
          <button class="feedback-btn" data-fb="notSuitable">不适合</button>
          <button class="feedback-btn" data-fb="replace">换一个</button>
        </div>
      </div>
    </div>`;
  }

  // === Navigation ===

  function pushPage(id) {
    state.pageStack.push({ id, scrollY: 0 });
    renderPage(id);
  }

  function popPage() {
    if (state.pageStack.length > 0) {
      const prev = state.pageStack.pop();
      renderPage(prev.id);
    } else {
      renderPage(state.tab);
    }
  }

  function renderPage(id) {
    switch (id) {
      case 'today': renderToday(); break;
      case 'explore': renderExplore(); break;
      case 'heart': renderHeartPage(); break;
      case 'reports': renderReports(); break;
      case 'me': renderMe(); break;
      case 'detail-recovery': renderDetail(recoveryDetail, 'recovery'); break;
      case 'detail-sleep': renderDetail(sleepDetail, 'sleep'); break;
      case 'detail-heart': renderDetail(heartDetail, 'heart'); break;
      case 'anomaly': renderAnomaly(); break;
      case 'ecg': renderECGDetail(); break;
      case 'onboarding': renderOnboarding(); break;
      default: renderToday();
    }
    // Trigger animation
    const page = pageStack.querySelector('.page');
    if (page) { page.style.animation = 'none'; page.offsetHeight; page.style.animation = ''; }
  }

  function updateTabbar(tab) {
    document.querySelectorAll('.tab-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.tab === tab);
    });
  }

  // === Render Functions ===

  function renderToday() {
    updateTabbar('today');
    const agencyToggle = state.agencyMode === 'agentGuided'
      ? '<span class="chip active" style="background:var(--brand);color:white">帮我总结</span><span class="chip">自己看</span>'
      : '<span class="chip">帮我总结</span><span class="chip active" style="background:var(--brand);color:white">自己看</span>';

    app.innerHTML = `
      <div class="page">
        <div class="topbar">
          <div>
            <h1 class="title-xl">今日</h1>
            <p class="eyebrow">${new Date().toLocaleDateString('zh-CN', { month: 'long', day: 'numeric', weekday: 'long' })} · Apple Health 已同步</p>
          </div>
          <div class="sync-pill">
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none"><circle cx="6" cy="6" r="5" stroke="currentColor" stroke-width="1.5"/><path d="M6 3v3l2 1" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>
            已同步
          </div>
        </div>

        <!-- Hero -->
        <div class="hero">
          <div class="hero-content">
            <div class="hero-grid">
              <div>
                <p class="hero-label">今日身体状态</p>
                <h2 class="hero-state">偏弱</h2>
                <p class="hero-copy">你的身体恢复水平偏低，<br>建议关注睡眠与恢复。</p>
              </div>
              <div class="ring">
                <div class="ring-inner">
                  <div>
                    <div class="ring-title">Recovery</div>
                    <div class="ring-score">62</div>
                  </div>
                </div>
              </div>
            </div>
            <div class="factor-row">
              <span class="factor">😴 睡眠不足</span>
              <span class="factor">📉 HRV 下降</span>
              <span class="factor">💓 心率略高</span>
            </div>
            <div class="button-row">
              <button class="ghost-btn" data-detail="detail-recovery">查看原因 →</button>
              <button class="primary-btn" onclick="showToast('今日建议：午后散步 10 分钟，22:40 放下手机')">今日建议</button>
            </div>
          </div>
        </div>

        <!-- Personalization Badge -->
        <div style="margin-top:16px">
          <span style="display:inline-flex;align-items:center;gap:4px;padding:5px 10px;border-radius:999px;background:rgba(47,125,104,0.08);color:var(--brand);font-size:11px;font-weight:700">
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M6 2v4l3 2" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>
            ${new Date().getHours() < 12 ? '早上好' : '下午好'} · 根据你的睡眠关注偏好生成
          </span>
        </div>

        <!-- Agency Toggle -->
        <div style="margin:14px 0;display:flex;align-items:center;gap:8px">
          <span style="font-size:12px;font-weight:600;color:var(--text-tertiary)">呈现模式</span>
          <div style="display:flex;background:var(--bg-secondary);border-radius:var(--radius-pill);padding:3px">
            <button id="toggleAgent" class="agency-btn" style="padding:5px 14px;border-radius:var(--radius-pill);border:none;font-size:12px;font-weight:700;background:var(--brand);color:white;transition:all 0.2s">帮我总结</button>
            <button id="toggleExplore" class="agency-btn" style="padding:5px 14px;border-radius:var(--radius-pill);border:none;font-size:12px;font-weight:700;color:var(--text-secondary);background:transparent;transition:all 0.2s">自己看</button>
          </div>
        </div>

        <!-- Agent 发现 -->
        <div class="section-title">
          <h2>Agent 发现</h2>
          <span class="action" data-detail="detail-recovery">查看全部 ›</span>
        </div>
        <div class="card" style="padding:var(--space-md)">
          ${discoveryItems.map((d, i) => agentRow(d.title, d.body, d.color)).join('')}
        </div>

        <!-- 今日模块 -->
        <div class="section-title"><h2>${state.agencyMode === 'agentGuided' ? '今日要点' : '数据总览'}</h2></div>
        <div class="module-grid">
          ${todayMetrics.map(m => `
            <div class="card module-card">
              <h3>${m.label}</h3>
              <div class="module-value" style="color:${m.color}">${m.value}</div>
              <p>${m.detail}</p>
              ${svgSparkline(m.values, m.color)}
            </div>
          `).join('')}
        </div>

        <!-- 行动建议 -->
        <div class="section-title"><h2>今日行动</h2></div>
        <div class="card action-plan" style="padding:var(--space-lg)">
          <h2>为你推荐的 3 个小行动</h2>
          ${actions.map((a, i) => actionRowHtml(a, i === 0)).join('')}
        </div>

        <!-- 为什么看 -->
        <div style="margin:var(--space-xl) 0 var(--space-md)">
          <div class="why-card">
            <div class="why-card-header">
              <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><circle cx="7" cy="7" r="6" stroke="var(--brand)" stroke-width="1.5"/><path d="M7 4v4l2.5 1.5" stroke="var(--brand)" stroke-width="1.5" stroke-linecap="round"/></svg>
              <span>为什么给你看这些</span>
            </div>
            <p class="body-copy">基于你过去 7 天的睡眠与运动数据，睡眠不足与次日 HRV 下降高度相关（相关系数 0.68）。该判断已通过 21 天数据验证。</p>
            <button class="why-expand" onclick="this.textContent = this.textContent === '展开详细依据 ▾' ? '收起 ▴' : '展开详细依据 ▾'">展开详细依据 ▾</button>
          </div>
        </div>

        <!-- 继续探索 -->
        <div class="section-title"><h2>继续探索</h2></div>
        <div class="insight-list">
          ${questions.map(insightCard).join('')}
        </div>

        <!-- Ask Bar -->
        <div class="askbar">
          <div class="askbar-icon">问</div>
          <input type="text" placeholder="问问你的健康数据..." aria-label="问问你的健康数据" id="askInput"/>
          <button class="send-btn" id="sendBtn" aria-label="发送">➤</button>
        </div>
      </div>
    `;

    // Bind events
    bindDetailLinks();
    bindAgencyToggle();
    bindAskBar();
    bindActionCompletion();
  }

  function renderDetail(detail, type) {
    updateTabbar('');
    const chartFn = type === 'sleep' ? 'detail-sleep' : type === 'heart' ? 'detail-heart' : 'detail-recovery';
    app.innerHTML = `
      <div class="page">
        <div class="detail-header">
          <button class="back-btn" data-back>‹</button>
          <div>
            <p class="eyebrow">${detail.range}</p>
            <h1 class="title-lg">${detail.title}</h1>
          </div>
        </div>

        <div class="card summary-card">
          <h2>${detail.summaryTitle}</h2>
          <p class="body-copy">${detail.summary}</p>
          <p class="notice">${type === 'heart' ? '心脏状态分析不构成医学诊断。如持续不适，建议咨询医生。' : '本页不构成医学诊断，仅帮助你回看身体数据。'}</p>
        </div>

        <div class="section-title"><h2>关键证据</h2></div>
        <div class="delta-grid">
          ${detail.metrics.map(m => deltaCard(m.label, m.value, m.detail, m.color)).join('')}
        </div>

        ${detail.chart ? `<div class="section-title"><h2>${detail.chart.title}</h2></div>
        <div class="card chart-card">
          <p class="body-copy">${detail.chart.subtitle}</p>
          ${svgChart(detail.chart.values, detail.chart.color)}
        </div>` : ''}

        ${detail.timeline ? `<div class="section-title"><h2>时间线</h2></div>
        <div class="card timeline" style="padding:var(--space-md)">
          ${detail.timeline.map(t => `
            <div class="timeline-row">
              <div class="timeline-dot"></div>
              <div><h3>${t.day} · ${t.primary}</h3><p>${t.secondary}</p></div>
            </div>
          `).join('')}
        </div>` : ''}

        <div class="section-title"><h2>下一步探索</h2></div>
        <div class="chips">${detail.next.map(n => `<button class="chip" data-detail="${chartFn}">${n}</button>`).join('')}</div>
      </div>
    `;
    bindDetailLinks();
  }

  function renderAnomaly() {
    updateTabbar('');
    const filtered = anomalyFilter === '全部' ? anomalies : anomalies.filter(a => a.tags.includes(anomalyFilter));

    app.innerHTML = `
      <div class="page">
        <div class="detail-header">
          <button class="back-btn" data-back>‹</button>
          <div>
            <p class="eyebrow">过去 14 天</p>
            <h1 class="title-lg">最近有什么异常？</h1>
          </div>
        </div>

        <div class="card summary-card">
          <h2>发现 ${anomalies.length} 个值得关注的变化</h2>
          <p class="body-copy">这些变化按个人基线、持续时间和数据完整度排序。</p>
        </div>

        <div class="filter-row">
          ${['全部', '睡眠', '心脏', '恢复', '运动'].map(f =>
            `<button class="filter ${anomalyFilter === f ? 'active' : ''}" data-filter="${f}">${f}</button>`
          ).join('')}
        </div>

        <div class="list-stack">
          ${filtered.map(item => `
            <button class="card insight-card" data-detail="detail-recovery" style="text-align:left">
              <span class="insight-icon" style="color:${colors.amber};background:${colors.amber}14">变</span>
              <span>
                <h3>${item.title} <span class="ecg-badge" style="background:${item.severity === '建议查看' ? colors.heart + '18' : colors.amber + '18'};color:${item.severity === '建议查看' ? colors.heart : colors.amber}">${item.severity}</span></h3>
                <p>${item.body}</p>
              </span>
              <span class="chev">›</span>
            </button>
          `).join('')}
        </div>
      </div>
    `;
    bindDetailLinks();
    bindFilter();
  }

  function renderHeartPage() {
    updateTabbar('heart');
    app.innerHTML = `
      <div class="page">
        <div class="topbar">
          <div>
            <h1 class="title-xl">心脏</h1>
            <p class="eyebrow">连续指标为主，ECG 作为补充证据</p>
          </div>
        </div>

        <div class="card ecg-card" data-screen="ecg" style="cursor:pointer">
          <h2>昨日 22:14 · ECG 补充证据</h2>
          <div class="stat-grid">
            <div class="stat"><span>节律</span><strong>整体稳定</strong></div>
            <div class="stat"><span>平均心率</span><strong>82 bpm</strong></div>
            <div class="stat"><span>信号质量</span><strong>良好</strong></div>
          </div>
          <img class="ecg-wave" src="./assets/ecg-waveform-sample.png" alt="ECG 波形" />
          <p class="notice" style="margin-top:12px">本解读仅供参考，不能替代专业医疗建议。</p>
        </div>

        <div class="section-title"><h2>心率趋势</h2></div>
        <div class="card chart-card">
          <p class="body-copy">近 7 天略高于个人基线</p>
          ${svgChart([54, 55, 55, 56, 58, 58, 59, 58, 57, 58, 59], colors.heart)}
        </div>

        <div class="section-title"><h2>继续探索</h2></div>
        <div class="insight-list">
          ${insightCard(questions[2])}
        </div>

        <div class="section-title"><h2>相关背景</h2></div>
        <div class="delta-grid">
          ${deltaCard('昨晚睡眠', '6h12m', '略低', colors.sleep)}
          ${deltaCard('HRV', '32ms', '略低', colors.recovery)}
          ${deltaCard('静息心率', '58 bpm', '略高', colors.heart)}
          ${deltaCard('信号质量', '良好', '干扰少', colors.recovery)}
        </div>
      </div>
    `;
    bindDetailLinks();
  }

  function renderECGDetail() {
    pushPage('ecg');
    app.innerHTML = `
      <div class="page">
        <div class="detail-header">
          <button class="back-btn" data-back>‹</button>
          <div>
            <p class="eyebrow">昨日 22:14 · 导联 II</p>
            <h1 class="title-lg">解读最新一次 ECG</h1>
          </div>
        </div>

        <div class="card summary-card">
          <h2>节律整体稳定</h2>
          <p class="body-copy">这不是医学诊断，但可以帮助你回看当时状态。心电波形显示心脏节律规整，无明显异常。</p>
        </div>

        <div class="card ecg-card">
          <h2>ECG 波形</h2>
          <div class="stat-grid">
            <div class="stat"><span>心率</span><strong>82 bpm</strong></div>
            <div class="stat"><span>PR 间期</span><strong>152 ms</strong></div>
            <div class="stat"><span>QT 间期</span><strong>380 ms</strong></div>
          </div>
          <img class="ecg-wave" src="./assets/ecg-waveform-sample.png" alt="ECG 波形" />
          <p class="notice">波形仅供参考，实际诊断需结合临床评估。</p>
        </div>

        <div class="section-title"><h2>RR 间期分析</h2></div>
        <div class="card chart-card">
          <p class="body-copy">平均 731ms，波动较平稳</p>
          ${svgChart([720, 738, 714, 731, 744, 729, 718, 735, 728, 732, 725], colors.heart)}
        </div>

        <div class="section-title"><h2>相关背景</h2></div>
        <div class="delta-grid">
          ${deltaCard('信号质量', '良好', '干扰少', colors.recovery)}
          ${deltaCard('分类', '正常窦性心律', '无异常', colors.recovery)}
          ${deltaCard('运动前', '记录前 1 小时静坐', '数据可靠', colors.recovery)}
          ${deltaCard('睡眠关联', '记录前夜睡眠 6.5h', '正常范围', colors.sleep)}
        </div>

        <div class="section-title"><h2>建议</h2></div>
        <div class="card" style="padding:var(--space-lg)">
          <p class="body-copy" style="margin-bottom:8px">
            <strong style="color:var(--green)">✓ 心电节律稳定</strong> — 当前 ECG 未见明显异常，可作为健康参考基线。
          </p>
          <p class="body-copy" style="margin-bottom:8px">
            <strong style="color:var(--amber)">⚠ 建议定期记录</strong> — 连续记录有助于发现长期变化趋势。
          </p>
          <p class="notice">以上内容基于设备采集数据，仅供参考。如有不适，请及时咨询专业医生。</p>
        </div>
      </div>
    `;
    bindDetailLinks();
  }

  function renderReports() {
    updateTabbar('reports');
    app.innerHTML = `
      <div class="page">
        <div class="topbar">
          <div>
            <h1 class="title-xl">报告</h1>
            <p class="eyebrow">每周复盘健康状态</p>
          </div>
        </div>

        <div class="card report-card">
          <h2>本周健康报告</h2>
          <p class="body-copy">本周整体偏弱但可恢复。主要变化来自睡眠减少、运动负荷上升和 HRV 下降。建议接下来 3 天降低训练强度，优先补足睡眠。</p>
          <div class="delta-grid" style="margin-top:16px">
            ${deltaCard('睡眠', '-42m', '平均每晚', colors.sleep)}
            ${deltaCard('运动', '+32%', '负荷上升', colors.workout)}
            ${deltaCard('HRV', '-12%', '低于基线', colors.recovery)}
            ${deltaCard('ECG', '1 次', '新增记录', colors.heart)}
          </div>
        </div>

        <div class="section-title"><h2>本周趋势</h2></div>
        <div class="card chart-card">
          <p class="body-copy">睡眠和恢复同步走弱，需关注调整节奏</p>
          ${svgChart([7, 6.8, 6.2, 5.9, 6.1, 6.0, 6.2], colors.recovery)}
        </div>

        <div class="section-title"><h2>AI 洞察</h2></div>
        <div class="card" style="padding:var(--space-lg)">
          <div style="display:flex;align-items:center;gap:8px;margin-bottom:12px">
            <span style="width:28px;height:28px;border-radius:50%;background:var(--brand-bg);display:grid;place-items:center">
              <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><circle cx="7" cy="7" r="3" stroke="var(--brand)" stroke-width="1.5"/><path d="M7 4v3l2 1" stroke="var(--brand)" stroke-width="1.5" stroke-linecap="round"/></svg>
            </span>
            <span style="font-size:13px;font-weight:700;color:var(--text-secondary)">Agent 综合分析</span>
          </div>
          <p class="body-copy" style="margin-bottom:10px">睡眠时长减少与恢复评分下降呈正相关（r=-0.72）。运动负荷在周三达到峰值后未及时恢复，周五出现明显疲劳累积。建议未来一周适当降低运动强度，增加 30 分钟午间休息。</p>
          <div class="chips">
            <button class="chip">展开更多分析</button>
            <button class="chip">导出 PDF</button>
          </div>
        </div>

        <div class="section-title"><h2>行动效果追踪</h2></div>
        <div class="card" style="padding:var(--space-lg)">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px">
            <span style="font-size:14px;font-weight:700">午后散步完成率</span>
            <span style="font-size:20px;font-weight:900;color:var(--recovery)">68%</span>
          </div>
          <div style="height:6px;background:var(--border);border-radius:3px;overflow:hidden">
            <div style="width:68%;height:100%;background:var(--recovery);border-radius:3px;transition:width 0.6s ease"></div>
          </div>
          <p class="notice" style="margin-top:10px;margin-bottom:0">坚持散步 3 天后，晚间心率平均恢复提前了 12 分钟</p>
        </div>
      </div>
    `;
    bindDetailLinks();
  }

  function renderMe() {
    updateTabbar('me');
    app.innerHTML = `
      <div class="page">
        <div class="topbar">
          <div>
            <h1 class="title-xl">我的</h1>
            <p class="eyebrow">数据、隐私和个性化设置</p>
          </div>
        </div>

        <div style="margin-bottom:var(--space-xl)">
          <div class="card" style="padding:var(--space-xl);display:flex;align-items:center;gap:var(--space-lg)">
            <div style="width:56px;height:56px;border-radius:50%;background:var(--brand);display:grid;place-items:center">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                <circle cx="12" cy="7" r="4"/>
              </svg>
            </div>
            <div>
              <h3 style="font-size:17px;font-weight:700">Health Agent</h3>
              <p style="font-size:13px;color:var(--text-tertiary)">分身记忆 v0.1 · 持续了解你</p>
            </div>
          </div>
        </div>

        <div style="margin-bottom:var(--space-xl)">
          <div class="section-title"><h2>健康关注</h2></div>
          <div class="chips" style="margin-bottom:var(--space-md)">
            <span class="chip active">睡眠</span>
            <span class="chip">恢复</span>
            <span class="chip">心脏</span>
            <span class="chip">运动</span>
          </div>
        </div>

        <div style="margin-bottom:var(--space-xl)">
          <div class="section-title"><h2>分身记忆</h2></div>
          <div class="list-stack">
            <div class="card" style="padding:var(--space-lg)">
              <div style="display:flex;justify-content:space-between;align-items:flex-start">
                <div>
                  <span style="font-size:10px;font-weight:700;color:var(--recovery);text-transform:uppercase;letter-spacing:0.5px">已确认 ✓</span>
                  <p style="font-size:14px;font-weight:700;margin-top:4px">睡眠不足 → 次日 HRV 下降</p>
                  <p style="font-size:12px;color:var(--text-tertiary)">观察 21 天，置信度 87%</p>
                </div>
                <span style="font-size:12px;color:var(--text-tertiary)">✓已确认</span>
              </div>
            </div>
            <div class="card" style="padding:var(--space-lg)">
              <div style="display:flex;justify-content:space-between;align-items:flex-start">
                <div>
                  <span style="font-size:10px;font-weight:700;color:var(--amber);text-transform:uppercase;letter-spacing:0.5px">观察中...</span>
                  <p style="font-size:14px;font-weight:700;margin-top:4px">午后运动是否改善晚间心率恢复</p>
                  <p style="font-size:12px;color:var(--text-tertiary)">已观察 4/7 次，待进一步确认</p>
                </div>
                <span style="font-size:12px;color:var(--text-tertiary)">4/7</span>
              </div>
            </div>
          </div>
        </div>

        <div style="margin-bottom:var(--space-xl)">
          <div class="section-title"><h2>变更记录</h2></div>
          <div class="list-stack">
            <div style="display:flex;align-items:center;gap:var(--space-sm)">
              <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><circle cx="7" cy="7" r="6" stroke="var(--recovery)" stroke-width="1.5"/><path d="M7 4v3l2 1" stroke="var(--recovery)" stroke-width="1.5" stroke-linecap="round"/></svg>
              <span style="font-size:13px">健康解释已改为简洁模式</span>
            </div>
            <div style="display:flex;align-items:center;gap:var(--space-sm)">
              <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><circle cx="7" cy="7" r="6" stroke="var(--recovery)" stroke-width="1.5"/><path d="M7 4v3l2 1" stroke="var(--recovery)" stroke-width="1.5" stroke-linecap="round"/></svg>
              <span style="font-size:13px">减少夜间心率提醒频率</span>
            </div>
            <div style="display:flex;align-items:center;gap:var(--space-sm)">
              <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><circle cx="7" cy="7" r="6" stroke="var(--recovery)" stroke-width="1.5"/><path d="M7 4v3l2 1" stroke="var(--recovery)" stroke-width="1.5" stroke-linecap="round"/></svg>
              <span style="font-size:13px">同类洞察展示频率已降低</span>
            </div>
          </div>
        </div>

        <div style="margin-bottom:var(--space-xl)">
          <div class="section-title"><h2>个性化设置</h2></div>
          <div class="card permission-card">
            <button class="insight-card" data-screen="onboarding" style="width:100%;display:flex">
              <span class="insight-icon" style="color:var(--green);background:var(--green)14">设</span>
              <span style="flex:1"><h3>重新进行偏好设置</h3><p>解释风格、提醒频率、代理模式</p></span>
              <span class="chev">›</span>
            </button>
          </div>
        </div>

        <div style="margin-bottom:var(--space-xl)">
          <div class="section-title"><h2>数据与隐私</h2></div>
          <div class="card permission-card">
            <h2>HealthKit 权限</h2>
            <p class="body-copy">已授权：睡眠 · 心率 · 静息心率 · 运动</p>
            <p class="body-copy">待授权：HRV · ECG · 血氧</p>
            <p class="notice" style="margin-top:12px;margin-bottom:0">原始健康数据默认留在设备本地</p>
          </div>
        </div>

        <div class="card" style="padding:var(--space-lg);text-align:center;margin-top:8px">
          <p style="font-size:12px;color:var(--text-tertiary)">Health Agent Twin v0.1 · 健康结果优先的智能 Agent 画布</p>
          <p style="font-size:11px;color:var(--text-tertiary);margin-top:4px">它不是让你更依赖 App，而是让你更理解自己的身体</p>
        </div>

        <div style="height:20px"></div>
      </div>
    `;
    bindDetailLinks();
  }

  function renderOnboarding() {
    updateTabbar('');
    const focus = ['睡眠', '恢复', '心脏', '运动', '压力', 'ECG', '体重', '整体健康'];

    app.innerHTML = `
      <div class="page">
        <div class="detail-header">
          <button class="back-btn" data-back>‹</button>
          <div>
            <p class="eyebrow">初始化 · 3 步完成</p>
            <h1 class="title-lg">先让 App 了解你关心什么</h1>
          </div>
        </div>

        <div class="card summary-card">
          <h2>🎯 健康关注选择</h2>
          <p class="body-copy">选择你最想了解的 3-5 个健康方向，我会据此为你生成个性化的首页和洞察建议。</p>
          <div style="margin-top:16px;display:flex;flex-wrap:wrap;gap:8px">
            ${focus.map((x, i) => `<button class="chip ${i < 4 ? 'active' : ''}" data-focus="${x}">${x}</button>`).join('')}
          </div>
        </div>

        <div class="card permission-card">
          <h2>🔒 权限说明</h2>
          <p class="body-copy" style="margin-bottom:8px">根据你的关注方向，我会渐进式请求以下权限：</p>
          <div style="display:grid;gap:8px;margin-top:8px">
            <div style="display:flex;align-items:center;gap:8px;padding:8px 12px;background:var(--bg);border-radius:8px">
              <span style="color:var(--green)">✓</span>
              <span style="font-size:14px;font-weight:600">睡眠数据</span>
              <span style="margin-left:auto;font-size:12px;color:var(--text-tertiary);flex-shrink:0">睡眠时长、阶段</span>
            </div>
            <div style="display:flex;align-items:center;gap:8px;padding:8px 12px;background:var(--bg);border-radius:8px">
              <span style="color:var(--green)">✓</span>
              <span style="font-size:14px;font-weight:600">心率数据</span>
              <span style="margin-left:auto;font-size:12px;color:var(--text-tertiary);flex-shrink:0">静息、运动心率</span>
            </div>
            <div style="display:flex;align-items:center;gap:8px;padding:8px 12px;background:var(--bg);border-radius:8px">
              <span style="color:var(--amber)">○</span>
              <span style="font-size:14px;font-weight:600">HRV</span>
              <span style="margin-left:auto;font-size:12px;color:var(--text-tertiary);flex-shrink:0">心率变异性</span>
            </div>
            <div style="display:flex;align-items:center;gap:8px;padding:8px 12px;background:var(--bg);border-radius:8px">
              <span style="color:var(--amber)">○</span>
              <span style="font-size:14px;font-weight:600">ECG</span>
              <span style="margin-left:auto;font-size:12px;color:var(--text-tertiary);flex-shrink:0">心电记录（可选）</span>
            </div>
          </div>
          <p class="notice" style="margin-top:12px;margin-bottom:0">原始 HealthKit 数据默认留在设备本地，不会上传。</p>
        </div>

        <div class="card permission-card">
          <h2>💬 解释风格</h2>
          <div style="display:grid;gap:8px;margin-top:8px">
            ${['一句话总结', '适度解释', '给我证据和数据'].map((x, i) =>
              `<button class="chip ${i === 1 ? 'active' : ''}" data-focus="style">${x}</button>`
            ).join('')}
          </div>
        </div>

        <div class="card permission-card">
          <h2>🔔 通知偏好</h2>
          <div style="display:grid;gap:8px;margin-top:8px">
            ${['只在重要变化时', '每天给我摘要', '尽量少打扰'].map((x, i) =>
              `<button class="chip ${i === 0 ? 'active' : ''}" data-focus="notify">${x}</button>`
            ).join('')}
          </div>
        </div>

        <div style="padding:var(--space-xl) 0 var(--space-lg)">
          <button class="primary-btn" id="onboardingDone" style="width:100%;padding:16px;font-size:16px">
            完成设置，生成我的首页
          </button>
          <p class="notice" style="margin:12px 0 0;text-align:center">
            我还在了解你。现在展示的洞察基于通用健康规律，<br>几天后我会切换到你的个人基线。
          </p>
        </div>
      </div>
    `;

    document.querySelectorAll('.card .chip').forEach(chip => {
      chip.addEventListener('click', function () {
        this.classList.toggle('active');
      });
    });

    document.getElementById('onboardingDone').addEventListener('click', function () {
      state.pageStack = [];
      showToast('设置完成！为你生成个性化首页 🎉');
      setTimeout(() => renderToday(), 600);
    });

    bindDetailLinks();
  }

  // === Event Bindings ===

  function bindDetailLinks() {
    document.querySelectorAll('[data-detail]').forEach(el => {
      el.addEventListener('click', function (e) {
        e.stopPropagation();
        const id = this.dataset.detail;
        if (id === 'detail-recovery') pushPage('detail-recovery');
        else if (id === 'detail-sleep') pushPage('detail-sleep');
        else if (id === 'detail-heart') pushPage('detail-heart');
        else if (id === 'anomaly') pushPage('anomaly');
        else if (id === 'ecg') pushPage('ecg');
        else if (id === 'onboarding') pushPage('onboarding');
        else if (id === 'recovery') pushPage('detail-recovery');
        else if (id === 'sleepDetail') pushPage('detail-sleep');
        else if (id === 'heart') renderHeartPage();
      });
    });

    document.querySelectorAll('[data-back]').forEach(el => {
      el.addEventListener('click', () => popPage());
    });

    document.querySelectorAll('[data-filter]').forEach(el => {
      el.addEventListener('click', function () {
        anomalyFilter = this.dataset.filter;
        renderAnomaly();
      });
    });

    document.querySelectorAll('[data-screen]').forEach(el => {
      el.addEventListener('click', function (e) {
        e.stopPropagation();
        const screen = this.dataset.screen;
        if (screen === 'ecg') pushPage('ecg');
      });
    });
  }

  function bindAgencyToggle() {
    const agent = document.getElementById('toggleAgent');
    const explore = document.getElementById('toggleExplore');
    if (!agent || !explore) return;

    agent.addEventListener('click', () => {
      state.agencyMode = 'agentGuided';
      agent.className = 'agency-btn';
      agent.style.background = '';
      agent.style.color = '';
      explore.className = 'agency-btn';
      explore.style.background = '';
      explore.style.color = '';
      // Re-render with new mode
      renderToday();
    });

    explore.addEventListener('click', () => {
      state.agencyMode = 'selfExplore';
      explore.className = 'agency-btn';
      explore.style.background = '';
      explore.style.color = '';
      agent.className = 'agency-btn';
      agent.style.background = '';
      agent.style.color = '';
      renderToday();
    });
  }

  function bindAskBar() {
    const input = document.getElementById('askInput');
    const btn = document.getElementById('sendBtn');
    if (!input || !btn) return;

    const queries = {
      '为什么这么累': { q: '为什么我最近总是觉得很累？', resp: '主要和睡眠时长不足、运动恢复不够有关。' },
      '睡眠': { q: '如何改善我的睡眠质量？', resp: '建议保持规律作息，睡前减少蓝光暴露，目标 7-8 小时。' },
      '心率': { q: '最近心率为什么偏高？', resp: '可能与近期运动负荷上升和压力水平有关，建议关注恢复。' },
      '运动': { q: '今天适合运动吗？', resp: '恢复分数偏低，建议选择轻度活动，如散步或拉伸。' },
      '压力': { q: '我最近压力怎么样？', resp: 'HRV 趋势显示近期压力略有上升，建议增加放松时间。' },
    };

    function processQuery(text) {
      const lower = text.toLowerCase();
      for (const [key, val] of Object.entries(queries)) {
        if (lower.includes(key)) return val;
      }
      return { q: text, resp: '我正在分析你的健康数据，请稍等...' };
    }

    function handleSend() {
      const text = input.value.trim();
      if (!text) return;

      const result = processQuery(text);
      showToast(`AI 分析中…`);

      setTimeout(() => {
        pushPage('detail-recovery');
        app.innerHTML = `
          <div class="page">
            <div class="detail-header">
              <button class="back-btn" data-back>‹</button>
              <div>
                <h1 class="title-lg">${result.q}</h1>
              </div>
            </div>
            <div class="card summary-card">
              <h2>分析结果</h2>
              <p class="body-copy">${result.resp}</p>
            </div>
            <div class="section-title"><h2>相关证据</h2></div>
            <div class="delta-grid">
              ${deltaCard('睡眠', '6h12m', '略低于目标', colors.sleep)}
              ${deltaCard('恢复', '62', '需关注', colors.recovery)}
              ${deltaCard('静息心率', '60 bpm', '正常范围', colors.heart)}
            </div>
            <div class="section-title"><h2>建议</h2></div>
            <div class="chips">
              <button class="chip">只看睡眠</button>
              <button class="chip">运动建议</button>
              <button class="chip">深入分析</button>
            </div>
          </div>
        `;
        bindDetailLinks();
      }, 800);

      input.value = '';
    }

    btn.addEventListener('click', handleSend);
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') handleSend();
    });

    // Focus input on "问" tab click
    document.querySelector('.tab-center').addEventListener('click', () => {
      setTimeout(() => input.focus(), 100);
    });
  }

  function bindActionCompletion() {
    document.addEventListener('click', (e) => {
      const btn = e.target.closest('.action-check');
      if (!btn) return;
      btn.classList.toggle('done');
      const label = btn.classList.contains('done') ? '已完成 ✓' : '已取消';
      showToast(label);
    });

    document.addEventListener('click', (e) => {
      const fb = e.target.closest('.feedback-btn');
      if (!fb) return;
      const fbText = {
        tooHard: '已记录难度偏好，将推荐更简单行动',
        notSuitable: '已记录你的偏好设置',
        replace: '已为你换个建议',
      }[fb.dataset.fb] || '反馈已记录';
      showToast(fbText);
    });
  }

  // === Tab Navigation ===

  tabbarEl.addEventListener('click', (e) => {
    const btn = e.target.closest('.tab-btn');
    if (!btn || btn.classList.contains('tab-center')) return;
    state.tab = btn.dataset.tab;
    state.pageStack = [];
    renderPage(state.tab);
  });

  // === Toast ===

  let toastTimer = null;
  function showToast(msg, duration = 2000) {
    toastEl.textContent = msg;
    toastEl.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toastEl.classList.remove('show'), duration);
  }

  // === Initial Render ===
  renderToday();

})();