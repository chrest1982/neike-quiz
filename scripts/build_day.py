#!/usr/bin/env python3
# 用当天 JSON 规格 + TEMPLATE.html 生成 docs/<date>[-<slot>].html 并更新 docs/index.html
# 用法: python3 scripts/build_day.py spec.json
# spec.json 字段: date, topic, case_desc_html, questions(数组, 见 README)
#   可选 slot: 同一天多份时的时段后缀(如 "07"/"09"), 文件名为 <date>-<slot>.html, 互不覆盖
import json, sys, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
spec = json.load(open(sys.argv[1], encoding='utf-8'))
tpl = open(os.path.join(ROOT, 'TEMPLATE.html'), encoding='utf-8').read()

slot = str(spec.get('slot', '')).strip()
fname = f"{spec['date']}-{slot}.html" if slot else f"{spec['date']}.html"

qs_json = json.dumps(spec['questions'], ensure_ascii=False, indent=2)
html = (tpl.replace('{{DATE}}', spec['date'])
           .replace('{{TOPIC}}', spec['topic'])
           .replace('{{CASE_DESC_HTML}}', spec['case_desc_html'])
           .replace('{{QS_JSON}}', qs_json))

out = os.path.join(ROOT, 'docs', fname)
open(out, 'w', encoding='utf-8').write(html)

# 更新落地页跳转目标为本次生成的文件(始终指向最新一份)
idx = os.path.join(ROOT, 'docs', 'index.html')
s = open(idx, encoding='utf-8').read()
s = re.sub(r'url=[^"]+\.html', f"url={fname}", s)
s = re.sub(r'location\.replace\("[^"]+\.html"\)', f'location.replace("{fname}")', s)
s = re.sub(r'href="[^"]+\.html"', f'href="{fname}"', s)
open(idx, 'w', encoding='utf-8').write(s)

print(f"已生成 {out}")
print(f"已更新 index.html → {fname}")
