const stage = document.querySelector("#stage");

const boards = [
  { id: "ui001", title: "业务场景探索：首页、Agent 发现、恢复分析、ECG 解读", src: "./assets/ui001.png", width: 1448, height: 1086 },
  { id: "ui002", title: "业务场景探索：授权、行动建议、趋势中心、偏好设置", src: "./assets/ui002.png", width: 1448, height: 1086 },
  { id: "ui003", title: "核心体验：首页、恢复睡眠分析、异常中心、心脏 ECG", src: "./assets/ui003.png", width: 1536, height: 1024 },
  { id: "ui004", title: "智能问答、今日时间线、证据详情、健康周报", src: "./assets/ui004.png", width: 1536, height: 1024 }
];

function currentIndex() {
  const id = window.location.hash.replace("#", "");
  const index = boards.findIndex((board) => board.id === id);
  return index >= 0 ? index : 0;
}

function navigate(index) {
  const normalized = (index + boards.length) % boards.length;
  window.location.hash = boards[normalized].id;
}

function render() {
  const index = currentIndex();
  const board = boards[index];
  document.title = `Health Agent UI v2 - ${board.id}`;
  stage.style.setProperty("--board-width", `${board.width}px`);
  stage.style.setProperty("--board-height", `${board.height}px`);
  stage.innerHTML = `
    <img class="board" src="${board.src}" width="${board.width}" height="${board.height}" alt="${board.title}" draggable="false" />
    <button class="hotspot prev-zone" type="button" data-action="prev" aria-label="上一张 v2 设计稿"></button>
    <button class="hotspot next-zone" type="button" data-action="next" aria-label="下一张 v2 设计稿"></button>
    ${boards.map((item, pageIndex) => `<button class="hotspot page-zone page-${pageIndex + 1}" type="button" data-page="${pageIndex}" aria-label="查看 ${item.id}"></button>`).join("")}
    <span class="sr-status">当前显示 ${board.id}，${index + 1} / ${boards.length}</span>
  `;
}

stage.addEventListener("click", (event) => {
  const action = event.target.closest("[data-action]");
  if (action?.dataset.action === "prev") navigate(currentIndex() - 1);
  if (action?.dataset.action === "next") navigate(currentIndex() + 1);

  const page = event.target.closest("[data-page]");
  if (page) navigate(Number(page.dataset.page));
});

window.addEventListener("keydown", (event) => {
  if (event.key === "ArrowLeft") navigate(currentIndex() - 1);
  if (event.key === "ArrowRight") navigate(currentIndex() + 1);
  if (/^[1-4]$/.test(event.key)) navigate(Number(event.key) - 1);
});

let pointerStartX = null;
window.addEventListener("pointerdown", (event) => {
  pointerStartX = event.clientX;
});

window.addEventListener("pointerup", (event) => {
  if (pointerStartX === null) return;
  const delta = event.clientX - pointerStartX;
  pointerStartX = null;
  if (Math.abs(delta) < 50) return;
  navigate(currentIndex() + (delta < 0 ? 1 : -1));
});

window.addEventListener("hashchange", render);

if (!window.location.hash) {
  window.location.hash = boards[0].id;
} else {
  render();
}
