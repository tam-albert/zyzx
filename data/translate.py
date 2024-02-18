import json
import random

with open("all.cm", "r") as file:
    cm_file_content = file.read().splitlines()

with open("all.nl", "r") as file:
    nl_file_content = file.read().splitlines()

assert len(cm_file_content) == len(nl_file_content)

lines = [(nl, cm) for nl, cm in zip(nl_file_content, cm_file_content)]
random.shuffle(lines)

with open("training.jsonl", "w") as output_file:
    for i in range(len(lines))[:-1000]:
        json_line = {
            "input": lines[i][0].strip(),
            "output": lines[i][1].strip(),
        }
        output_file.write(json.dumps(json_line) + "\n")

with open("validation.jsonl", "w") as output_file:
    for i in range(len(lines))[-1000:]:
        json_line = {
            "input": lines[i][0].strip(),
            "output": lines[i][1].strip(),
        }
        output_file.write(json.dumps(json_line) + "\n")
