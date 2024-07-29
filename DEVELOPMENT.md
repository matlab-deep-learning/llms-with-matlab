# Notes for Developers

Nothing in this file should be required knowledge to use the repository. These are notes for people actually making changes that are going to be submitted and incorporated into the main branch.

## Git Hooks

After checkout, link or (on Windows) copy the files from `.githooks` into the local `.git/hooks` folder:

```
(cd .git/hooks/; ln -s ../../.githooks/pre-commit .)
```
