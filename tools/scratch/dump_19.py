import json

with open('tools/batches/input_batch_19.json', encoding='utf-8') as f:
    items = json.load(f)

for idx, item in enumerate(items):
    print(f"{idx+1}: {item['sample']}")
    print(f"   EN: {item['en']}")
    print(f"   PT_OLD: {item.get('curr_pt', '')}")
