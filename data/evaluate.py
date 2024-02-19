from openai import OpenAI

client = OpenAI(api_key="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")


# def gen_message(query):
#     # Generate a chat completion based on the prompt
#     response = client.chat.completions.create(
#         model="gpt-3.5-turbo",
#         messages=[
#             {"role": "system", "content": "You are a helpful assistant."},
#             {"role": "user", "content": query},
#         ],
#     )
#     return response.choices[0].message.content


# # Define the prompt for the chat completion
# prompt = "Hi, how are you today?"

# res = gen_message(prompt)
# print(res)

import csv
import json
import ast
import re


def parse_list_of_list_string(s):
    s = s[1:-1]
    s = s.split("],")
    s = [x[1:-1].split(", ") for x in s]
    return s


def parse_list_string(s):
    s = s[1:-1]
    s = s.split(", ")
    return s


def get_score():
    # Open the CSV file
    num_rows = 0

    with open("labeledData.csv", "r") as file:
        # Create a CSV reader object
        csv_reader = csv.reader(file)

        all_s = []
        # Iterate over each row in the CSV file
        for row in csv_reader:
            num_rows += 1
            # Process each row here
            (
                idx,
                logprob,
                exp,
                actual,
                actual_utils,
                pred_utils,
                actual_keys,
                pred_keys,
            ) = row
            s = 0.0
            if not actual_keys:
                continue
            actual_keys = parse_list_of_list_string(actual_keys)
            pred_keys = parse_list_of_list_string(pred_keys)
            actual_utils = parse_list_string(actual_utils)
            pred_utils = parse_list_string(pred_utils)
            T = max(len(actual_utils), len(pred_utils))
            for i in range(max(len(actual_utils), len(pred_utils))):
                if i >= len(actual_utils):
                    s -= 1 / T
                    continue
                if i >= len(pred_utils):
                    s -= 1 / T
                    continue
                if actual_utils[i] != pred_utils[i]:
                    s -= 1 / T
                    continue
                N = max(len(actual_keys[i]), len(pred_keys[i]))
                Sf = (
                    1
                    / N
                    * (
                        2 * len(set(actual_keys[i]).intersection(set(pred_keys[i])))
                        - len(set(actual_keys[i]).union(set(pred_keys[i])))
                    )
                )
                s += 1 / T * Sf
            all_s.append(s)
        mx = max(all_s)
        print(all_s)
        if mx > 0:
            return mx
        else:
            return 1 / num_rows * sum(all_s)


print(get_score())
# print(parse_list_of_list_string("[[type, name, prune, mtime, print]]"))
