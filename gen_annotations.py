import os
import json
from pathlib import Path
import pandas as pd

def process_json(json_path):
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    objects = data.get("objects", [])
    f1 = len(objects)

    # примеры дополнительных фич (замени под свою задачу)
    f2 = sum(obj.get("score", 0) for obj in objects)
    f3 = len([obj for obj in objects if obj.get("type") == "A"])
    f4 = len([obj for obj in objects if obj.get("type") == "B"])
    f5 = max([obj.get("score", 0) for obj in objects], default=0)
    f6 = min([obj.get("score", 0) for obj in objects], default=0)

    # извлекаем idx из имени файла
    stem = json_path.stem  # template_3
    idx = stem.split("_")[-1]

    # путь до картинки
    image_path = json_path.parent / "images" / f"template_{idx}.jpg"

    return {
        "path": str(image_path),
        "f1": f1,
        "f2": f2,
        "f3": f3,
        "f4": f4,
        "f5": f5,
        "f6": f6,
    }


def build_dataframe(root_dir):
    root = Path(root_dir)

    # ищем все json
    json_files = list(root.rglob("*.json"))

    rows = []
    for json_file in json_files:
        try:
            row = process_json(json_file)
            rows.append(row)
        except Exception as e:
            print(f"Ошибка в {json_file}: {e}")

    df = pd.DataFrame(rows)
    return df


if __name__ == "__main__":
    df = build_dataframe("/path/to/root")
    print(df.head())

    # сохранить
    df.to_csv("result.csv", index=False)