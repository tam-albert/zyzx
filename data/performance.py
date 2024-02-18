ENDPOINT = "https://474aeee83f0d.ngrok.app"

import requests
import json

models = ["0", "1", "2", "gpt"]


def query_model(model: str, input_string: str):
    body = {"model": model, "query": input_string}
    response = requests.post(
        ENDPOINT + f"/generate_code",
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


print(query_model("1", "write a story into the file `story.txt`"))


# with open("validation.jsonl") as f:
#     lines = f.readlines()
#     for line in lines:
#         print(line)


# def query_model(model: str, input_string: str):
#     body = {
#         "model": model,
#         "messages": [{"role": "user", "content": input_string}],
#     }
#     response = requests.post(
#         ENDPOINT + f"/openai",
#         headers={"content-type": "application/json"},
#         data=json.dumps(body),
#     )
#     print(response)
# if (
#     response.status_code != 200
#     or response.headers["Content-Type"] != "application/json"
# ):
#     print(f"Error: {response.status_code}")
#     return None
# res_json = response.json()
# return res_json["message"]


# def query_models():
# res1 = query_model(
#     "0",
#     "delete the file named `hello.txt`",
# )
# res2 = query_model(
#     "1",
#     "delete the file named `hello.txt`",
# )
# res3 = query_model(
#     "2",
#     "delete the file named `hello.txt`",
# )
# res4 = query_model(
#     "openai",
#     "delete the file named `hello.txt`",
# )

# print("res1", res1)
# print("res2", res2)
# print("res3", res3)
# print("res4", res4)


# query_models()
