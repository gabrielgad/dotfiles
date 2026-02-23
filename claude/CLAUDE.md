# Claude Code System Configuration

## Critical Constraints

### Sudo Access
**NEVER run sudo commands. Claude Code does NOT have sudo access.**

Running sudo commands will:
- Fail with "sudo: a password is required"
- Count toward PAM faillock failed authentication attempts
- Lock out the user after 3 failures for 10 minutes

**When sudo is required:**
- Tell the user which commands to run in their terminal
- DO NOT attempt to run the command yourself

### Git Commits
**DO NOT add Claude Code branding to git commits.**

Do not add:
- "🤖 Generated with [Claude Code](https://claude.com/claude-code)"
- "Co-Authored-By: Claude <noreply@anthropic.com>"
- Any other Claude Code or Anthropic branding

Keep commit messages clean and professional without AI attribution.

## Environment Details

### Shell
- Default shell: Nushell (nu)
- Nushell syntax differences from bash:
  - Use `(command)` instead of `$(command)` for command substitution
  - Use `out+err>` instead of `2>&1` for redirection

### System
- OS: Linux (CachyOS)
- Package managers: pacman, yay
