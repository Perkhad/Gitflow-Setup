# GitHub Repository Setup Script

This script automates the standard configuration process for GitHub repositories, enforcing best practices and a consistent setup, particularly suitable for workflows like Gitflow. It utilizes the GitHub CLI (`gh`) to interact with the GitHub API.

## Overview

The script performs the following actions on the target repository (the one in the current directory where the script is run):

1.  **Sets `GH_TOKEN` Secret:** Adds a repository secret named `GH_TOKEN`. Requires a Personal Access Token (PAT) with appropriate permissions to be provided via the `GH_PAT` environment variable. *(Note: Ensure this PAT has the necessary scopes, potentially `repo` and `workflow`)*.
2.  **Sets Default Branch:** Changes the default branch to `develop`.
3.  **Applies Branch Protections (Legacy):** Configures strict branch protection rules for `main` and `develop`:
    *   Requires status checks to pass before merging (specifically `call-self / Quality Gate Checks` - **customize if needed**).
    *   Requires branches to be up-to-date before merging.
    *   Enforces these rules for administrators.
    *   Requires at least one approving pull request review.
    *   Dismisses stale pull request approvals when new commits are pushed.
    *   Requires conversation resolution before merging.
    *   Requires linear history (prevents merge commits).
    *   Disallows force pushes.
    *   Disallows deletions.
4.  **Enables Auto-Delete Branches:** Configures the repository to automatically delete head branches after pull requests are merged.
5.  **Sets Pull Request Preferences:** Configures the repository to **only allow Squash Merging**. Disables standard Merge Commits and Rebase Merging.
6.  **Creates Repository Rulesets:** Implements finer-grained rules using GitHub Rulesets:
    *   **`hotfix/*` Branches:**
        *   Prevents deletion.
        *   Prevents non-fast-forward pushes.
        *   Allows **Repository Admins** to bypass these rules (necessary for manual deletion after merging to `main` and `develop`).
    *   **`release/*` Branches:**
        *   Prevents deletion.
        *   Prevents non-fast-forward pushes.
        *   Allows **Repository Admins** to bypass these rules (necessary for manual deletion after merging to `main` and `develop`).
    *   **`feature/*` Branches:**
        *   Prevents non-fast-forward pushes.
        *   **Allows deletion:** This is intentional to work with the repository's "auto-delete branches" setting, ensuring feature branches are cleaned up automatically after merging.

## Prerequisites

1.  **GitHub CLI (`gh`):** You need to have the GitHub CLI installed and authenticated. You can install it from [cli.github.com](https://cli.github.com/). Run `gh auth login` to authenticate.
2.  **Permissions:** You must have **Admin** permissions on the target GitHub repository to apply these settings.
3.  **Personal Access Token (PAT):** You need a GitHub Personal Access Token (Classic or Fine-Grained) with sufficient permissions (e.g., `repo`, `workflow` scopes) to set the `GH_TOKEN` secret. This token should be exported as an environment variable named `GH_PAT` *before* running the script.
    ```bash
    export GH_PAT="YOUR_GITHUB_PAT_HERE"
    ```
4.  **(Optional) `jq`:** While not strictly required by *this version* of the script, `jq` is a useful command-line JSON processor often used with `gh api`.

## Usage

1.  **Clone this Repository:** Get the script onto your local machine.
    ```bash
    # git clone <url-to-this-repo>
    # cd <repo-name>
    ```
2.  **Modify the Script:**
    *   **IMPORTANT:** Open the script file (e.g., `setup_repo.sh`) in a text editor.
    *   **Change the Organization Name:** Update the `ORG` variable to your GitHub organization name.
        ```bash
        ORG="YOUR-ORG-NAME" # <-- CHANGE THIS
        ```
    *   **(Optional) Customize Settings:** Review other settings like the `required_status_checks` context (`"call-self / Quality Gate Checks"`) and adjust if your workflow uses different check names.
3.  **Navigate to Target Repository:** Change your directory (`cd`) to the local clone of the **repository you want to configure**. The script uses `basename "$PWD"` to determine the repository name.
    ```bash
    cd /path/to/your/target-repo
    ```
4.  **Set Environment Variable:** Export the PAT required for the `GH_TOKEN` secret.
    ```bash
    export GH_PAT="YOUR_GITHUB_PAT_HERE"
    ```
5.  **Make Script Executable:**
    ```bash
    chmod +x /path/to/setup_repo.sh
    ```
6.  **Run the Script:**
    ```bash
    /path/to/setup_repo.sh
    ```

The script will output progress messages as it applies the settings.

## Important Notes

*   **Idempotency:** This script uses `gh api --method POST` to create rulesets. If rulesets with the *exact same names* already exist in the target repository, the `POST` calls for those rulesets will fail. To make the script fully idempotent (runnable multiple times without error), you would need to modify it to first check if a ruleset exists by name, get its ID, and then use `gh api --method PUT ... /rulesets/{id}` to update it. For now, if you encounter errors about existing rulesets, you might need to delete them manually via the GitHub UI before re-running the script.
*   **Permissions:** Ensure the user running the script and the PAT used have the necessary administrative permissions on the repository.
*   **Status Check Context:** The branch protection rule relies on a status check named `"call-self / Quality Gate Checks"`. Make sure your GitHub Actions workflows (or other CI/CD systems) actually report a status check with this exact name, otherwise the protection might block merging pull requests.
*   **Admin Bypass:** The rulesets for `flow/*`, `hotfix/*`, and `release/*` explicitly grant bypass permissions to the "Repository admin" role. This means users with admin privileges *can* delete these protected branches manually when needed (which is required for `hotfix` and `release` branches after they are fully merged).

## License

This project is licensed under the terms of the [MIT License](./LICENSE).
