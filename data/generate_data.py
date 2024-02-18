from openai import OpenAI
import json
import tqdm
import random

client = OpenAI(api_key="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")


def gen_message(query):
    # Generate a chat completion based on the prompt
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {
                "role": "system",
                "content": "Your role is to help generate data to train a ML expert on terminal literacy. You will be given a command that was run in MacOS, and your job is to create a short natural language description of the command. For example, if you are given the command `ls`, a possible description could be `list the contents of the current directory`.",
            },
            {"role": "user", "content": query},
        ],
    )
    return response.choices[0].message.content


def gen_new_message(query):
    print("query", query)
    # Generate a chat completion based on the prompt
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {
                "role": "system",
                "content": "Your role is to help generate data to train a ML expert on terminal literacy. Your goal is to generate some high quality, synthetic data for training a model to understand terminal commands. This data should come in the form of a natural language description of a command, and the command itself. For example, a natural language description could be `list the contents of the current directory`, and the corresponding command could be `ls`. To help you with this task, you will be given a list of ten example pairs of commands and their natural language descriptions. You should use these examples to help you generate new, high quality, synthetic data. You should also use your own knowledge of terminal commands to help you generate new examples. You should aim to generate exactly 20 new examples. Please format your list so that each pair of command and natural language description is on a new line, and the command and natural language description are separated by a comma. For example, `list the contents of the current directory, ls`. Once again, please make sure that your 20 examples are high quality and correct!",
            },
            {"role": "user", "content": str(query)},
        ],
    )
    return response.choices[0].message.content


def gen_synthetic_data_from_existing():
    # generate synthetic NL from bash commands compiled from our collective .zsh history
    # these commands were sanitized (see `filterhistory.py`) and then compiled together
    # they have all been looked through, are safe to run, and "high quality"
    with open("all_commands.txt", "r") as file:
        all_commands = file.read().splitlines()
        for i, command in tqdm.tqdm(enumerate(all_commands), total=len(all_commands)):
            res = gen_message(command)
            with open("alldata.jsonl", "a") as output_file:
                json_line = {
                    "input": res.strip(),
                    "output": command.strip(),
                }
                output_file.write(json.dumps(json_line) + "\n")


def gen_synthetic_data(k=int(10000 / 20)):
    # mix together some of the existing data to give to gpt as examples for new, synthetic data
    examples = []
    with open("alldata.jsonl", "r") as file:
        existing_data = file.read().splitlines()
        for data in existing_data:
            single_data = json.loads(data)
            examples.append(single_data["input"] + ", " + single_data["output"])
    with open("training.jsonl", "r") as file:
        existing_data = file.read().splitlines()
        for data in existing_data:
            single_data = json.loads(data)
            examples.append(single_data["input"] + ", " + single_data["output"])

    random.shuffle(examples)
    batched_examples = []
    for i in range(len(examples) // 10):
        batched_examples.append(examples[10 * i : 10 * i + 10])

    for i in tqdm.tqdm(range(k)):
        res = gen_new_message(batched_examples[i])
        pairs = res.split("\n")
        for pair in pairs:
            try:
                pair_list = pair.split(",")
                with open("syntheticdata.jsonl", "a") as output_file:
                    json_line = {
                        "input": pair_list[0].strip(),
                        "output": pair_list[1].strip(),
                    }
                    output_file.write(json.dumps(json_line) + "\n")
            except:
                pass


def combine_data():
    # combine the synthetic data with the existing data
    total_data = []
    with open("syntheticdata.jsonl", "r") as file:
        existing_data = file.read().splitlines()
        for data in existing_data:
            total_data.append(data)
    with open("training.jsonl", "r") as file:
        existing_data = file.read().splitlines()
        for data in existing_data:
            total_data.append(data)
    with open("alldata.jsonl", "r") as file:
        existing_data = file.read().splitlines()
        for data in existing_data:
            total_data.append(data)
    with open("combineddata.jsonl", "w") as file:
        for data in total_data:
            file.write(data + "\n")


combine_data()
