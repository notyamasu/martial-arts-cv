import json

from openai import OpenAI

# open json file with api key
with open("openai_key.json") as f:
    key = json.load(f)

client = OpenAI(
    # This is the default and can be omitted
    api_key=key["OPENAI_API_KEY"],
)


def get_martial_arts_feedback(full_summary):
    prompt = (
        "You are a martial arts coach reviewing a student’s movements compared to an expert.\n"
        "Below is a summary of joint angle differences per segment. Provide a concise overall assessment "
        "with praise, critique, and improvement tips.\n\n"
        f"{full_summary}"
    )

    try:
        completion = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": "You are a helpful martial arts coach."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            max_tokens=500
        )
        return completion.choices[0].message.content.replace('*', '')
    except Exception as e:
        return f"OpenAI API Error: {e}"
