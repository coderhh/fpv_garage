# Using a Separate GitHub Account for This Repo

This repo is configured to use a **different GitHub identity** from your default. Follow these steps to finish setup.

## 1. Set your commit identity (required)

Edit `.git/config` in this repo and replace the placeholder under `[user]`:

- **name**: Your other account’s display name (e.g. `Your FPV Account`).
- **email**: The email used by that GitHub account (or a [GitHub no-reply email](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-github-user-account/managing-email-preferences/setting-your-commit-email-address)).

Or set from the command line:

```bash
git config user.name "Your Other Account Name"
git config user.email "your-other-account@example.com"
```

## 2. Use that account for push/pull (SSH recommended)

To avoid mixing accounts, use a **dedicated SSH key** for this repo.

### 2a. Create an SSH key for the other account

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_fpv_garage -C "your-other-account@example.com"
```

Add the key to the agent (optional but convenient):

```bash
ssh-add ~/.ssh/id_ed25519_fpv_garage
```

### 2b. Add the public key to GitHub

1. Copy the public key:  
   `pbcopy < ~/.ssh/id_ed25519_fpv_garage.pub`
2. GitHub → **Settings** → **SSH and GPG keys** → **New SSH key** (for the account you use for this repo).
3. Paste and save.

### 2c. SSH config so this repo uses that key

Create or edit `~/.ssh/config`:

```
Host github-fpv
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_fpv_garage
  IdentitiesOnly yes
```

### 2d. Point this repo at the separate account

If the repo lives under the **other** account (e.g. `otheruser/fpv_garage`):

```bash
git remote set-url origin git@github-fpv:OTHER_USER/fpv_garage.git
```

Replace `OTHER_USER` with the GitHub username for that account.

Then tell this repo to use the `github-fpv` host (and thus the right key) for all Git SSH operations:

```bash
git config core.sshCommand "ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519_fpv_garage"
```

### 2e. Test

```bash
git fetch origin
```

If that works, push/pull will use the separate GitHub account for this repo only.

## 3. Optional: HTTPS instead of SSH

If you prefer HTTPS:

1. Keep the remote as `https://github.com/USER/fpv_garage.git` (with the other account’s USER).
2. When you `git push` or `git pull`, sign in as that account (browser or credential prompt).
3. On macOS, the Keychain can store different credentials per URL so this repo can keep using the other account.

---

**Summary**

- **Commits**: Identity is set in this repo’s `.git/config` under `[user]` (step 1).
- **Push/pull**: Use a dedicated SSH key and `Host github-fpv` (steps 2a–2e), or sign in with the other account over HTTPS (step 3).
