import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open("tools/batches/input_batch_20.json", "r", encoding="utf-8") as f:
    data = json.load(f)

with open("tools/batches/dump_batch_20.txt", "w", encoding="utf-8") as out:
    out.write(f"Total items: {len(data)}\n")
    for i, item in enumerate(data):
        out.write(f"=== ITEM {i+1} / {len(data)} (idx={item.get('ranked_idx')}) ===\n")
        out.write(f"SAMPLE: {item.get('sample')}\n")
        out.write(f"EN:\n{item.get('en')}\n")
        out.write(f"CURR_PT:\n{item.get('curr_pt')}\n\n")
