---
description: Validate ADR and PDR files against governance rules
allowed-tools: Bash, Read, Edit
---

# Lint Decision Records

Run the ADR/PDR governance validator against the specified files (or all records if none specified).

## Steps

1. Run the lint script:

```bash
./scripts/lint-decisions.sh $ARGUMENTS
```

2. Report the results clearly — list each violation and warning with the file and rule that failed.

3. For any violations found, offer to fix them if they are mechanical issues:
   - **Authoring guide comment still present** → remove the `<!-- AUTHORING GUIDE ... -->` block
   - **Placeholder text in `<summary>`** → ask the user what the summary should be
   - **`<last-validated>` missing or placeholder** → prompt for the date or set to today if the user confirms the decision is current
   - **Placeholder in `<date>`** → ask the user for the correct date
   - **`<status>` invalid** → ask which valid status applies

4. For structural violations (missing alternatives table, empty constraints/invariants), explain what is required and what good looks like — don't fabricate content.

5. After any fixes, re-run the linter to confirm all violations are resolved.
