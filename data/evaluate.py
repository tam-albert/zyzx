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
            actual_keys = json.dumps(actual_keys)
            pred_keys = json.dumps(pred_keys)
            actual_keys = ast.literal_eval(actual_keys)
            pred_keys = ast.literal_eval(pred_keys)
            actual_utils = json.dumps(actual_utils)
            pred_utils = json.dumps(pred_utils)
            actual_utils = ast.literal_eval(actual_utils)
            pred_utils = ast.literal_eval(pred_utils)

            print("should be good", actual_utils, len(actual_utils))

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
                # actual_utils[i] == pred_utils[i]
                print(actual_keys, pred_keys, i)
                print(actual_utils, pred_utils, i)
                print(len(actual_utils), len(pred_utils))
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
        if mx > 0:
            return mx
        else:
            return 1 / num_rows * sum(all_s)


print(get_score())
