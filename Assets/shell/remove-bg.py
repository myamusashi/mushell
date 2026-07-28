#!/usr/bin/env python3
import sys
from rembg import remove, new_session

def main():
    if len(sys.argv) != 5 or sys.argv[1] != "-m":
        print("Usage: remove-bg.py -m <model-name> <input> <output>", file=sys.stderr)
        sys.exit(1)

    model = sys.argv[2]
    input_path = sys.argv[3]
    output_path = sys.argv[4]

    session = new_session(model)
    with open(input_path, "rb") as f:
        input_data = f.read()
    result = remove(input_data, session=session)

    with open(output_path, "wb") as f:
        f.write(result)


if __name__ == "__main__":
    main()
