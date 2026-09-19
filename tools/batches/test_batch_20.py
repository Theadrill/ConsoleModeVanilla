import json
import sys
import re

from validate_spell_vars import validate_pair, count_en_vars, count_pt_vars

# Load input batch
with open("tools/batches/input_batch_20.json", "r", encoding="utf-8") as f:
    input_data = json.load(f)

print(f"Total inputs: {len(input_data)}")
