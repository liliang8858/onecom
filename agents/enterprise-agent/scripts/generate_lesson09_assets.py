from __future__ import annotations

from pathlib import Path

from generate_lesson06_assets import (
    BODY,
    COLORS,
    HEADING,
    SUBTITLE,
    TITLE,
    arrow,
    code_panel,
    dense_box,
    draw_text,
    label_card,
    new_canvas,
    rounded_card,
    table_box,
)


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "lessons" / "assets" / "09-llm-router"


def save(image, filename: str) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    image.save(OUT_DIR / filename, quality=94)


def draw_cover() -> None:
    image, draw = new_canvas()
    draw.rectangle((0, 0, 1600, 900), fill="#F6F8FC")
    draw.rectangle((0, 0, 1600, 150), fill=COLORS["white"])
    draw_text(draw, (90, 55), "第 09 章", HEADING, COLORS["blue"])
    draw_text(draw, (90, 118), "多模型路由入门", TITLE)
    draw_text(draw, (90, 183), "用 task_type 把一次 LLMRequest 交给合适的模型和客户端。", SUBTITLE, COLORS["muted"])

    rounded_card(draw, (80, 260, 1520, 820))
    stages = [
        ("请求", "LLMRequest\nmetadata.task_type", COLORS["blue"], COLORS["blue2"]),
        ("路由器", "LLMRouter\nroute_for()", COLORS["purple"], COLORS["purple2"]),
        ("默认路由", "general-chat\nfallback", COLORS["green"], COLORS["green2"]),
        ("任务路由", "coding\nreasoning", COLORS["orange"], COLORS["orange2"]),
        ("客户端", "Mock 或真实\nBaseLLMClient", COLORS["red"], COLORS["red2"]),
    ]
    x = 115
    for index, (title, body, color, fill) in enumerate(stages):
        label_card(draw, (x, 330, x + 230, 560), title, body, color, fill)
        if index < len(stages) - 1:
            arrow(draw, (x + 238, 445), (x + 288, 445))
        x += 270

    dense_box(draw, (120, 600, 470, 790), "本章新增对象", ["LLMRoute", "LLMRouter", "DEFAULT_LLM_TASK_TYPE", "test_llm_router.py"], COLORS["blue"], COLORS["blue2"])
    dense_box(draw, (520, 600, 910, 790), "模型选择依据", ["task_type", "默认兜底", "请求设置保留", "model 由路由改写"], COLORS["green"], COLORS["green2"])
    dense_box(draw, (960, 600, 1465, 790), "刻意不做", ["不做智能路由", "不做成本排序", "不做健康检查", "不做动态权重"], COLORS["orange"], COLORS["orange2"])
    draw_text(draw, (90, 852), "读图方法：路由层只决定交给谁，不解释 prompt，也不评价模型输出质量。", BODY, COLORS["muted"])
    save(image, "cover.jpg")


def draw_routing_map() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "路由地图：task_type 决定模型和客户端", TITLE)
    draw_text(draw, (80, 130), "上层只提供任务类型；路由器负责选择路线并改写请求中的 model。", SUBTITLE, COLORS["muted"])

    dense_box(draw, (90, 235, 410, 540), "调用方", ["messages", "temperature", "max_output_tokens", "metadata.task_type"], COLORS["blue"], COLORS["blue2"])
    dense_box(draw, (500, 235, 830, 540), "LLMRouter", ["读取 task_type", "查找 route", "未知任务走默认", "保留请求设置"], COLORS["purple"], COLORS["purple2"])
    dense_box(draw, (920, 180, 1240, 410), "默认路线", ["task: chat", "model: general-chat", "client: default"], COLORS["green"], COLORS["green2"])
    dense_box(draw, (920, 470, 1240, 700), "任务路线", ["task: reasoning", "model: reasoning-model", "client: reasoning"], COLORS["orange"], COLORS["orange2"])
    dense_box(draw, (1320, 310, 1530, 570), "响应", ["LLMResponse", "assistant", "usage", "raw_id"], COLORS["red"], COLORS["red2"])
    arrow(draw, (410, 388), (500, 388))
    arrow(draw, (830, 330), (920, 295))
    arrow(draw, (830, 450), (920, 585))
    arrow(draw, (1240, 295), (1320, 395))
    arrow(draw, (1240, 585), (1320, 490))

    table_box(
        draw,
        (100, 745, 1500, 860),
        "路由前后请求变化",
        ["字段", "路由前", "路由后", "原因"],
        [
            ["model", "caller-placeholder", "route.model", "模型选择由路由层集中管理"],
            ["messages / temperature / metadata", "原请求", "保留", "路由只改模型，不改用户语义"],
        ],
        [300, 330, 330, 360],
        COLORS["purple"],
    )
    save(image, "routing-map.jpg")


def draw_route_contract() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "LLMRoute 契约：模型名加客户端", TITLE)
    draw_text(draw, (80, 130), "一个 route 不包含复杂策略，只说明某类任务应该交给哪个模型和哪个 BaseLLMClient。", SUBTITLE, COLORS["muted"])

    table_box(
        draw,
        (80, 215, 1040, 640),
        "对象职责",
        ["对象", "字段 / 方法", "职责", "校验"],
        [
            ["LLMRoute", "model", "目标模型名", "非空"],
            ["LLMRoute", "client", "执行调用的客户端", "BaseLLMClient"],
            ["LLMRouter", "default_route", "未知或缺省任务兜底", "LLMRoute"],
            ["LLMRouter", "task_routes", "任务类型到 route 的映射", "key 非空"],
            ["LLMRouter", "route_for()", "返回匹配或默认路线", "task_type 归一化"],
            ["LLMRouter", "complete()", "改写模型并调用客户端", "request 类型"],
        ],
        [210, 230, 330, 190],
        COLORS["green"],
    )
    code_panel(
        draw,
        (1090, 215, 1500, 640),
        "最小配置",
        [
            "router = LLMRouter(",
            "  default_route=LLMRoute(",
            "    model='general-chat',",
            "    client=MockLLMClient(),",
            "  ),",
            "  task_routes={",
            "    'reasoning': LLMRoute(...),",
            "  },",
            ")",
        ],
    )
    dense_box(draw, (110, 705, 500, 850), "为什么默认兜底", ["调用方可逐步接入 task_type", "未知任务仍可回答", "工程迁移更平滑"], COLORS["blue"], COLORS["blue2"])
    dense_box(draw, (605, 705, 995, 850), "为什么不智能判断", ["避免隐藏 prompt 逻辑", "保持可测试", "策略后续再演进"], COLORS["orange"], COLORS["orange2"])
    dense_box(draw, (1100, 705, 1490, 850), "测试证据", ["selected client.calls", "response.model", "metadata 保留", "unknown fallback"], COLORS["purple"], COLORS["purple2"])
    save(image, "route-contract.jpg")


def draw_testing_matrix() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "测试矩阵：路由层要证明选对对象", TITLE)
    draw_text(draw, (80, 130), "第 09 章测试不评价模型聪明与否，只验证模型选择和请求传递。", SUBTITLE, COLORS["muted"])

    table_box(
        draw,
        (80, 215, 1500, 650),
        "第 09 章单元测试覆盖",
        ["测试点", "断言", "证明什么", "后续价值"],
        [
            ["route 校验", "model 非空、client 类型", "路由配置可信", "减少启动期错误"],
            ["默认路线", "缺少 task_type 走 default", "兜底策略可用", "普通聊天"],
            ["任务路线", "reasoning 走 reasoning client", "任务选择生效", "复杂任务模型"],
            ["请求保留", "temperature、max_tokens、metadata", "路由不改语义", "成本和追踪"],
            ["未知任务", "fallback default", "渐进接入", "兼容老调用方"],
            ["配置错误", "空 task_type、非法 request", "边界早失败", "生产诊断"],
        ],
        [250, 360, 330, 330],
        COLORS["blue"],
    )
    dense_box(draw, (110, 710, 500, 850), "当前证据", ["48 passed", "MockLLMClient.calls", "response.model", "route_for()"], COLORS["green"], COLORS["green2"])
    dense_box(draw, (605, 710, 995, 850), "还不做", ["权重路由", "成本最优", "熔断切换", "模型健康检查"], COLORS["orange"], COLORS["orange2"])
    dense_box(draw, (1100, 710, 1490, 850), "下一章衔接", ["token 估算", "调用成本", "预算限制", "路由成本依据"], COLORS["purple"], COLORS["purple2"])
    save(image, "testing-matrix.jpg")


def main() -> None:
    draw_cover()
    draw_routing_map()
    draw_route_contract()
    draw_testing_matrix()
    print(f"Generated lesson 09 assets in {OUT_DIR}")


if __name__ == "__main__":
    main()
