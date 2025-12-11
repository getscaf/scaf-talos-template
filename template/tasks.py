import os
import shlex
import subprocess

TERMINATOR = "\x1b[0m"
WARNING = "\x1b[1;33m [WARNING]: "
INFO = "\x1b[1;33m [INFO]: "
HINT = "\x1b[3;33m"
SUCCESS = "\x1b[1;32m [SUCCESS]: "


def init_git_repo():
    print(INFO + "Initializing git repository..." + TERMINATOR)
    print(INFO + f"Current working directory: {os.getcwd()}" + TERMINATOR)
    subprocess.run(
        shlex.split("git -c init.defaultBranch=main init . --quiet"), check=True
    )
    print(SUCCESS + "Git repository initialized." + TERMINATOR)


def configure_git_remote():
    repo_url = "{{ copier__repo_url }}"
    if repo_url:
        print(INFO + f"repo_url: {repo_url}" + TERMINATOR)
        command = f"git remote add origin {repo_url}"
        subprocess.run(shlex.split(command), check=True)
        print(SUCCESS + f"Remote origin={repo_url} added." + TERMINATOR)
    else:
        print(
            WARNING
            + "No repo_url provided. Skipping git remote configuration."
            + TERMINATOR
        )


def party_popper():
    for _ in range(4):
        print("\r🎉 POP! 💥", end="", flush=True)
        subprocess.run(["sleep", "0.3"])
        print("\r💥 POP! 🎉", end="", flush=True)
        subprocess.run(["sleep", "0.3"])

    print("\r🎊 Congrats! Your {{ copier__project_slug }} project is ready! 🎉")
    print()
    print("To get started, run:")
    print("cd {{ copier__project_slug }}")
    print("tilt up")
    print()


def run_setup():
    subprocess.run(
        shlex.split("kind create cluster --name {{ copier__project_dash }}"), check=True
    )
    subprocess.run(shlex.split("make compile"), check=True)

    print("Dependencies compiled successfully.")
    print("Performing initial commit.")

    subprocess.run(shlex.split("git add ."), check=True)
    subprocess.run(shlex.split("git commit -m 'Initial commit' --quiet"), check=True)


def main():
    init_git_repo()
    configure_git_remote()
    run_setup()
    party_popper()

    print(SUCCESS + "Project initialized, keep up the good work!!" + TERMINATOR)


if __name__ == "__main__":
    main()
