import json
import subprocess
import sys

TERMINAL_NOTIFIER = "@TERMINAL_NOTIFIER@"
NOTIFY_SEND = "@NOTIFY_SEND@"


def send_notification(thread_id: str, title: str, message: str) -> None:
    if sys.platform == "darwin":
        subprocess.run(
            [
                TERMINAL_NOTIFIER,
                "-title",
                title,
                "-message",
                message,
                "-group",
                f"codex-{thread_id}",
                "-activate",
                "net.kovidgoyal.kitty",
            ],
            check=True,
        )
    else:
        subprocess.run(
            [
                NOTIFY_SEND,
                title,
                message,
            ],
            check=True,
        )


def main() -> int:
    notification = json.loads(sys.argv[1])
    if notification.get("type") != "agent-turn-complete":
        return 0

    send_notification(
        notification.get("thread-id", ""),
        "Codex",
        "Codex is ready for more action!",
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
