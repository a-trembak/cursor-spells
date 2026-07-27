# Resolve a pull request to BASE_SHA / HEAD_SHA

Used by `pr-review` before delegating to the engineer-review spine.

## 1. Identity

From the invocation args (strip `apply` / `no-figma` first):

| Input | Action |
|-------|--------|
| `https://github.com/org/repo/pull/N` | PR number `N` in that repo (cd to matching git root if needed) |
| `N` or `#N` | PR number in the **current** repo |
| Branch name | `gh pr list --head <branch> --state open --json number --jq '.[0].number'` |
| Empty | `gh pr view --json number` for the current branch; if none, stop and ask |

## 2. Metadata

```bash
gh pr view <N> --json number,title,url,baseRefName,headRefName,baseRefOid,headRefOid,author,files,body,state
```

If `baseRefOid` / `headRefOid` are present, use them as `BASE_SHA` / `HEAD_SHA`.

Otherwise:

```bash
git fetch origin <baseRefName> <headRefName>
BASE_SHA=$(git merge-base "origin/<baseRefName>" "origin/<headRefName>")
HEAD_SHA=$(git rev-parse "origin/<headRefName>")
```

Confirm the range is non-empty: `git diff --name-only "$BASE_SHA..$HEAD_SHA"`. If empty, stop — nothing to review.

## 3. Checkout policy

- **Report-only:** prefer reviewing via SHAs without switching branches; fetch is enough.
- **`apply`:** require a clean working tree on the PR head (`gh pr checkout <N>` or equivalent). If another branch is checked out or the tree is dirty: stop and ask.

## 4. Fail closed

- No `gh` and no user-supplied `base..head` → stop.
- PR `state` is `MERGED` or `CLOSED` → warn; continue only if the user still wants a historical review of those SHAs.
- Private/inaccessible PR → stop; ask for local range or paste.
