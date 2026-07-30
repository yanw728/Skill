# GPT Adapter

Use this build as Custom Instructions or Project Instructions.

- Keep the extraction logic, but inline or summarize any dependency on sibling skills because GPT does not auto-load adjacent files.
- Remove tool-specific wording such as `present_files`.
- If file writing is unavailable, return the final Markdown inline and keep the filename suggestion in plain text.
- Prefer the shortest version of the rules that still preserves the output contract.
