#!/usr/bin/env python3
"""
团队能力包 → 可视化知识地图生成器
读取指定能力包目录下的 YAML/MD 文件，输出单页 HTML 到该目录的 viz/ 下。

用法：
  python generate_knowledge_map.py <能力包绝对路径>
  python generate_knowledge_map.py   # 无参数时提示用法

示例：
  python generate_knowledge_map.py D:\\xxx\\.kiro\\extensions\\manufacturing
"""

import os
import sys
import json
import re
from pathlib import Path

try:
    import yaml
except ImportError:
    print("需要 PyYAML：pip install pyyaml")
    sys.exit(1)

# ─── 路径配置 ───
if len(sys.argv) >= 2:
    EXT_DIR = Path(sys.argv[1])
else:
    # 默认：从脚本位置推导（兼容旧用法）
    EXT_DIR = Path(__file__).parent.parent.parent / "extensions" / "manufacturing"

if not EXT_DIR.exists():
    print(f"❌ 能力包目录不存在: {EXT_DIR}")
    print(f"用法: python {Path(__file__).name} <能力包绝对路径>")
    sys.exit(1)

OUTPUT_DIR = EXT_DIR / "viz"
OUTPUT_DIR.mkdir(exist_ok=True)
OUTPUT_FILE = OUTPUT_DIR / "knowledge-map.html"


def load_yaml(filepath):
    """安全加载 YAML 文件"""
    with open(filepath, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_md_content(filepath):
    """读取 markdown 文件全文"""
    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()


# ─── 数据加载 ───
def load_metrics():
    index_file = EXT_DIR / "metrics" / "_index.yaml"
    if not index_file.exists():
        return []
    data = load_yaml(index_file)
    return data.get("metrics_index", [])


def load_catalog():
    cat_file = EXT_DIR / "catalog.yaml"
    if not cat_file.exists():
        return []
    data = load_yaml(cat_file)
    return data.get("tables", [])


def load_dimensions():
    dim_file = EXT_DIR / "dimensions.yaml"
    if not dim_file.exists():
        return []
    data = load_yaml(dim_file)
    return data.get("dimensions", [])


def load_aggregation_rules():
    agg_file = EXT_DIR / "aggregation-rules.yaml"
    if not agg_file.exists():
        return []
    data = load_yaml(agg_file)
    return data.get("non_additive", [])


def load_source_systems():
    src_file = EXT_DIR / "source-systems.yaml"
    if not src_file.exists():
        return {"systems": [], "关联关系": []}
    return load_yaml(src_file)


def load_word_roots():
    wr_file = EXT_DIR / "word-roots.yaml"
    if not wr_file.exists():
        return []
    data = load_yaml(wr_file)
    return data.get("word_roots", [])


def load_vocabulary():
    vocab_file = EXT_DIR / "vocabulary.yaml"
    if not vocab_file.exists():
        return []
    data = load_yaml(vocab_file)
    return data.get("vocabulary", [])


def load_business_rules():
    rules_dir = EXT_DIR / "business-rules"
    all_rules = []
    if not rules_dir.exists():
        return all_rules
    for f in rules_dir.glob("*.yaml"):
        try:
            data = load_yaml(f)
            if data and "rules" in data:
                for r in data["rules"]:
                    r["_file"] = f.name
                    all_rules.append(r)
        except Exception as e:
            print(f"  ⚠️ 跳过 {f.name}（YAML 解析错误: {e}）")
    return all_rules


def load_cases():
    cases_dir = EXT_DIR / "cases"
    cases = []
    if not cases_dir.exists():
        return cases
    for f in cases_dir.glob("*.yaml"):
        if f.name.startswith("_"):
            continue
        try:
            data = load_yaml(f)
            if data:
                cases.append(data)
        except Exception as e:
            print(f"  ⚠️ 跳过 {f.name}（YAML 解析错误: {e}）")
    return cases


def load_patterns():
    pat_dir = EXT_DIR / "patterns"
    patterns = []
    if not pat_dir.exists():
        return patterns
    for f in pat_dir.glob("*.md"):
        content = load_md_content(f)
        # 提取标题行
        title = f.stem
        for line in content.split("\n"):
            if line.startswith("# "):
                title = line[2:].strip()
                break
        patterns.append({"name": f.stem, "title": title, "content_preview": content[:300]})
    return patterns


def load_gates():
    gates_file = EXT_DIR / "gates" / "extra-checks.md"
    if not gates_file.exists():
        return []
    content = load_md_content(gates_file)
    checks = []
    current_group = ""
    for line in content.split("\n"):
        if line.startswith("## "):
            current_group = line[3:].strip()
        elif line.strip().startswith("- ["):
            item = line.strip()[5:].strip()  # remove "- [ ] "
            checks.append({"group": current_group, "item": item})
    return checks


def load_extension_json():
    ext_file = EXT_DIR / "extension.json"
    if not ext_file.exists():
        return {}
    with open(ext_file, "r", encoding="utf-8") as f:
        return json.load(f)


# ─── 数据组装 ───
def build_data():
    metrics = load_metrics()
    catalog = load_catalog()
    dimensions = load_dimensions()
    agg_rules = load_aggregation_rules()
    source_sys = load_source_systems()
    word_roots = load_word_roots()
    vocabulary = load_vocabulary()
    business_rules = load_business_rules()
    cases = load_cases()
    patterns = load_patterns()
    gates = load_gates()
    ext_json = load_extension_json()

    # 指标图谱
    metric_nodes = []
    metric_links = []
    for m in metrics:
        metric_nodes.append({
            "name": m.get("name", ""),
            "type": m.get("type", ""),
            "field": m.get("field", ""),
            "table": m.get("table", ""),
            "domain": m.get("domain", ""),
        })

    for domain_file in (EXT_DIR / "metrics").glob("*.yaml"):
        if domain_file.name.startswith("_"):
            continue
        data = load_yaml(domain_file)
        for m in data.get("metrics", []):
            if "derives_from" in m:
                for dep in m["derives_from"]:
                    metric_links.append({"source": dep, "target": m["name"]})

    # 表血缘 DAG
    table_nodes = []
    for t in catalog:
        table_nodes.append({
            "name": t["name"],
            "layer": t["layer"],
            "granularity": t.get("granularity", ""),
            "notes": t.get("notes", ""),
        })

    catalog_names = {t["name"] for t in catalog}
    ods_tables = []
    for sys_info in source_sys.get("systems", []):
        for tbl in sys_info.get("tables", []):
            if tbl["name"] not in catalog_names:
                ods_tables.append({
                    "name": tbl["name"],
                    "layer": "ODS",
                    "granularity": "",
                    "notes": tbl.get("用途", ""),
                })

    table_links = []
    for t in catalog:
        for dep in t.get("depends_on", []):
            table_links.append({"source": dep, "target": t["name"]})

    # 源系统展示数据
    source_display = []
    for sys_info in source_sys.get("systems", []):
        sys_entry = {
            "id": sys_info.get("id", ""),
            "name": sys_info.get("name", ""),
            "入湖就绪": sys_info.get("入湖就绪", ""),
            "入湖方式": sys_info.get("入湖方式", ""),
            "tables": [],
        }
        for tbl in sys_info.get("tables", []):
            pitfalls = tbl.get("坑", [])
            if isinstance(pitfalls, list):
                pitfalls = pitfalls
            else:
                pitfalls = [str(pitfalls)]
            sys_entry["tables"].append({
                "name": tbl.get("name", ""),
                "用途": tbl.get("用途", ""),
                "坑": pitfalls,
            })
        source_display.append(sys_entry)

    # 覆盖度
    coverage = {
        "metrics": len(metrics),
        "metrics_basic": len([m for m in metrics if m.get("type") == "基础度量"]),
        "metrics_derived": len([m for m in metrics if m.get("type") == "派生度量"]),
        "metrics_composite": len([m for m in metrics if m.get("type") == "复合指标"]),
        "vocabulary": len(vocabulary),
        "word_roots": len(word_roots),
        "dimensions": len(dimensions),
        "catalog_tables": len(catalog),
        "source_systems": len(source_sys.get("systems", [])),
        "source_tables": sum(len(s.get("tables", [])) for s in source_sys.get("systems", [])),
        "cases": len(cases),
        "patterns": len(patterns),
        "aggregation_rules": len(agg_rules),
        "business_rules": len(business_rules),
        "gates": len(gates),
    }

    # 维度
    dim_matrix = []
    for d in dimensions:
        dim_matrix.append({
            "name": d.get("name", ""),
            "dim_table": d.get("dim_table", ""),
            "key": d.get("key", []),
            "notes": "; ".join(d.get("usage_notes", [])),
        })

    return {
        "ext_info": ext_json,
        "metric_nodes": metric_nodes,
        "metric_links": metric_links,
        "table_nodes": table_nodes + ods_tables,
        "table_links": table_links,
        "coverage": coverage,
        "dimensions": dim_matrix,
        "agg_rules": agg_rules,
        "word_roots": word_roots,
        "vocabulary": vocabulary,
        "source_systems": source_display,
        "business_rules": business_rules,
        "cases": cases,
        "patterns": patterns,
        "gates": gates,
    }


# ─── HTML 生成 ───
def generate_html(data):
    data_json = json.dumps(data, ensure_ascii=False, indent=2)

    html = f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{data['ext_info'].get('display_name', '团队能力包')} - 知识地图</title>
<script src="https://cdn.jsdelivr.net/npm/echarts@5.4.3/dist/echarts.min.js"></script>
<style>
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0f1419; color: #e7e9ea; }}
.header {{ padding: 20px 30px; background: #1a2332; border-bottom: 1px solid #2f3942; display: flex; justify-content: space-between; align-items: center; }}
.header h1 {{ font-size: 22px; font-weight: 600; }}
.header .meta {{ font-size: 13px; color: #8899a6; }}
.tabs {{ display: flex; gap: 0; background: #1a2332; padding: 0 30px; border-bottom: 1px solid #2f3942; overflow-x: auto; }}
.tab {{ padding: 12px 16px; cursor: pointer; font-size: 13px; color: #8899a6; border-bottom: 2px solid transparent; transition: all 0.2s; white-space: nowrap; }}
.tab:hover {{ color: #e7e9ea; }}
.tab.active {{ color: #1d9bf0; border-bottom-color: #1d9bf0; }}
.panel {{ display: none; padding: 20px 30px; min-height: calc(100vh - 130px); }}
.panel.active {{ display: block; }}
.chart-container {{ width: 100%; height: 500px; background: #192734; border-radius: 12px; margin-bottom: 20px; }}
.chart-container.large {{ height: 600px; }}
.stats-grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 14px; margin-bottom: 24px; }}
.stat-card {{ background: #192734; border-radius: 10px; padding: 14px; text-align: center; }}
.stat-card .number {{ font-size: 26px; font-weight: 700; color: #1d9bf0; }}
.stat-card .label {{ font-size: 11px; color: #8899a6; margin-top: 4px; }}
.table-wrap {{ overflow-x: auto; margin-bottom: 20px; }}
table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
th {{ background: #192734; padding: 10px 12px; text-align: left; color: #8899a6; font-weight: 500; position: sticky; top: 0; }}
td {{ padding: 8px 12px; border-bottom: 1px solid #2f3942; vertical-align: top; }}
tr:hover td {{ background: #192734; }}
.badge {{ display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: 500; }}
.badge-basic {{ background: #1d3a5c; color: #5ab3f0; }}
.badge-derived {{ background: #2d4a1c; color: #7cc832; }}
.badge-composite {{ background: #4a2d1c; color: #f0943a; }}
.badge-block {{ background: #4a1c1c; color: #f05a5a; }}
.badge-warn {{ background: #4a3a1c; color: #f0c43a; }}
.badge-info {{ background: #1c3a4a; color: #5ac8f0; }}
.badge-ods {{ background: #2d2d2d; color: #9ca3af; }}
.section-title {{ font-size: 16px; font-weight: 600; margin: 20px 0 12px; padding-left: 10px; border-left: 3px solid #1d9bf0; }}
.pitfall {{ background: #1a1a2e; border-left: 3px solid #f59e0b; padding: 6px 10px; margin: 4px 0; border-radius: 4px; font-size: 12px; }}
.card {{ background: #192734; border-radius: 10px; padding: 16px; margin-bottom: 16px; }}
.card h3 {{ font-size: 14px; margin-bottom: 8px; color: #e7e9ea; }}
.card p {{ font-size: 12px; color: #8899a6; margin: 4px 0; }}
.tag {{ display: inline-block; padding: 1px 6px; border-radius: 3px; font-size: 10px; background: #2d3748; color: #a0aec0; margin-right: 4px; }}
</style>
</head>
<body>

<div class="header">
    <h1>📊 {data['ext_info'].get('display_name', '团队能力包')} — 知识地图</h1>
    <div class="meta">v{data['ext_info'].get('version', '?')} | 更新于 {data['ext_info'].get('last_updated', '?')}</div>
</div>

<div class="tabs">
    <div class="tab active" onclick="switchTab('overview')">总览</div>
    <div class="tab" onclick="switchTab('metrics')">指标图谱</div>
    <div class="tab" onclick="switchTab('lineage')">表血缘</div>
    <div class="tab" onclick="switchTab('dimensions')">维度</div>
    <div class="tab" onclick="switchTab('rules')">聚合规则</div>
    <div class="tab" onclick="switchTab('vocabulary')">术语表</div>
    <div class="tab" onclick="switchTab('wordroots')">词根</div>
    <div class="tab" onclick="switchTab('sources')">源系统</div>
    <div class="tab" onclick="switchTab('bizrules')">业务规则</div>
    <div class="tab" onclick="switchTab('cases')">案例库</div>
    <div class="tab" onclick="switchTab('standards')">规范保障</div>
</div>

<!-- ═══ 总览 ═══ -->
<div id="panel-overview" class="panel active">
    <div class="stats-grid">
        <div class="stat-card"><div class="number">{data['coverage']['metrics']}</div><div class="label">指标/度量</div></div>
        <div class="stat-card"><div class="number">{data['coverage']['catalog_tables']}</div><div class="label">已建表</div></div>
        <div class="stat-card"><div class="number">{data['coverage']['dimensions']}</div><div class="label">维度</div></div>
        <div class="stat-card"><div class="number">{data['coverage']['vocabulary']}</div><div class="label">术语</div></div>
        <div class="stat-card"><div class="number">{data['coverage']['word_roots']}</div><div class="label">词根</div></div>
        <div class="stat-card"><div class="number">{data['coverage']['source_tables']}</div><div class="label">源表</div></div>
        <div class="stat-card"><div class="number">{data['coverage']['business_rules']}</div><div class="label">业务规则</div></div>
        <div class="stat-card"><div class="number">{data['coverage']['cases']}</div><div class="label">案例</div></div>
        <div class="stat-card"><div class="number">{data['coverage']['patterns']}</div><div class="label">设计模式</div></div>
        <div class="stat-card"><div class="number">{data['coverage']['gates']}</div><div class="label">闸门检查项</div></div>
    </div>
    <div class="chart-container" id="chart-coverage"></div>
</div>

<!-- ═══ 指标图谱 ═══ -->
<div id="panel-metrics" class="panel">
    <div class="section-title">指标层次关系图</div>
    <div class="chart-container large" id="chart-metrics"></div>
    <div class="section-title">指标清单</div>
    <div class="table-wrap"><table>
        <thead><tr><th>指标名</th><th>类型</th><th>字段</th><th>所在表</th><th>域</th></tr></thead>
        <tbody id="metrics-table"></tbody>
    </table></div>
</div>

<!-- ═══ 表血缘 ═══ -->
<div id="panel-lineage" class="panel">
    <div class="section-title">表血缘 DAG（ODS → DWD → DWS → ADS）</div>
    <div class="chart-container large" id="chart-lineage"></div>
    <div class="section-title">表目录</div>
    <div class="table-wrap"><table>
        <thead><tr><th>表名</th><th>层次</th><th>粒度</th><th>备注</th></tr></thead>
        <tbody id="catalog-table"></tbody>
    </table></div>
</div>

<!-- ═══ 维度 ═══ -->
<div id="panel-dimensions" class="panel">
    <div class="section-title">维度知识</div>
    <div class="table-wrap"><table>
        <thead><tr><th>维度</th><th>维表</th><th>主键</th><th>使用经验</th></tr></thead>
        <tbody id="dim-table"></tbody>
    </table></div>
</div>

<!-- ═══ 聚合规则 ═══ -->
<div id="panel-rules" class="panel">
    <div class="section-title">不可加型指标（必须回到分子分母重算）</div>
    <div class="table-wrap"><table>
        <thead><tr><th>字段</th><th>分子</th><th>分母</th><th>所在表</th><th>备注</th></tr></thead>
        <tbody id="agg-table"></tbody>
    </table></div>
    <div class="section-title">反模式红线</div>
    <div class="table-wrap"><table>
        <thead><tr><th>级别</th><th>检测模式</th><th>修复方式</th></tr></thead>
        <tbody>
            <tr><td><span class="badge badge-block">阻塞</span></td><td>AVG(xxx_rate)</td><td>SUM(分子)/NULLIF(SUM(分母),0)</td></tr>
            <tr><td><span class="badge badge-block">阻塞</span></td><td>SUM(xxx_rate)</td><td>SUM(分子)/NULLIF(SUM(分母),0)</td></tr>
            <tr><td><span class="badge badge-block">阻塞</span></td><td>不同粒度表 JOIN 后直接 SUM</td><td>先 GROUP BY 到相同粒度再 JOIN</td></tr>
            <tr><td><span class="badge badge-warn">警告</span></td><td>ADS 只存 rate 无分子分母</td><td>同时保留分子、分母、比率</td></tr>
            <tr><td><span class="badge badge-warn">警告</span></td><td>WHERE rate>N 后再聚合</td><td>先聚合再过滤</td></tr>
        </tbody>
    </table></div>
</div>

<!-- ═══ 术语表 ═══ -->
<div id="panel-vocabulary" class="panel">
    <div class="section-title">业务概念词表</div>
    <div class="table-wrap"><table>
        <thead><tr><th>业务用语</th><th>标准定义</th><th>易混淆项</th><th>关联指标</th></tr></thead>
        <tbody id="vocab-table"></tbody>
    </table></div>
</div>

<!-- ═══ 词根 ═══ -->
<div id="panel-wordroots" class="panel">
    <div class="section-title">字段命名词根速查</div>
    <div class="table-wrap"><table>
        <thead><tr><th>分类</th><th>缩写</th><th>英文全称</th><th>数据类型</th><th>状态</th></tr></thead>
        <tbody id="wr-table"></tbody>
    </table></div>
</div>

<!-- ═══ 源系统 ═══ -->
<div id="panel-sources" class="panel">
    <div class="section-title">源系统经验缓存</div>
    <div id="source-cards"></div>
</div>

<!-- ═══ 业务规则 ═══ -->
<div id="panel-bizrules" class="panel">
    <div class="section-title">业务规则</div>
    <div id="bizrule-cards"></div>
</div>

<!-- ═══ 案例库 ═══ -->
<div id="panel-cases" class="panel">
    <div class="section-title">项目案例库</div>
    <div id="case-cards"></div>
</div>

<!-- ═══ 规范保障 ═══ -->
<div id="panel-standards" class="panel">
    <div class="section-title">设计模式</div>
    <div id="pattern-cards"></div>
    <div class="section-title">闸门额外检查项</div>
    <div class="table-wrap"><table>
        <thead><tr><th>分组</th><th>检查项</th></tr></thead>
        <tbody id="gates-table"></tbody>
    </table></div>
</div>

<script>
const DATA = {data_json};

function switchTab(name) {{
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
    event.target.classList.add('active');
    document.getElementById('panel-' + name).classList.add('active');
    setTimeout(() => window.dispatchEvent(new Event('resize')), 100);
}}

// ─── 覆盖度雷达图 ───
function renderCoverage() {{
    const chart = echarts.init(document.getElementById('chart-coverage'));
    const c = DATA.coverage;
    chart.setOption({{
        backgroundColor: 'transparent',
        radar: {{
            indicator: [
                {{ name: '指标', max: 20 }}, {{ name: '表', max: 15 }}, {{ name: '维度', max: 10 }},
                {{ name: '术语', max: 20 }}, {{ name: '词根', max: 20 }}, {{ name: '源表', max: 10 }},
                {{ name: '规则', max: 10 }}, {{ name: '案例', max: 5 }}, {{ name: '模式', max: 5 }},
            ],
            axisName: {{ color: '#8899a6' }},
            splitArea: {{ areaStyle: {{ color: ['#192734', '#1a2d3d'] }} }},
            axisLine: {{ lineStyle: {{ color: '#2f3942' }} }},
            splitLine: {{ lineStyle: {{ color: '#2f3942' }} }},
        }},
        series: [{{ type: 'radar', data: [{{
            value: [c.metrics, c.catalog_tables, c.dimensions, c.vocabulary, c.word_roots, c.source_tables, c.business_rules, c.cases, c.patterns],
            name: '当前覆盖', areaStyle: {{ color: 'rgba(29,155,240,0.2)' }}, lineStyle: {{ color: '#1d9bf0' }}, itemStyle: {{ color: '#1d9bf0' }},
        }}] }}]
    }});
    window.addEventListener('resize', () => chart.resize());
}}

// ─── 指标图谱 ───
function renderMetrics() {{
    const chart = echarts.init(document.getElementById('chart-metrics'));
    const typeColor = {{ '基础度量': '#5ab3f0', '派生度量': '#7cc832', '复合指标': '#f0943a' }};
    const typeSize = {{ '基础度量': 30, '派生度量': 35, '复合指标': 40 }};
    const nodes = DATA.metric_nodes.map(m => ({{ name: m.name, symbolSize: typeSize[m.type]||30, itemStyle: {{ color: typeColor[m.type]||'#888' }}, category: m.type, label: {{ show: true, fontSize: 11 }} }}));
    const links = DATA.metric_links.map(l => ({{ source: l.source, target: l.target, lineStyle: {{ color: '#4a5568', curveness: 0.2 }} }}));
    const categories = ['基础度量', '派生度量', '复合指标'].map(n => ({{ name: n }}));
    chart.setOption({{
        backgroundColor: 'transparent',
        tooltip: {{ trigger: 'item' }},
        legend: {{ data: categories.map(c => c.name), textStyle: {{ color: '#8899a6' }}, top: 10 }},
        series: [{{ type: 'graph', layout: 'force', data: nodes, links: links, categories: categories, roam: true, force: {{ repulsion: 200, edgeLength: [80, 160] }}, label: {{ color: '#e7e9ea' }}, emphasis: {{ focus: 'adjacency' }} }}]
    }});
    window.addEventListener('resize', () => chart.resize());
    const tbody = document.getElementById('metrics-table');
    DATA.metric_nodes.forEach(m => {{
        const bc = m.type==='基础度量'?'badge-basic':m.type==='派生度量'?'badge-derived':'badge-composite';
        tbody.innerHTML += `<tr><td>${{m.name}}</td><td><span class="badge ${{bc}}">${{m.type}}</span></td><td><code>${{m.field}}</code></td><td>${{m.table}}</td><td>${{m.domain}}</td></tr>`;
    }});
}}

// ─── 表血缘 DAG ───
function renderLineage() {{
    const chart = echarts.init(document.getElementById('chart-lineage'));
    const layerX = {{ 'ODS': 80, 'DIM': 80, 'DWD': 320, 'DWS': 560, 'ADS': 800 }};
    const layerColor = {{ 'ODS': '#6b7280', 'DIM': '#8b5cf6', 'DWD': '#3b82f6', 'DWS': '#10b981', 'ADS': '#f59e0b' }};
    const layerCount = {{}};
    const nodes = DATA.table_nodes.map(t => {{
        const layer = t.layer;
        layerCount[layer] = (layerCount[layer] || 0) + 1;
        return {{ name: t.name, x: layerX[layer]||500, y: layerCount[layer]*65, itemStyle: {{ color: layerColor[layer]||'#888' }}, symbolSize: 18, label: {{ show: true, position: 'right', fontSize: 10, color: '#c0c8d0' }} }};
    }});
    const links = DATA.table_links.map(l => ({{ source: l.source, target: l.target, lineStyle: {{ color: '#4a5568', width: 1.5 }} }}));
    chart.setOption({{
        backgroundColor: 'transparent',
        tooltip: {{ trigger: 'item', formatter: p => p.data ? `<b>${{p.data.name}}</b>` : '' }},
        series: [{{ type: 'graph', layout: 'none', data: nodes, links: links, roam: true, lineStyle: {{ curveness: 0.1 }}, emphasis: {{ focus: 'adjacency' }}, edgeSymbol: ['none', 'arrow'], edgeSymbolSize: 8 }}]
    }});
    window.addEventListener('resize', () => chart.resize());
    const tbody = document.getElementById('catalog-table');
    DATA.table_nodes.forEach(t => {{ tbody.innerHTML += `<tr><td><code>${{t.name}}</code></td><td><span class="badge badge-info">${{t.layer}}</span></td><td>${{t.granularity}}</td><td>${{t.notes}}</td></tr>`; }});
}}

// ─── 维度 ───
function renderDimensions() {{
    const tbody = document.getElementById('dim-table');
    DATA.dimensions.forEach(d => {{ tbody.innerHTML += `<tr><td><b>${{d.name}}</b></td><td><code>${{d.dim_table}}</code></td><td>${{(d.key||[]).join(', ')}}</td><td>${{d.notes}}</td></tr>`; }});
}}

// ─── 聚合规则 ───
function renderAggRules() {{
    const tbody = document.getElementById('agg-table');
    DATA.agg_rules.forEach(r => {{ tbody.innerHTML += `<tr><td><code>${{r.field}}</code></td><td>${{r.numerator}}</td><td>${{r.denominator}}</td><td><code>${{r.table}}</code></td><td>${{r.note||'-'}}</td></tr>`; }});
}}

// ─── 术语表 ───
function renderVocabulary() {{
    const tbody = document.getElementById('vocab-table');
    DATA.vocabulary.forEach(v => {{
        const confused = (v.confused_with||[]).join(', ');
        const related = (v.related_metrics||[]).join(', ') || '-';
        tbody.innerHTML += `<tr><td><b>${{v.term}}</b></td><td>${{v.definition}}</td><td>${{confused}}</td><td>${{related}}</td></tr>`;
    }});
}}

// ─── 词根 ───
function renderWordRoots() {{
    const tbody = document.getElementById('wr-table');
    DATA.word_roots.forEach(w => {{
        tbody.innerHTML += `<tr><td>${{w.category}}</td><td><code>${{w.abbr}}</code></td><td>${{w.full_name}}</td><td><span class="badge badge-info">${{w.data_type}}</span></td><td>${{w.status}}</td></tr>`;
    }});
}}

// ─── 源系统 ───
function renderSources() {{
    const container = document.getElementById('source-cards');
    DATA.source_systems.forEach(sys => {{
        let tablesHtml = '';
        sys.tables.forEach(t => {{
            let pits = t['坑'].map(p => `<div class="pitfall">⚠️ ${{p}}</div>`).join('');
            tablesHtml += `<div style="margin:8px 0;padding:8px;background:#0f1419;border-radius:6px;">
                <div><code>${{t.name}}</code> — ${{t['用途']}}</div>${{pits}}</div>`;
        }});
        container.innerHTML += `<div class="card">
            <h3>📦 ${{sys.name}}</h3>
            <p>入湖就绪: ${{sys['入湖就绪']}} | 方式: ${{sys['入湖方式']}}</p>
            ${{tablesHtml}}
        </div>`;
    }});
}}

// ─── 业务规则 ───
function renderBizRules() {{
    const container = document.getElementById('bizrule-cards');
    DATA.business_rules.forEach(r => {{
        let desc = r.description || r['判定逻辑'] || '';
        let pending = r['待确认'] ? `<div class="pitfall">❓ 待确认: ${{r['待确认']}}</div>` : '';
        container.innerHTML += `<div class="card">
            <h3>${{r.name || r.id}}</h3>
            <p style="color:#8899a6;font-size:11px;">域: ${{r.domain || '-'}} | 实体: ${{r.entity || '-'}} | 字段: ${{r.field || '-'}}</p>
            <p style="white-space:pre-wrap;font-size:12px;margin-top:8px;">${{desc}}</p>
            ${{pending}}
        </div>`;
    }});
}}

// ─── 案例库 ───
function renderCases() {{
    const container = document.getElementById('case-cards');
    DATA.cases.forEach(c => {{
        let decisions = '';
        if (c.decisions) {{
            c.decisions.forEach(d => {{
                decisions += `<div style="margin:4px 0;font-size:12px;">• <b>${{d.question}}</b>: ${{d.decision}}</div>`;
            }});
        }}
        let pitfalls = '';
        if (c.pitfalls) {{
            c.pitfalls.forEach(p => {{
                pitfalls += `<div class="pitfall">🕳️ ${{p.issue}}: ${{p.solution}}</div>`;
            }});
        }}
        let tables = (c.output_tables||[]).map(t => `<span class="tag">${{t}}</span>`).join('');
        container.innerHTML += `<div class="card">
            <h3>📋 ${{c.name || c.project_id}}</h3>
            <p style="color:#8899a6;font-size:11px;">时间: ${{c.time||'-'}} | Owner: ${{c.owner||'-'}}</p>
            ${{decisions ? '<div class="section-title" style="font-size:13px;margin:10px 0 6px;">关键决策</div>' + decisions : ''}}
            ${{pitfalls ? '<div class="section-title" style="font-size:13px;margin:10px 0 6px;">踩坑记录</div>' + pitfalls : ''}}
            ${{tables ? '<div style="margin-top:10px;">产出表: ' + tables + '</div>' : ''}}
        </div>`;
    }});
    if (DATA.cases.length === 0) {{
        container.innerHTML = '<p style="color:#8899a6;">暂无案例</p>';
    }}
}}

// ─── 规范保障（模式 + 闸门） ───
function renderStandards() {{
    const patContainer = document.getElementById('pattern-cards');
    DATA.patterns.forEach(p => {{
        patContainer.innerHTML += `<div class="card"><h3>🧩 ${{p.title}}</h3><p style="font-size:12px;color:#8899a6;white-space:pre-wrap;">${{p.content_preview}}...</p></div>`;
    }});
    if (DATA.patterns.length === 0) {{
        patContainer.innerHTML = '<p style="color:#8899a6;">暂无设计模式</p>';
    }}
    const gatesTbody = document.getElementById('gates-table');
    DATA.gates.forEach(g => {{
        gatesTbody.innerHTML += `<tr><td><span class="badge badge-info">${{g.group}}</span></td><td>${{g.item}}</td></tr>`;
    }});
    if (DATA.gates.length === 0) {{
        gatesTbody.innerHTML = '<tr><td colspan="2" style="color:#8899a6;">暂无额外检查项</td></tr>';
    }}
}}

// ─── 初始化 ───
renderCoverage();
renderMetrics();
renderLineage();
renderDimensions();
renderAggRules();
renderVocabulary();
renderWordRoots();
renderSources();
renderBizRules();
renderCases();
renderStandards();
</script>
</body>
</html>"""
    return html


# ─── 主流程 ───
def main():
    print(f"📂 扫描能力包目录: {EXT_DIR}")
    data = build_data()
    html = generate_html(data)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"✅ 已生成: {OUTPUT_FILE}")
    print(f"   打开方式: 浏览器直接打开该文件即可")


if __name__ == "__main__":
    main()
