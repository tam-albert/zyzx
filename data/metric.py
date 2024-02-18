from openai import OpenAI
import json
import tqdm
import random
import csv

client = OpenAI(api_key="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")


def gen_message(query):
    # Generate a chat completion based on the prompt
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {
                "role": "system",
                "content": "Give me a bash command that will execute on this natural language query. Please only include the command and no other words. For example, if the query is `list the contents of the current directory`, the command would be `ls`.",
            },
            {"role": "user", "content": query},
        ],
        logprobs=True,
    )
    return response.choices


data = []
with open("validation.jsonl", "r") as file:
    file_contents = file.read().splitlines()[250:]
    for i, test in tqdm.tqdm(enumerate(file_contents), total=len(file_contents)):
        test = json.loads(test)
        responses = gen_message(test["input"])
        for res in responses:
            total_logprob = 0
            for token in res.logprobs.content:
                total_logprob += token.logprob
            data.append([i, total_logprob, test["output"], res.message.content])

        if i % 50 == 0:
            csv_file = "data.csv"
            with open(csv_file, "a") as file:
                writer = csv.writer(file)
                writer.writerows(data)
            data = []
