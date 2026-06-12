# 内科护理学正高每日练习 · 自动推送

每天定时生成一份交互答题网页，发布到 GitHub Pages，并把作答链接推送到飞书群。

## 目录结构
```
neike-quiz/
├── docs/                 # GitHub Pages 发布目录(Pages 设置为 main 分支 /docs)
│   ├── index.html        # 落地页, 自动跳转到最新一期
│   └── YYYY-MM-DD.html   # 每天一份, 独立可作答评分
├── TEMPLATE.html         # 可复用模板, 每天替换 4 处占位符生成当天页面
├── scripts/
│   └── push_feishu.sh    # 推送链接到飞书群机器人
└── README.md
```

## 占位符(TEMPLATE.html → 当天页面)
| 占位符 | 替换为 |
|---|---|
| `{{DATE}}` | 当天日期, 如 `2026-06-12`(出现两处) |
| `{{TOPIC}}` | 今日主题, 如 `消化系统——肝硬化并发症` |
| `{{CASE_DESC_HTML}}` | 案例描述的内层 HTML(患者信息/查体/检查) |
| `{{QS_JSON}}` | 5 题的 JS 数组(结构见下) |

Qs 数组每题字段: `id`(1~5), `type`(`multi`多选/`case`案例不定项), `num`, `title`, `opts`(A~E, 含 `k`和`t`), `correct`(正确选项数组), `expl`(解析)。
固定结构: 第1~2题 `multi`, 第3~5题 `case`。

## 每日运行流程(定时任务自动执行)
1. 生成当天 5 题内容(主题轮换, 避免与近期重复)。
2. 读 `TEMPLATE.html`, 替换 4 处占位符 → 写 `docs/YYYY-MM-DD.html`。
3. 更新 `docs/index.html` 的跳转目标为当天文件。
4. `git add -A && git commit && git push` → GitHub Pages 自动发布。
5. 运行 `scripts/push_feishu.sh <当天URL> <主题>` 推送到飞书。

## 飞书推送配置(环境变量)
```bash
export FEISHU_WEBHOOK="https://open.feishu.cn/open-apis/bot/v2/hook/xxxx"
# 安全设置二选一:
export FEISHU_KEYWORD="每日练习"   # 自定义关键词模式
export FEISHU_SECRET="xxxxxxxx"    # 签名校验模式
```

## 一次性初始化(需 GitHub 账号)
```bash
gh auth login                                   # 浏览器登录 GitHub
gh repo create neike-quiz --public --source=. --remote=origin --push
gh api repos/{owner}/neike-quiz/pages -X POST \
  -f source[branch]=main -f source[path]=/docs  # 开启 Pages
```
发布后链接形如: `https://<用户名>.github.io/neike-quiz/2026-06-12.html`
