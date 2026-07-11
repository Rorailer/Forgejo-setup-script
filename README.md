# Forgejo Setup Script — Automated Self-Hosting on Ubuntu/Debian with Docker

A small bash script by [rorailer](https://github.com/rorailer) that does the boring parts of setting up Forgejo (a lightweight, Gitea-fork alternative to GitHub) for you on Ubuntu or Debian. From a fresh server to a running self-hosted Forgejo instance in minutes.

If you just want Forgejo running and don't care about the why behind every step, run this script. If you'd rather understand each piece, follow my [Forgejo Setup Guide](https://github.com/rorailer/Forgejo-setup-guide) instead. Same end result, different paths.

## What it does

- Checks your OS. If it's not Ubuntu or Debian, it exits.
- Looks for Docker. If it's missing, it asks if you want it installed and runs the official one-liner.
- Asks you for the external port (default `3123`) and the folder to put Forgejo in (default `./Forgejo`).
- Drops a `docker-compose.yaml` in that folder.
- Starts the container.
- Prints the URL where Forgejo is now reachable + container info.

If a Forgejo container already exists, the script just restarts it instead of touching your data.

## What you need

- Ubuntu or Debian server.
- `sudo` access (only if Docker isn't already installed).
- Internet so Docker can pull the image.

That's it.

## Quick start

```bash
git clone https://github.com/rorailer/Forgejo-setup-script.git
cd Forgejo-setup-script
chmod +x setup.sh uninstall.sh
./setup.sh
```

Press Enter at each prompt to use the defaults, or type your own values.

When it's done, open the URL it prints, scroll to the very bottom of Forgejo's setup page, and create your admin account. That's the only manual step left.

## Uninstall

```bash
./uninstall.sh
```

It'll stop and remove the container and ask whether you want to delete the data folder too. Your repos and database stay safe unless you say yes to that last question.

## Defaults

| Setting | Default |
|---|---|
| External port | `3123` |
| Folder location | `./Forgejo` |

Internal port is `3000` because that's just what Forgejo uses. Don't change that one.

## What this script does NOT do

- **No HTTPS or reverse proxy.** Forgejo runs on `http://your-ip:3123` after this. If you want a clean URL with HTTPS, that's a separate setup. I'll write a guide for it soon.
- **No backups.** The whole `data/` folder inside your Forgejo folder is everything. Back it up however you like.
- **No locking down repo visibility.** By default, public repos are visible without login. The [setup guide](https://github.com/rorailer/Forgejo-setup-guide) covers how to flip that.

## Related projects

If you're going further down the self-hosting path, you might find these useful:

- [Forgejo-setup-guide](https://github.com/rorailer/Forgejo-setup-guide) — A practical, no-fluff guide to self-hosting Forgejo with Docker. The "understand every step" companion to this script.
- [Server-Setup-Script](https://github.com/rorailer/Server-Setup-Script) — One-script self-hosting setup. Fresh VPS to Docker + Portainer + NPM + Cloudflared + firewall rules in minutes.

## License

MIT — see [LICENSE](./LICENSE).

## About

Maintained by **rorailer** — Fullstack & DevOps engineer.

- 🌐 Portfolio: [rorailer.site](https://rorailer.com)
- 🐙 GitHub: [github.com/rorailer](https://github.com/rorailer)
- 💼 LinkedIn: [linkedin.com/in/rorailer](https://linkedin.com/in/rorailer)
