# 🏡🍻 Homebrew Tap

Homebrew tap for tools developed by [Corey Coto](https://github.com/coreycoto) and [Codex](https://openai.com/codex/).

## git-slop

Supported platforms: Apple Silicon macOS and Linux.

```bash
brew tap coreycoto/tap
brew install coreycoto/tap/git-slop
git-slop version
git slop version
```

The `git-slop` formula is generated from the `coreycoto/git-slop` release
manifest with `scripts/update_homebrew_formula.py` in that repository. 

## Bottle Publishing

Pull requests build bottle artifacts with Homebrew's `brew test-bot` workflow.
When a formula update is green, apply the `pr-pull` label to publish the bottles,
merge the PR, and update the formula bottle block.
