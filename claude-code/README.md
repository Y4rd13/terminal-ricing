# Claude Code — Setup Guide

Complete guide to set up Claude Code with MCP servers, plugins, custom agents, skills, and audio notifications on a fresh machine.

**Target environment:** Ubuntu on WSL2 (same as [ubuntu-wsl](../ubuntu-wsl/))

## Table of Contents

- [1. Install Claude Code](#1-install-claude-code)
- [2. Authenticate](#2-authenticate)
- [3. Deploy Configuration](#3-deploy-configuration)
- [4. Configure MCP Secrets](#4-configure-mcp-secrets)
- [5. Install Plugins](#5-install-plugins)
- [6. MCP Auth Setup](#6-mcp-auth-setup)
- [7. Verify Installation](#7-verify-installation)
- [Reference: What's Configured](#reference-whats-configured)

---

## 1. Install Claude Code

```bash
# Install via npm (requires Node.js, see ubuntu-wsl guide for nvm setup)
npm install -g @anthropic-ai/claude-code
```

Verify:

```bash
claude --version
```

## 2. Authenticate

```bash
claude
# Follow the browser-based OAuth flow on first launch
```

This creates `~/.claude/.credentials.json` (machine-specific, not synced).

## 3. Deploy Configuration

Configuration lives in a separate repo ([claude-config](https://github.com/Y4rd13/claude-config)) and gets symlinked to `~/.claude/`.

```bash
# Clone the config repo
cd ~/projects
git clone git@github.com:Y4rd13/claude-config.git

# Run the setup script (creates symlinks, backs up existing files)
cd claude-config
bash setup.sh
```

This links the following into `~/.claude/`:

| Source (repo) | Target (symlink) | Purpose |
|---------------|-------------------|---------|
| `settings.json` | `~/.claude/settings.json` | Permissions, hooks, plugins, env vars |
| `.mcp.json` | `~/.claude/.mcp.json` | MCP server configurations |
| `rules/` | `~/.claude/rules/` | User-level rules (auto-loaded) |
| `agents/` | `~/.claude/agents/` | Custom agents (code-cleanup-linter, commit-message-writer) |
| `skills/` | `~/.claude/skills/` | Custom skills (fastapi-architect, dead-code-audit, etc.) |
| `statusline.sh` | `~/.claude/statusline.sh` | Custom status line script |
| `sounds/` | `~/.claude/sounds/` | Notification sounds |

### Machine-Specific Overrides

After running `setup.sh`, create `~/.claude/settings.local.json` for machine-specific permissions. This file is NOT synced — it stays local.

Template:

```json
{
  "permissions": {
    "allow": [
      "Bash(docker pull:*)",
      "Bash(docker run:*)",
      "Bash(gh auth:*)",
      "Bash(gh repo:*)",
      "Bash(git remote:*)",
      "Bash(git push:*)",
      "Bash(mkdir:*)",
      "Bash(rm:*)",
      "mcp__atlassian__jira_search",
      "mcp__atlassian__confluence_search",
      "WebFetch(domain:github.com)",
      "WebFetch(domain:docs.anthropic.com)",
      "WebFetch(domain:raw.githubusercontent.com)"
    ]
  }
}
```

Add any additional permissions as needed for your workflow.

## 4. Configure MCP Secrets

MCP servers that require API keys read them from environment variables. Create the secrets file:

```bash
mkdir -p ~/.config/mcp
```

### secrets.env

This file is sourced by `.zshrc` and provides API keys to MCP servers.

```bash
cat > ~/.config/mcp/secrets.env << 'EOF'
# Claude Code
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000

# Context7 MCP
export CONTEXT7_API_KEY=your_context7_api_key_here

# GitHub Copilot MCP
export GITHUB_PERSONAL_ACCESS_TOKEN=your_github_pat_here
EOF
```

### atlassian.env (optional — only if using Jira/Confluence MCP)

```bash
cat > ~/.config/mcp/atlassian.env << 'EOF'
JIRA_URL=https://your-team.atlassian.net
JIRA_USERNAME=your_email@company.com
JIRA_API_TOKEN=your_jira_api_token_here
CONFLUENCE_URL=https://your-team.atlassian.net/wiki
CONFLUENCE_USERNAME=your_email@company.com
CONFLUENCE_API_TOKEN=your_confluence_api_token_here
TOOLSETS=all
EOF
```

> **Security:** These files contain secrets. Never commit them to git. The `.zshrc` sources `secrets.env` automatically.

## 5. Install Plugins

Launch Claude Code and install plugins from the official marketplace:

```bash
claude
# Then inside Claude Code:
/install-plugin ralph-loop@claude-plugins-official
/install-plugin rust-analyzer-lsp@claude-plugins-official
/install-plugin frontend-design@claude-plugins-official
/install-plugin superpowers@claude-plugins-official
/install-plugin context7@claude-plugins-official
/install-plugin claude-md-management@claude-plugins-official
/install-plugin security-guidance@claude-plugins-official
/install-plugin claude-code-setup@claude-plugins-official
/install-plugin skill-creator@claude-plugins-official
```

The `settings.json` (synced from the config repo) already has these plugins enabled — you just need to install them.

## 6. MCP Auth Setup

Some MCP servers require interactive authentication on first use:

### Google Calendar

```bash
# Inside Claude Code, trigger any calendar action — it will prompt for OAuth
```

### Sentry

```bash
# Inside Claude Code, trigger any Sentry action — it will prompt for auth
```

### Atlassian (Jira/Confluence)

No interactive auth needed if `atlassian.env` is configured (step 4). The MCP server reads credentials from environment variables.

### Cyberpunk Modding MCPs (cet-bridge, wolvenkit)

These are local development servers. They only work if:
- The game is installed at the path specified in `.mcp.json`
- The MCP server repos are cloned and built locally
- See `.mcp.json` for the expected paths (update them if your game install differs)

## 7. Verify Installation

```bash
claude
```

Inside Claude Code, check:

| Check | How | Expected |
|-------|-----|----------|
| Config loaded | Settings apply (hooks, permissions) | Audio plays on session start |
| MCP servers | `/mcp` | Lists configured servers |
| Plugins | Skills available in conversation | Superpowers, frontend-design, etc. |
| Context7 | Ask about any library docs | Fetches live documentation |
| Custom agents | Available in agent list | code-cleanup-linter, commit-message-writer |

---

## Reference: What's Configured

### MCP Servers

| Server | Type | Purpose |
|--------|------|---------|
| context7 | npx | Live library/framework documentation |
| github | HTTP | GitHub Copilot API |
| playwright | npx | Browser automation and testing |
| cet-bridge | local | Cyberpunk Engine Tweaks (game modding) |
| wolvenkit | local | WolvenKit CLI (game modding) |
| atlassian | env-based | Jira + Confluence (via atlassian.env) |
| google-calendar | OAuth | Google Calendar integration |
| sentry | OAuth | Error tracking |

### Audio Hooks (WSL + PowerShell)

| Event | Sound |
|-------|-------|
| Session start | Windows Logon.wav |
| Task complete (Stop) | Custom notification.mp3 |
| Notification | Windows Notify.wav |
| Tool failure | Windows Error.wav |
| Subagent complete | ding.wav |
| Post-compact | Windows Exclamation.wav |

> **Note:** Audio hooks use `powershell.exe` from WSL. They work out of the box on WSL2 with Windows audio. On native Linux, replace with `paplay` or equivalent.

### Plugins

| Plugin | Purpose |
|--------|---------|
| superpowers | Brainstorming, planning, TDD, debugging, code review workflows |
| frontend-design | UI/frontend code generation |
| context7 | Library documentation lookup |
| claude-md-management | CLAUDE.md file management |
| skill-creator | Create and test custom skills |
| claude-code-setup | Automation recommendations |
| ralph-loop | Recurring prompt loop |
| rust-analyzer-lsp | Rust language server integration |
| security-guidance | Security best practices |

### Custom Agents

| Agent | Purpose |
|-------|---------|
| code-cleanup-linter | Clean comments, standardize to English, run linting |
| commit-message-writer | Generate conventional commit messages |

### Custom Skills

| Skill | Purpose |
|-------|---------|
| fastapi-architect | Scaffold/review FastAPI services |
| dead-code-audit | Find unused Python code |
| minimal-tests-audit | Propose minimal test coverage |
| python-best-practices | Production Python standards |
| repo-codebook-generator | Generate repo documentation |
