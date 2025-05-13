import json


def read_expert_angles_file():
    # read the json file if it exists
    try:
        with open(f"angles/expert_angles.json", "r") as f:
            existing_angles = json.load(f)
    except FileNotFoundError:
        existing_angles = {}
    return existing_angles
