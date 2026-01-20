import os
import yaml
from datetime import datetime
from jinja2 import Template

CHARTS_DIR = "charts"
TEMPLATE_PATH = ".pre-commit/templates/root-readme.md.j2"
OUTPUT_PATH = "README.md"

def get_charts_data():
    charts = []
    if not os.path.exists(CHARTS_DIR):
        return charts

    for chart_name in sorted(os.listdir(CHARTS_DIR)):
        chart_path = os.path.join(CHARTS_DIR, chart_name)
        yaml_path = os.path.join(chart_path, "Chart.yaml")

        if os.path.isdir(chart_path) and os.path.exists(yaml_path):
            with open(yaml_path, 'r') as f:
                data = yaml.safe_load(f)
                charts.append({
                    "name": data.get("name"),
                    "dir_name": chart_name,
                    "version": data.get("version"),
                    "appVersion": data.get("appVersion", "n/a"),
                    "description": data.get("description", "")
                })
    return charts

def render():
    charts = get_charts_data()

    with open(TEMPLATE_PATH, 'r') as f:
        template_content = f.read()

    template = Template(template_content)
    rendered = template.render(
        charts=charts,
        template_path=TEMPLATE_PATH
    )

    with open(OUTPUT_PATH, 'w') as f:
        f.write(rendered)
    print(f"Successfully generated {OUTPUT_PATH}")

if __name__ == "__main__":
    render()
