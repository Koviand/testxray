#!/usr/bin/env python3
"""Timer hook: refresh subscription artifacts after panel changes."""
import subprocess
import sys

INSTALL_ROOT = "/usr/local/testxray"
SCRIPT = f"{INSTALL_ROOT}/scripts/build-subscription.sh"


def main() -> int:
    try:
        subprocess.run(["bash", SCRIPT], check=False)
    except OSError as e:
        print(e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
