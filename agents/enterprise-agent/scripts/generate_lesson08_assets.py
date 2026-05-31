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
OUT_DIR = ROOT / "docs" / "lessons" / "assets" / "08-real-client-boundary"


def save(image, filename: str) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    image.save(OUT_DIR / filename, quality=94)


def draw_cover() -> None:
    image, draw = new_canvas()
    draw.rectangle((0, 0, 1600, 900), fill="#F6F8FC")
    draw.rectangle((0, 0, 1600, 150), fill=COLORS["white"])
    draw_text(draw, (90, 55), "第 08 章", HEADING, COLORS["blue"])
    draw_text(draw, (90, 118), "真实模型客户端边界", TITLE)
    draw_text(draw, (90, 183), "先固定 OpenAI-compatible 调用边界，再让真实网络和 SDK 进入工程。", SUBTITLE, COLORS["muted"])

    rounded_card(draw, (80, 260, 1520, 820))
    stages = [
        ("配置", "base_url\napi_key\nendpoint", COLORS["blue"], COLORS["blue2"]),
        ("请求", "LLMRequest\nmessages\nmax_tokens", COLORS["purple"], COLORS["purple2"]),
        ("传输", "post_json\n超时\n重试", COLORS["orange"], COLORS["orange2"]),
        ("供应商", "choices\nusage\nid", COLORS["green"], COLORS["green2"]),
        ("归一化", "LLMResponse\n错误类型\n可测试", COLORS["red"], COLORS["red2"]),
    ]
    x = 115
    for index, (title, body, color, fill) in enumerate(stages):
        label_card(draw, (x, 330, x + 230, 560), title, body, color, fill)
        if index < len(stages) - 1:
            arrow(draw, (x + 238, 445), (x + 288, 445))
        x += 270

    dense_box(draw, (120, 600, 470, 790), "本章新增对象", ["OpenAICompatibleClientConfig", "OpenAICompatibleTransport", "OpenAICompatibleLLMClient", "LLMProviderError"], COLORS["blue"], COLORS["blue2"])
    dense_box(draw, (520, 600, 910, 790), "边界原则", ["不在业务层碰 SDK", "真实调用返回 LLMResponse", "transport 可替换", "测试不需要 API Key"], COLORS["green"], COLORS["green2"])
    dense_box(draw, (960, 600, 1465, 790), "仍然暂缓", ["不引入真实 SDK", "不做流式输出", "不做成本计算", "不要求真实网络"], COLORS["orange"], COLORS["orange2"])
    draw_text(draw, (90, 852), "读图方法：真实客户端边界不是马上联网，而是把联网位置压缩到 transport 后面。", BODY, COLORS["muted"])
    save(image, "cover.jpg")


def draw_transport_boundary() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "Transport 边界：真实网络被隔离在一层接口后面", TITLE)
    draw_text(draw, (80, 130), "客户端负责构造 payload 和归一化 response；transport 只负责发送 JSON 并返回 JSON。", SUBTITLE, COLORS["muted"])

    dense_box(draw, (90, 235, 410, 540), "上层代码", ["只创建 LLMRequest", "只等待 LLMResponse", "不处理 SDK 对象", "不读供应商原始 JSON"], COLORS["blue"], COLORS["blue2"])
    dense_box(draw, (500, 235, 860, 540), "OpenAICompatibleLLMClient", ["构造 headers", "转换 max_output_tokens", "控制 timeout", "解析 choices 和 usage"], COLORS["purple"], COLORS["purple2"])
    dense_box(draw, (950, 235, 1245, 540), "Transport", ["post_json()", "可替换 fake", "真实实现可后加", "抛出 transport error"], COLORS["orange"], COLORS["orange2"])
    dense_box(draw, (1320, 235, 1530, 540), "Provider", ["HTTP API", "SDK", "choices", "usage"], COLORS["green"], COLORS["green2"])
    arrow(draw, (410, 388), (500, 388))
    arrow(draw, (860, 388), (950, 388))
    arrow(draw, (1245, 388), (1320, 388))

    table_box(
        draw,
        (100, 620, 1500, 850),
        "字段映射",
        ["本项目", "OpenAI-compatible", "说明", "测试断言"],
        [
            ["max_output_tokens", "max_tokens", "供应商字段差异留在客户端内", "payload"],
            ["input_tokens", "prompt_tokens", "归一化 token usage", "response.usage()"],
            ["output_tokens", "completion_tokens", "归一化 token usage", "response.usage()"],
            ["raw_id", "id", "保留供应商追踪 id", "response.raw_id"],
        ],
        [300, 320, 430, 250],
        COLORS["purple"],
    )
    save(image, "transport-boundary.jpg")


def draw_retry_normalization() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "超时、重试、错误归一化", TITLE)
    draw_text(draw, (80, 130), "第 08 章只重试传输错误；供应商返回结构错误直接暴露为 ProviderError。", SUBTITLE, COLORS["muted"])

    table_box(
        draw,
        (80, 220, 1020, 640),
        "失败分类",
        ["失败来源", "例子", "错误类型", "是否重试"],
        [
            ["transport", "TimeoutError", "LLMTransportError", "是"],
            ["transport", "ConnectionError", "LLMTransportError", "是"],
            ["provider shape", "choices 为空", "LLMProviderError", "否"],
            ["provider usage", "usage 不是对象", "LLMProviderError", "否"],
            ["request", "非 LLMRequest", "TypeError", "否"],
        ],
        [240, 250, 260, 150],
        COLORS["orange"],
    )
    code_panel(
        draw,
        (1070, 220, 1500, 640),
        "重试预算",
        [
            "attempts = max_retries + 1",
            "",
            "transport error -> retry",
            "provider error -> fail fast",
            "",
            "max_retries=2",
            "最多发送 3 次",
        ],
    )
    dense_box(draw, (110, 705, 500, 850), "为什么只重试传输错误", ["网络抖动可能恢复", "超时可能是暂态", "连接错误可能是瞬时"], COLORS["green"], COLORS["green2"])
    dense_box(draw, (605, 705, 995, 850), "为什么不重试结构错误", ["返回格式错通常不是暂态", "重试会放大成本", "测试应该尽早失败"], COLORS["red"], COLORS["red2"])
    dense_box(draw, (1100, 705, 1490, 850), "后续演进", ["指数退避", "限流识别", "熔断", "供应商错误码映射"], COLORS["purple"], COLORS["purple2"])
    save(image, "retry-normalization.jpg")


def draw_testing_matrix() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "测试矩阵：不联网也能测试真实客户端边界", TITLE)
    draw_text(draw, (80, 130), "FakeTransport 让测试覆盖 payload、headers、timeout、重试和响应解析。", SUBTITLE, COLORS["muted"])

    table_box(
        draw,
        (80, 215, 1500, 650),
        "第 08 章单元测试覆盖",
        ["测试点", "断言", "证明什么", "避免什么风险"],
        [
            ["配置归一化", "base_url、endpoint、timeout", "运行参数可靠", "URL 拼错"],
            ["payload", "messages、max_tokens、metadata", "请求形状正确", "字段泄漏到业务层"],
            ["response", "assistant、usage、raw_id", "供应商返回被归一化", "业务依赖原始 JSON"],
            ["retry", "失败两次后成功", "重试预算生效", "测试依赖真实网络"],
            ["exhausted", "失败后抛 LLMTransportError", "传输错误统一", "异常类型发散"],
            ["provider error", "choices 为空直接失败", "结构错误不重试", "重复浪费 token"],
        ],
        [250, 360, 330, 330],
        COLORS["blue"],
    )
    dense_box(draw, (110, 710, 500, 850), "当前证据", ["FakeTransport.calls", "48 passed", "无真实 API Key", "无网络访问"], COLORS["green"], COLORS["green2"])
    dense_box(draw, (605, 710, 995, 850), "仍未证明", ["真实供应商可用性", "模型回答质量", "真实 SDK 兼容性"], COLORS["orange"], COLORS["orange2"])
    dense_box(draw, (1100, 710, 1490, 850), "下一章衔接", ["LLMRouter", "任务类型", "模型选择", "客户端替换"], COLORS["purple"], COLORS["purple2"])
    save(image, "testing-matrix.jpg")


def main() -> None:
    draw_cover()
    draw_transport_boundary()
    draw_retry_normalization()
    draw_testing_matrix()
    print(f"Generated lesson 08 assets in {OUT_DIR}")


if __name__ == "__main__":
    main()
