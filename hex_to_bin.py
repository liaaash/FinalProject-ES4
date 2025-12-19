def hex_to_bin(input_filename, output_filename):
    """
    Converts a hex file (each line = one 16-bit hex sample)
    into a binary file (each line = 16-bit binary string).
    Example input line: 3fa2
    Example output line: 0011111110100010
    """

    try:
        with open(input_filename, 'r') as f_in:
            lines = f_in.read().strip().splitlines()

        with open(output_filename, 'w') as f_out:
            for line in lines:
                h = line.strip()

                if len(h) == 0:
                    continue

                # ensure valid hex
                value = int(h, 16)

                # convert to 16-bit binary string
                b = f"{value:016b}"

                f_out.write(b + "\n")

        print(f"Converted {input_filename} → {output_filename} (hex → 16-bit binary).")

    except Exception as e:
        print(f"Error: {e}")

hex_to_bin("cymbal.hex", "testCymbal.bin")
