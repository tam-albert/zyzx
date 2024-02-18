import subprocess
import time

history = []
commands = []

with open("acommands1.txt", "rb") as file:
    for line in file:
        encodings = ["utf-8", "latin1", "ascii"]
        for encoding in encodings:
            try:
                decoded_line = line.decode(encoding)
                history.append(" ".join(decoded_line.strip().split()[1:]))
                break
            except UnicodeDecodeError:
                continue
history = list(set(history))


def run_command_and_check_exit_status(command):
    if (
        "mv" in command
        or "rm" in command
        or "cp" in command
        or "git" in command
        or "mkdir" in command
        or "touch" in command
        or "ln" in command
        or "vim" in command
        or "ssh" in command
        or "sudo" in command
        or "#include" in command
    ):
        return
    process = subprocess.Popen(command, shell=True)
    time.sleep(0.05)
    if process.poll() is None:
        process.terminate()

    return_code = process.returncode
    if return_code == 0:
        commands.append(command)


def write_array_to_file(array, filename):
    with open(filename, "w") as file:
        for item in array:
            file.write(str(item) + "\n")


# write_array_to_file(commands, "rcommands1.txt")

all_commands = []
with open("all_commands.txt", "r") as file:
    for line in file:
        all_commands.append(line.strip())

for i in range(1, 6):
    with open(f"acommands{i}final.txt", "rb") as file:
        for line in file:
            encodings = ["utf-8", "latin1", "ascii"]
            for encoding in encodings:
                try:
                    decoded_line = line.decode(encoding)
                    all_commands.append(" ".join(decoded_line.strip().split()[1:]))
                    break
                except UnicodeDecodeError:
                    continue

all_commands = list(set(all_commands))
write_array_to_file(all_commands, "all_commands.txt")
