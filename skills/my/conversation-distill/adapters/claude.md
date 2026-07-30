# Claude Adapter

<claude>
Use this variant when the host mounts skills as plain Markdown plus a separate description field.

- Treat any OpenClaw-only frontmatter as metadata, not as part of the prompt body.
- If the base skill mentions `/mnt/user-data/outputs/` or `present_files`, translate that into Claude's available file-writing mechanism. If no file tool exists, return the final Markdown directly.
- When resolving sibling skills such as `obsidian-writing`, prefer the mounted skills root and relative paths like `{baseDir}/../obsidian-writing/...`.
</claude>
