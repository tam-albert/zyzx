from openai import OpenAI
import json
import tqdm
import random
import csv
import requests

client = OpenAI(api_key="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")
ENDPOINT = "https://17e5469d8a58.ngrok.app"


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


def gen_message_mistral(query):
    body = {"model": "1", "query": query}
    response = requests.post(
        ENDPOINT + f"/generate_many_code",
        headers={"content-type": "application/json"},
        data=json.dumps(body),
    )
    if (
        response.status_code != 200
        or response.headers["Content-Type"] != "application/json"
    ):
        print(f"Error: {response.status_code}")
        return None
    res_json = response.json()
    return res_json["message"]


data = []
with open("/Users/andrew/jsonl/validation.jsonl", "r") as file:
    file_contents = file.read().splitlines()[:]
    for i, test in tqdm.tqdm(enumerate(file_contents), total=len(file_contents)):
        test = json.loads(test)
        responses = gen_message_mistral(test["input"])
        responses = eval(responses)
        for res in responses:
            idx = res.find("[/INST]")
            data.append([i, test["input"], test["output"], res[idx:]])
        print(i)
        if i % 1 == 0:
            csv_file = "data.csv"
            with open(csv_file, "a") as file:
                writer = csv.writer(file)
                writer.writerows(data)
            data = []
