import json

with open('tools/batches/input_batch_19.json', encoding='utf-8') as f:
    items = json.load(f)

for idx, item in enumerate(items):
    print(f"=== #{idx+1} (idx {item.get('ranked_idx')}) [{item.get('sample')}] ===")
    print(f"EN: {repr(item['en'])}")
    print(f"CURR_PT: {repr(item.get('curr_pt', ''))}")
