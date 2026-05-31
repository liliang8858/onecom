from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "lessons" / "assets" / "06-llm-call-shape"

FONT_CANDIDATES = [
    "C:/Windows/Fonts/msyh.ttc",
    "C:/Windows/Fonts/simhei.ttf",
    "C:/Windows/Fonts/simsun.ttc",
    "C:/Windows/Fonts/arial.ttf",
]
FONT_BOLD_CANDIDATES = [
    "C:/Windows/Fonts/msyhbd.ttc",
    "C:/Windows/Fonts/simhei.ttf",
    *FONT_CANDIDATES,
]

COLORS = {
    "bg": "#F7F8FA",
    "ink": "#172033",
    "muted": "#5E6A7D",
    "line": "#C8D0DC",
    "blue": "#2F6FED",
    "blue2": "#E8F0FF",
    "green": "#1A8F63",
    "green2": "#E7F6EF",
    "orange": "#C45A1A",
    "orange2": "#FFF1E6",
    "red": "#B42318",
    "red2": "#FEECEC",
    "purple": "#6A4BBC",
    "purple2": "#F0ECFF",
    "dark": "#111827",
    "white": "#FFFFFF",
}


def load_font(size: int, *, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = FONT_BOLD_CANDIDATES if bold else FONT_CANDIDATES
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


TITLE = load_font(56, bold=True)
SUBTITLE = load_font(28)
HEADING = load_font(28, bold=True)
BODY = load_font(23)
SMALL = load_font(19)


def new_canvas(width: int = 1600, height: int = 900) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGB", (width, height), COLORS["bg"])
    return image, ImageDraw.Draw(image)


def draw_text(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int],
    value: str,
    font: ImageFont.ImageFont = BODY,
    fill: str = COLORS["ink"],
    *,
    anchor: str | None = None,
) -> None:
    draw.text(xy, value, font=font, fill=fill, anchor=anchor)


def wrap_text(
    draw: ImageDraw.ImageDraw,
    value: str,
    font: ImageFont.ImageFont,
    max_width: int,
) -> list[str]:
    lines: list[str] = []
    for paragraph in value.splitlines() or [""]:
        current = ""
        for char in paragraph:
            candidate = current + char
            if draw.textlength(candidate, font=font) <= max_width or not current:
                current = candidate
            else:
                lines.append(current)
                current = char
        if current:
            lines.append(current)
    return lines


def rounded_card(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    fill: str = COLORS["white"],
    outline: str = COLORS["line"],
    radius: int = 20,
) -> None:
    x1, y1, x2, y2 = box
    draw.rounded_rectangle((x1 + 5, y1 + 7, x2 + 5, y2 + 7), radius=radius, fill="#DFE5EE")
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=2)


def arrow(
    draw: ImageDraw.ImageDraw,
    start: tuple[int, int],
    end: tuple[int, int],
    color: str = COLORS["muted"],
    width: int = 4,
) -> None:
    import math

    draw.line([start, end], fill=color, width=width)
    x1, y1 = start
    x2, y2 = end
    angle = math.atan2(y2 - y1, x2 - x1)
    size = 14
    points = []
    for offset in (2.65, -2.65):
        points.append((x2 - size * math.cos(angle + offset), y2 - size * math.sin(angle + offset)))
    draw.polygon([end, *points], fill=color)


def label_card(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    title: str,
    body: str,
    color: str,
    fill: str,
) -> None:
    rounded_card(draw, box)
    x1, y1, x2, _ = box
    draw.rounded_rectangle((x1 + 18, y1 + 18, x1 + 66, y1 + 66), radius=12, fill=fill, outline=color, width=2)
    draw_text(draw, (x1 + 42, y1 + 42), title[:1], HEADING, color, anchor="mm")
    title_font = HEADING
    title_max_width = x2 - x1 - 100
    for candidate_size in (28, 24, 21, 18):
        candidate = load_font(candidate_size, bold=True)
        if draw.textlength(title, font=candidate) <= title_max_width:
            title_font = candidate
            break
    draw_text(draw, (x1 + 82, y1 + 22), title, title_font)
    y = y1 + 62
    for line in wrap_text(draw, body, SMALL, x2 - x1 - 104):
        draw_text(draw, (x1 + 82, y), line, SMALL, COLORS["muted"])
        y += 28


def dense_box(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    title: str,
    lines: list[str],
    color: str,
    fill: str,
) -> None:
    rounded_card(draw, box, fill=COLORS["white"])
    x1, y1, x2, _ = box
    draw.rounded_rectangle((x1 + 16, y1 + 16, x2 - 16, y1 + 54), radius=12, fill=fill, outline=color, width=2)
    draw_text(draw, (x1 + 32, y1 + 22), title, load_font(22, bold=True), color)
    y = y1 + 72
    for line in lines:
        if y > box[3] - 26:
            break
        draw.ellipse((x1 + 24, y + 7, x1 + 33, y + 16), fill=color)
        for wrapped in wrap_text(draw, line, SMALL, x2 - x1 - 60):
            if y > box[3] - 26:
                break
            draw_text(draw, (x1 + 44, y), wrapped, SMALL, COLORS["ink"])
            y += 25
        y += 5


def table_box(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    title: str,
    headers: list[str],
    rows: list[list[str]],
    widths: list[int],
    color: str,
) -> None:
    rounded_card(draw, box, fill=COLORS["white"])
    x1, y1, _, _ = box
    draw_text(draw, (x1 + 22, y1 + 18), title, load_font(23, bold=True), color)
    y = y1 + 58
    x = x1 + 22
    for header, width in zip(headers, widths):
        draw.rounded_rectangle((x, y, x + width, y + 34), radius=8, fill="#EEF2F7", outline=COLORS["line"], width=1)
        draw_text(draw, (x + 10, y + 7), header, SMALL, COLORS["muted"])
        x += width
    y += 38
    for row in rows:
        x = x1 + 22
        row_height = 48
        for value, width in zip(row, widths):
            draw.rounded_rectangle((x, y, x + width, y + row_height), radius=8, fill="#FFFFFF", outline=COLORS["line"], width=1)
            line_y = y + 8
            for wrapped in wrap_text(draw, value, load_font(17), width - 16)[:2]:
                draw_text(draw, (x + 8, line_y), wrapped, load_font(17), COLORS["ink"])
                line_y += 21
            x += width
        y += row_height + 6


def code_panel(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    title: str,
    lines: list[str],
) -> None:
    rounded_card(draw, box, fill=COLORS["dark"], outline=COLORS["dark"])
    x1, y1, _, _ = box
    draw_text(draw, (x1 + 22, y1 + 18), title, load_font(22, bold=True), "#FFFFFF")
    mono = load_font(18)
    y = y1 + 58
    for line in lines:
        draw_text(draw, (x1 + 22, y), line, mono, "#D8DEE9")
        y += 26


def save(image: Image.Image, filename: str) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    image.save(OUT_DIR / filename, quality=94)


def draw_cover() -> None:
    image, draw = new_canvas()
    draw.rectangle((0, 0, 1600, 900), fill="#F6F8FC")
    draw.rectangle((0, 0, 1600, 150), fill=COLORS["white"])
    draw_text(draw, (90, 55), "第 06 章", HEADING, COLORS["blue"])
    draw_text(draw, (90, 118), "LLM 调用长什么样", TITLE)
    draw_text(draw, (90, 183), "从 Message、LLMRequest、LLMResponse 开始，先建立企业级模型调用边界。", SUBTITLE, COLORS["muted"])

    rounded_card(draw, (80, 260, 1520, 820))
    pipeline = [
        ("1 应用意图", "任务、上下文、策略", COLORS["blue"], COLORS["blue2"]),
        ("2 消息数组", "系统 / 用户 / 助手 / 工具", COLORS["green"], COLORS["green2"]),
        ("3 标准请求", "模型、温度、输出上限、元数据", COLORS["purple"], COLORS["purple2"]),
        ("4 客户端层", "第 07 章模拟\n第 08 章真实", COLORS["orange"], COLORS["orange2"]),
        ("5 标准响应", "回答、用量、结束状态、原始 id", COLORS["red"], COLORS["red2"]),
    ]
    x = 115
    for index, (title, body, color, fill) in enumerate(pipeline):
        label_card(draw, (x, 335, x + 230, 560), title, body, color, fill)
        if index < len(pipeline) - 1:
            arrow(draw, (x + 238, 445), (x + 288, 445))
        x += 270

    dense_box(
        draw,
        (120, 600, 470, 790),
        "本章工程交付",
        ["llm/messages.py", "test_llm_messages.py", "30 passed"],
        COLORS["blue"],
        COLORS["blue2"],
    )
    dense_box(
        draw,
        (520, 600, 910, 790),
        "企业级质量门",
        ["不可变对象", "早失败校验", "中立 payload", "用量可审计"],
        COLORS["green"],
        COLORS["green2"],
    )
    dense_box(
        draw,
        (960, 600, 1465, 790),
        "刻意暂缓",
        ["不接真实 API Key", "不做重试限流", "不做成本计算", "第 07-10 章接入"],
        COLORS["orange"],
        COLORS["orange2"],
    )
    draw_text(draw, (90, 840), "读图方法：先看中间调用链，再看下方交付、质量门与暂缓项。", BODY, COLORS["muted"])
    save(image, "cover.jpg")


def draw_boundary_map() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "模型调用边界图", TITLE)
    draw_text(draw, (80, 130), "第 06 章只定义边界，不实现网络客户端。这样后续替换模型供应商时不会冲击业务代码。", SUBTITLE, COLORS["muted"])
    draw.rounded_rectangle((80, 210, 1520, 272), radius=16, fill="#FFFFFF", outline=COLORS["line"], width=2)
    for x, title, color in [(120, "业务层", COLORS["blue"]), (520, "边界层", COLORS["purple"]), (930, "客户端层", COLORS["orange"]), (1260, "治理层", COLORS["green"])]:
        draw_text(draw, (x, 228), title, HEADING, color)

    dense_box(draw, (90, 315, 400, 550), "业务层只说意图", ["用户问题", "系统约束", "工具结果", "对话历史摘要"], COLORS["blue"], COLORS["blue2"])
    dense_box(draw, (460, 315, 770, 550), "边界层负责契约", ["Message 白名单角色", "LLMRequest 参数校验", "LLMResponse 用量归一", "to_payload() 屏蔽厂商差异"], COLORS["purple"], COLORS["purple2"])
    dense_box(draw, (830, 315, 1140, 550), "客户端层可替换", ["MockLLMClient", "OpenAI-compatible", "Qwen / Claude / 本地模型", "超时、重试、限流在后续章节"], COLORS["orange"], COLORS["orange2"])
    dense_box(draw, (1200, 315, 1510, 550), "治理层可复用", ["日志追踪", "成本统计", "预算熔断", "审计与评估"], COLORS["green"], COLORS["green2"])
    arrow(draw, (400, 432), (460, 432))
    arrow(draw, (770, 432), (830, 432))
    arrow(draw, (1140, 432), (1200, 432))

    table_box(
        draw,
        (105, 590, 1495, 870),
        "边界设计的取舍",
        ["选择", "收益", "代价", "后续补齐"],
        [
            ["dataclass(frozen=True)", "调用对象不可变，测试稳定", "比 dict 多一层定义", "第 08 章接真实客户端"],
            ["tuple[Message, ...]", "避免运行中追加消息", "构造时要显式转换", "第 19 章接对话历史"],
            ["provider-neutral payload", "业务不绑定供应商", "不能覆盖所有厂商细节", "第 09 章路由适配"],
        ],
        [260, 330, 330, 330],
        COLORS["purple"],
    )
    save(image, "boundary-map.jpg")


def draw_message_stack() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "Message：最小但严格的消息对象", TITLE)
    draw_text(draw, (80, 130), "一次 chat 调用不是一段字符串，而是一组有角色的消息。角色边界决定模型如何理解上下文。", SUBTITLE, COLORS["muted"])
    table_box(
        draw,
        (80, 210, 980, 560),
        "角色矩阵",
        ["role", "谁写入", "典型内容", "风险"],
        [
            ["system", "平台 / 应用", "长期规则、输出约束", "泄露或被覆盖"],
            ["user", "真实用户", "问题、指令、业务输入", "提示注入"],
            ["assistant", "模型客户端", "模型上一轮回答", "伪造模型输出"],
            ["tool", "工具层", "检索、计算、API 结果", "未校验工具结果"],
        ],
        [120, 170, 300, 220],
        COLORS["green"],
    )
    dense_box(draw, (1030, 215, 1500, 560), "Message 校验规则", ["role 会 strip + lower", "role 必须属于白名单", "content 去空白后不能为空", "name 可选；出现时不能为空", "to_dict() 输出 API 友好结构"], COLORS["green"], COLORS["green2"])

    code_panel(
        draw,
        (105, 615, 755, 820),
        "对象示例",
        [
            'Message(role="system", content="回答要简洁")',
            'Message(role="user", content="总结事故")',
            'Message(role="assistant", content="已完成摘要")',
            'Message(role="tool", content="日志命中 3 条")',
        ],
    )
    dense_box(
        draw,
        (820, 615, 1495, 820),
        "为什么不直接传字符串",
        ["字符串无法表达系统规则、用户输入和工具结果的来源", "角色边界让测试能断言上下文顺序", "后续做 Prompt Injection 防护时，需要知道哪些内容来自用户"],
        COLORS["red"],
        COLORS["red2"],
    )
    save(image, "message-stack.jpg")


def draw_request_payload() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "LLMRequest：把调用参数收拢到一个对象", TITLE)
    draw_text(draw, (80, 130), "请求对象要同时服务教学、测试、日志、审计和后续真实客户端。", SUBTITLE, COLORS["muted"])
    table_box(
        draw,
        (80, 215, 960, 680),
        "LLMRequest 字段契约",
        ["字段", "类型", "校验", "为什么需要"],
        [
            ["model", "str", "strip 后非空", "路由与成本归属"],
            ["messages", "tuple[Message,...]", "至少 1 条且类型正确", "上下文稳定"],
            ["temperature", "float", "0 到 2", "控制随机性"],
            ["max_output_tokens", "int | None", "如果设置必须 > 0", "限制输出成本"],
            ["metadata", "Mapping[str,str]", "key/value 非空", "追踪与审计"],
        ],
        [150, 190, 230, 230],
        COLORS["purple"],
    )
    code_panel(
        draw,
        (1010, 215, 1500, 680),
        "to_payload() 输出",
        [
            "{",
            '  "model": "mock-chat",',
            '  "messages": [',
            '    {"role": "system", "content": "..."},',
            '    {"role": "user", "content": "..."}',
            "  ],",
            '  "temperature": 0.0,',
            '  "metadata": {"trace_id": "req-001"}',
            "}",
        ],
    )
    dense_box(draw, (100, 725, 500, 850), "测试覆盖", ["默认 temperature", "空 model 拒绝", "空 messages 拒绝", "非法输出上限拒绝"], COLORS["blue"], COLORS["blue2"])
    dense_box(draw, (600, 725, 1000, 850), "工程收益", ["后续客户端只接收一个对象", "日志可记录 request.metadata", "路由层可按 model 和任务类型决策"], COLORS["green"], COLORS["green2"])
    dense_box(draw, (1100, 725, 1500, 850), "安全边界", ["metadata 不能放 API Key", "消息内容后续再做注入扫描", "请求对象不负责网络重试"], COLORS["red"], COLORS["red2"])
    save(image, "request-payload.jpg")


def draw_response_usage() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "LLMResponse：回答之外，还要带回可运营信息", TITLE)
    draw_text(draw, (80, 130), "企业级模型调用不能只拿文本。成本、限额、追踪和失败分析都依赖响应边界。", SUBTITLE, COLORS["muted"])
    table_box(
        draw,
        (80, 215, 1030, 650),
        "LLMResponse 字段契约",
        ["字段", "类型", "校验", "后续用途"],
        [
            ["model", "str", "非空", "模型路由回填"],
            ["message", "Message", "role 必须 assistant", "最终回答"],
            ["input_tokens", "int", "不得为负", "输入成本"],
            ["output_tokens", "int", "不得为负", "输出成本"],
            ["finish_reason", "str", "非空", "截断与工具调用判断"],
            ["raw_id", "str | None", "出现时非空", "供应商审计"],
        ],
        [150, 190, 230, 260],
        COLORS["green"],
    )
    dense_box(
        draw,
        (1080, 220, 1500, 455),
        "usage() 统一口径",
        ["input_tokens", "output_tokens", "total_tokens", "第 10 章直接用于成本统计"],
        COLORS["green"],
        COLORS["green2"],
    )
    dense_box(
        draw,
        (1080, 490, 1500, 650),
        "响应防错",
        ["用户消息不能伪装成模型回答", "负 token 立即失败", "finish_reason 为空立即失败"],
        COLORS["red"],
        COLORS["red2"],
    )
    code_panel(
        draw,
        (120, 705, 1480, 850),
        "运营链路",
        [
            "LLMResponse -> usage() -> 成本统计 -> 预算熔断 -> 评估流水线 -> 审计报表",
            "raw_id + metadata.trace_id -> 真实供应商排障 + 企业内部请求追踪",
        ],
    )
    save(image, "response-usage.jpg")


def main() -> None:
    draw_cover()
    draw_boundary_map()
    draw_message_stack()
    draw_request_payload()
    draw_response_usage()
    print(f"Generated lesson 06 assets in {OUT_DIR}")


if __name__ == "__main__":
    main()
