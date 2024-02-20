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
    s = [x[1:-1].split(",") for x in s]
    for i in range(len(s)):
        for j in range(len(s[i])):
            s[i][j] = s[i][j].strip()
    return s


def parse_list_string(s):
    s = s[1:-1]
    s = s.split(",")
    for i in range(len(s)):
        s[i] = s[i].strip()
    return s


def get_score(filename):
    # Open the CSV file
    num_rows = 0

    all_rows = {}

    with open(filename, "r") as file:
        # Create a CSV reader object
        csv_reader = csv.reader(file)

        all_s = {}
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

            if all_rows.get(idx, None) is None:
                all_rows[idx] = []
            all_rows[idx].append(row)

            actual_util_to_key_map = {
                actual_utils[i]: actual_keys[i] for i in range(len(actual_utils))
            }
            if len(pred_keys) != len(pred_utils):
                print(row)
                print(pred_keys, len(pred_keys))
                print(pred_utils, len(pred_utils))
            pred_util_to_key_map = {
                pred_utils[i]: pred_keys[i] for i in range(len(pred_utils))
            }

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
                if len(pred_util_to_key_map[actual_utils[i]]):
                    Sf = (
                        1
                        / N
                        * (
                            2
                            * len(
                                set(
                                    actual_util_to_key_map[actual_utils[i]]
                                ).intersection(
                                    set(pred_util_to_key_map[actual_utils[i]])
                                )
                            )
                            - len(
                                set(actual_util_to_key_map[actual_utils[i]]).union(
                                    set(pred_util_to_key_map[actual_utils[i]])
                                )
                            )
                        )
                    )
                else:
                    Sf = 0
                s += 1 / T * 1 / 2 * (1 + Sf)
            if all_s.get(idx, None) is None:
                all_s[idx] = []
            all_s[idx].append(s)

        total = []
        for idx in all_s:
            mx = max(all_s[idx])
            if mx < 0:
                total.append(sum(all_s[idx]) / len(all_s[idx]))
                print(idx, mx)
            else:
                total.append(mx)
        # return average of top 15 elements in total
        total.sort(reverse=True)
        # total = total[:15]
        print(total)
        return sum(total) / len(total)


print(get_score("labeledData.csv"))
# [1.0, 1.0, 1.0, 1.0, 1.0, 0.5, 0.375, 0.16666666666666669, -0.33333333333333326, -0.3333333333333333, -0.3333333333333333, -0.5, -0.5, -0.75, -0.75]
# 0.16944444444444454
print(get_score("mistraldata.csv"))
# [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.6666666666666666, 0.6666666666666666, 0.5, 0.5, 0.5, 0.4, 0.25, -0.5, -0.625, -0.625, -0.8333333333333333, -1.0, -1.0, -1.0, -1.0, -1.0]
# 0.2555555555555555
