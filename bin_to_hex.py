def raw_to_hex8(input_filename, output_filename):
    """
    Converts an 8-bit PCM raw file into a hex file for Verilog ROM.
    Each line is one 8-bit sample in hex (2 digits, 00-FF).
    """
    try:
        with open(input_filename, 'rb') as f_in:
            raw = f_in.read()

        with open(output_filename, 'w') as f_out:
            for b in raw:
                # convert to unsigned 8-bit hex
                f_out.write(f"{b:02x}\n")

        print(f"Converted {input_filename} → {output_filename} (8-bit samples).")

    except Exception as e:
        print(f"Error: {e}")

raw_to_hex8("snare8.raw", "snare8.hex")