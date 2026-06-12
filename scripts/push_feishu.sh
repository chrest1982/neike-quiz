#!/usr/bin/env bash
# 推送每日练习链接到飞书群机器人
# 用法:
#   FEISHU_WEBHOOK="https://open.feishu.cn/open-apis/bot/v2/hook/xxxx" \
#   [FEISHU_SECRET="签名密钥"] \
#   [FEISHU_KEYWORD="每日练习"] \
#   ./push_feishu.sh "https://用户名.github.io/neike-quiz/2026-06-12.html" "消化系统——肝硬化并发症"
#
# 安全设置二选一:
#   - 自定义关键词: 设置 FEISHU_KEYWORD, 标题中会带上该词
#   - 签名校验: 设置 FEISHU_SECRET, 脚本自动计算 HMAC-SHA256 签名
set -euo pipefail

URL="${1:?需传入当天练习网址}"
TOPIC="${2:-内科护理学正高每日练习}"
DATE="$(date +%Y-%m-%d)"
KEYWORD="${FEISHU_KEYWORD:-}"
: "${FEISHU_WEBHOOK:?需设置环境变量 FEISHU_WEBHOOK}"

TITLE="📋 内科护理学正高每日练习 · ${DATE}"
[ -n "$KEYWORD" ] && TITLE="${TITLE}（${KEYWORD}）"

# 富文本卡片正文
CONTENT="**今日主题：${TOPIC}**\n\n共 5 题（多选 2 + 案例 3），满分 5 分。\n点击下方链接在线作答并自动评分 👇\n\n[▶ 开始今日练习](${URL})"

# 计算签名(仅签名校验模式)
# 飞书算法: key = "timestamp\nsecret"(含真实换行), 对空消息做 HMAC-SHA256, 再 base64
SIGN_FIELDS=""
if [ -n "${FEISHU_SECRET:-}" ]; then
  TS="$(date +%s)"
  SIGN="$(printf '' | openssl dgst -sha256 -hmac "$(printf '%b' "${TS}\n${FEISHU_SECRET}")" -binary | base64)"
  SIGN_FIELDS="\"timestamp\":\"${TS}\",\"sign\":\"${SIGN}\","
fi

PAYLOAD=$(cat <<JSON
{
  ${SIGN_FIELDS}
  "msg_type": "interactive",
  "card": {
    "config": {"wide_screen_mode": true},
    "header": {"title": {"tag": "plain_text", "content": "${TITLE}"}, "template": "blue"},
    "elements": [
      {"tag": "div", "text": {"tag": "lark_md", "content": "${CONTENT}"}},
      {"tag": "action", "actions": [
        {"tag": "button", "text": {"tag": "plain_text", "content": "开始作答"},
         "type": "primary", "url": "${URL}"}
      ]}
    ]
  }
}
JSON
)

echo "推送内容预览:"; echo "$PAYLOAD"
RESP="$(curl -sS -X POST -H 'Content-Type: application/json' -d "$PAYLOAD" "$FEISHU_WEBHOOK")"
echo "飞书返回: $RESP"
echo "$RESP" | grep -q '"StatusCode":0\|"code":0' && echo "✅ 推送成功" || { echo "❌ 推送失败"; exit 1; }
