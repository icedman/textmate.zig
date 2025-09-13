import plistlib
import json
import sys
import os

def plist_to_json(plist_path, json_path):
    with open(plist_path, "rb") as f:
        data = plistlib.load(f)

    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def convert_directory(directory):
    for filename in os.listdir(directory):
        if filename.lower().endswith(".plist") or filename.lower().endswith(".tmLanguage"):
            plist_path = os.path.join(directory, filename)
            json_path = plist_path + ".json"  # append ".json" to filename
            try:
                plist_to_json(plist_path, json_path)
                print(f"Converted {filename} -> {os.path.basename(json_path)}")
            except Exception as e:
                print(f"Failed to convert {filename}: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <directory>")
        sys.exit(1)

    directory = sys.argv[1]
    if not os.path.isdir(directory):
        print(f"Error: {directory} is not a valid directory")
        sys.exit(1)

    convert_directory(directory)
