from __future__ import annotations

from pathlib import Path

from generate_lesson06_assets import (
    BODY,
    COLORS,
    HEADING,
    SMALL,
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
OUT_DIR = ROOT / "docs" / "lessons" / "assets" / "07-mock-llm-client"


def save(image, filename: str) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    image.save(OUT_DIR / filename, quality=94)


def draw_cover() -> None:
    image, draw = new_canvas()
    draw.rectangle((0, 0, 1600, 900), fill="#F6F8FC")
    draw.rectangle((0, 0, 1600, 150), fill=COLORS["white"])
    draw_text(draw, (90, 55), "第 07 章", HEADING, COLORS["blue"])
    draw_text(draw, (90, 118), "MockLLMClient：不用 API Key 学模型调用", TITLE)
    draw_text(draw, (90, 183), "把第 06 章的数据边界接成一次可测试、可审计、可替换的客户端调用。", SUBTITLE, COLORS["muted"])

    rounded_card(draw, (80, 260, 1520, 820))
    stages = [
        ("1 请求", "标准请求\n来自第 06 章", COLORS["blue"], COLORS["blue2"]),
        ("2 抽象接口", "统一方法\n异步返回", COLORS["purple"], COLORS["purple2"]),
        ("3 模拟实现", "无网络\n无密钥", COLORS["green"], COLORS["green2"]),
        ("4 稳定响应", "固定文本\n固定用量", COLORS["orange"], COLORS["orange2"]),
        ("5 测试证据", "调用历史\nraw_id 递增", COLORS["red"], COLORS["red2"]),
    ]
    x = 115
    for index, (title, body, color, fill) in enumerate(stages):
        label_card(draw, (x, 330, x + 230, 560), title, body, color, fill)
        if index < len(stages) - 1:
            arrow(draw, (x + 238, 445), (x + 288, 445))
        x += 270

    dense_box(draw, (120, 600, 470, 790), "本章工程交付", ["llm/clients.py", "BaseLLMClient", "MockLLMClient", "test_mock_llm_client.py"], COLORS["blue"], COLORS["blue2"])
    dense_box(draw, (520, 600, 910, 790), "企业级质量门", ["异步接口先行", "响应稳定可断言", "调用历史只读", "无外部网络依赖"], COLORS["green"], COLORS["green2"])
    dense_box(draw, (960, 600, 1465, 790), "刻意暂缓", ["不做真实 SDK", "不做重试限流", "不做供应商鉴权", "第 08 章接真实边界"], COLORS["orange"], COLORS["orange2"])
    draw_text(draw, (90, 852), "读图方法：Mock 不是玩具代码，它是后续 Agent、工具、路由和评估的可控测试替身。", BODY, COLORS["muted"])
    save(image, "cover.jpg")


def draw_client_boundary() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "客户端边界：业务只认 BaseLLMClient", TITLE)
    draw_text(draw, (80, 130), "第 07 章先把客户端形状固定下来，避免后续真实供应商接入时冲击 Agent 代码。", SUBTITLE, COLORS["muted"])

    dense_box(draw, (90, 225, 410, 520), "调用方", ["Agent 或服务层", "只构造 LLMRequest", "不关心供应商 SDK", "不直接读 API Key"], COLORS["blue"], COLORS["blue2"])
    dense_box(draw, (500, 225, 820, 520), "抽象边界", ["BaseLLMClient", "async complete(request)", "输入：LLMRequest", "输出：LLMResponse"], COLORS["purple"], COLORS["purple2"])
    dense_box(draw, (910, 225, 1230, 520), "当前实现", ["MockLLMClient", "无网络调用", "固定响应文本", "固定 token usage"], COLORS["green"], COLORS["green2"])
    dense_box(draw, (1280, 225, 1530, 520), "后续实现", ["真实客户端", "超时", "重试", "限流"], COLORS["orange"], COLORS["orange2"])
    arrow(draw, (410, 372), (500, 372))
    arrow(draw, (820, 372), (910, 372))
    arrow(draw, (1230, 372), (1280, 372))

    table_box(
        draw,
        (105, 590, 1495, 850),
        "设计取舍",
        ["选择", "收益", "代价", "后续章节"],
        [
            ["异步 complete()", "提前兼容真实网络 IO", "测试要用 asyncio.run()", "第 08 章真实客户端"],
            ["ABC 抽象类", "强制统一客户端方法", "比普通函数多一层", "第 09 章模型路由"],
            ["Mock 记录 calls", "Agent 测试可验证请求", "Mock 有少量状态", "第 13-17 章 Agent 测试"],
        ],
        [260, 330, 330, 330],
        COLORS["purple"],
    )
    save(image, "client-boundary.jpg")


def draw_async_flow() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "异步调用流程：现在模拟，未来接网络", TITLE)
    draw_text(draw, (80, 130), "本章不用真实 API，但接口形状要和真实网络客户端兼容。", SUBTITLE, COLORS["muted"])

    table_box(
        draw,
        (80, 220, 980, 610),
        "complete(request) 执行步骤",
        ["步骤", "Mock 行为", "真实客户端未来行为", "可测试证据"],
        [
            ["1", "校验 request 类型", "校验请求与认证前置", "TypeError"],
            ["2", "记录到 calls", "记录 trace / metrics", "client.calls"],
            ["3", "生成 raw_id", "读取供应商 response id", "mock-response-0001"],
            ["4", "构造 LLMResponse", "归一化供应商返回", "assistant message"],
            ["5", "返回稳定结果", "处理超时/重试/限流", "usage()"],
        ],
        [80, 250, 300, 220],
        COLORS["green"],
    )
    code_panel(
        draw,
        (1030, 220, 1500, 610),
        "测试中的调用",
        [
            "client = MockLLMClient()",
            "request = LLMRequest(...)",
            "",
            "response = asyncio.run(",
            "    client.complete(request)",
            ")",
            "",
            "assert response.message.role == 'assistant'",
        ],
    )
    dense_box(draw, (110, 675, 500, 845), "为什么现在就异步", ["真实模型调用一定是 IO", "Agent 循环后续会等待工具和模型", "早固定接口，晚接 SDK"], COLORS["blue"], COLORS["blue2"])
    dense_box(draw, (605, 675, 995, 845), "为什么不用 pytest-asyncio", ["当前章节不增加依赖", "asyncio.run() 足够清楚", "先学习边界，不学习插件"], COLORS["orange"], COLORS["orange2"])
    dense_box(draw, (1100, 675, 1490, 845), "失败边界", ["非 LLMRequest 立即失败", "空响应配置立即失败", "负 token 配置立即失败"], COLORS["red"], COLORS["red2"])
    save(image, "async-flow.jpg")


def draw_mock_contract() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "MockLLMClient 契约：稳定、可控、可审计", TITLE)
    draw_text(draw, (80, 130), "Mock 的价值不是假装聪明，而是让上层代码在没有 API Key 时仍然能被严格测试。", SUBTITLE, COLORS["muted"])

    table_box(
        draw,
        (80, 215, 1030, 660),
        "MockLLMClient 字段契约",
        ["字段", "默认值", "校验", "用途"],
        [
            ["response_text", "deterministic response", "非空", "稳定回答"],
            ["input_tokens", "10", "不得为负", "模拟输入成本"],
            ["output_tokens", "5", "不得为负", "模拟输出成本"],
            ["finish_reason", "stop", "非空", "模拟结束原因"],
            ["raw_id_prefix", "mock-response", "非空", "生成可追踪 id"],
            ["calls", "只读 tuple", "内部 list 外部不可改", "验证请求传递"],
        ],
        [170, 250, 190, 220],
        COLORS["green"],
    )
    dense_box(draw, (1080, 225, 1500, 455), "稳定性原则", ["相同配置返回相同文本", "raw_id 只随调用次数递增", "token usage 固定可断言", "不随机、不访问网络"], COLORS["green"], COLORS["green2"])
    dense_box(draw, (1080, 495, 1500, 660), "反模式", ["Mock 不应该偷偷调用真实 API", "Mock 不应该生成随机答案", "Mock 不应该吞掉非法请求"], COLORS["red"], COLORS["red2"])
    code_panel(
        draw,
        (120, 720, 1480, 850),
        "响应形状",
        [
            "LLMResponse(model=request.model, message=Message(role='assistant', content=response_text),",
            "            input_tokens=10, output_tokens=5, finish_reason='stop', raw_id='mock-response-0001')",
        ],
    )
    save(image, "mock-contract.jpg")


def draw_testing_matrix() -> None:
    image, draw = new_canvas()
    draw_text(draw, (80, 70), "测试矩阵：Mock 客户端不是只测 happy path", TITLE)
    draw_text(draw, (80, 130), "第 07 章测试要证明客户端边界、响应结构、调用历史和失败路径都可控。", SUBTITLE, COLORS["muted"])

    table_box(
        draw,
        (80, 215, 1500, 640),
        "单元测试覆盖",
        ["测试点", "断言内容", "为什么重要", "未来复用"],
        [
            ["实现 BaseLLMClient", "isinstance(client, BaseLLMClient)", "统一客户端入口", "真实客户端替换"],
            ["稳定响应", "assistant 内容、usage、finish_reason", "上层测试不抖动", "Agent 回答测试"],
            ["调用历史", "client.calls == (request,)", "证明请求传递", "工具/Agent 调试"],
            ["raw_id 递增", "0001、0002", "追踪多次调用", "日志与审计"],
            ["非法请求", "TypeError", "边界早失败", "真实客户端前置校验"],
            ["非法配置", "空文本、负 token", "Mock 自身可信", "评估用例稳定"],
        ],
        [250, 360, 330, 330],
        COLORS["blue"],
    )
    dense_box(draw, (110, 705, 500, 850), "当前证据", ["python -m pytest", "36 passed", "无网络依赖", "无 API Key 依赖"], COLORS["green"], COLORS["green2"])
    dense_box(draw, (605, 705, 995, 850), "还不能声称", ["不能代表真实模型质量", "不能覆盖供应商错误", "不能覆盖超时重试"], COLORS["orange"], COLORS["orange2"])
    dense_box(draw, (1100, 705, 1490, 850), "下一章补齐", ["真实客户端边界", "超时配置", "重试策略", "供应商错误归一"], COLORS["purple"], COLORS["purple2"])
    save(image, "testing-matrix.jpg")


def main() -> None:
    draw_cover()
    draw_client_boundary()
    draw_async_flow()
    draw_mock_contract()
    draw_testing_matrix()
    print(f"Generated lesson 07 assets in {OUT_DIR}")


if __name__ == "__main__":
    main()
