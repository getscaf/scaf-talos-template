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


def party_popper():
    for _ in range(4):
        print("\r🎉 POP! 💥", end="", flush=True)
        subprocess.run(["sleep", "0.3"])
        print("\r💥 POP! 🎉", end="", flush=True)
        subprocess.run(["sleep", "0.3"])

    print("\r🎊 Congrats! Your {{ copier__project_slug }} Talos cluster project is ready! 🎉")
    print()
    print("To get started:")
    print("1. cd {{ copier__project_slug }}")
    print("2. Create S3 backend: cd terraform/bootstrap && tofu init && tofu plan -out=tfplan.out && tofu apply tfplan.out")
    print("3. Deploy infrastructure: cd ../sandbox && tofu init && tofu plan -out=tfplan.out && tofu apply tfplan.out")
    print("4. Bootstrap Talos: cd ../../bootstrap-cluster && export ENV=sandbox && task talos:bootstrap")
    print()


def run_setup():
    print("Performing initial commit.")
    subprocess.run(shlex.split("git add ."), check=True)
    subprocess.run(shlex.split("git commit -m 'Initial commit' --quiet"), check=True)


def main():
    init_git_repo()
    run_setup()
    party_popper()

    print(SUCCESS + "Project initialized, keep up the good work!!" + TERMINATOR)


if __name__ == "__main__":
    main()
