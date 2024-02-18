from openai import OpenAI

client = OpenAI(api_key="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")


def gen_message(query):
    # Generate a chat completion based on the prompt
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": query},
        ],
    )
    return response.choices[0].message.content


# Define the prompt for the chat completion
prompt = "Hi, how are you today?"

res = gen_message(prompt)
print(res)
