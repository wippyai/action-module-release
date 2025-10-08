# Module Release Locator

A GitHub Action and local tool for locating and processing release source code from GitHub repositories.

## Features

- Locates GitHub releases by repository and tag
- Downloads release source code
- Uploads source code to modules.wippy.ai
- Supports both GitHub Actions and local execution

## Usage

### GitHub Action Usage

Add the following to your workflow file (`.github/workflows/your-workflow.yml`):

```yaml
name: Release Module

on:
  release:
    types: [published]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: wippyai/module-release-locator@v1
        with:
          username: ${{ secrets.WIPPY_USERNAME }}
          password: ${{ secrets.WIPPY_PASSWORD }}
          # tag is optional - uses github.ref_name if not provided
```

### Local Testing

1. Clone the repository:
```bash
git clone https://github.com/wippyai/module-release-locator.git
cd module-release-locator
```

2. Make the script executable:
```bash
chmod +x main.sh
```

3. Run the script:
```bash
./main.sh \
  --repository "owner/repo" \
  --tag "v1.0.0" \
  --token "your-github-token" \
  --module-id "your-module-uuid" \
  --username "your-wippy-username" \
  --password "your-wippy-password"
```

#### Required Parameters

- `username`: Username for modules.wippy.ai authentication
- `password`: Password for modules.wippy.ai authentication

#### Optional Parameters

- `tag`: The version tag to publish. Supports packcli automatic increments (major/minor/patch/tag) or semantic version format (e.g., v1.0.0, 1.0.0-alpha.1). If not provided, uses github.ref_name.
- `directory`: The directory to release files (default: ".")

#### Automatic Parameters

The action automatically uses:
- `repository`: Current GitHub repository (`${{ github.repository }}`)
- `source_tag`: Current release tag for cloning (`${{ github.ref_name }}`)

#### How it works

1. **Clones** the repository from the current tag/branch (`github.ref_name`)
2. **Publishes** the module with the specified version tag (`inputs.tag`)
3. This allows you to publish a different version than the one you're currently on

#### Version Tag Examples

```yaml
# Packcli automatic increments (no --version flag):
tag: "major"      # ✅ packcli module publish major
tag: "minor"      # ✅ packcli module publish minor  
tag: "patch"      # ✅ packcli module publish patch
tag: "tag"        # ✅ packcli module publish tag

# Semantic version tags (with --version flag):
tag: "v1.0.0"     # ✅ packcli module publish --version "v1.0.0"
tag: "1.2.3"      # ✅ packcli module publish --version "1.2.3"
tag: "1.0.0-alpha.1"     # ✅ packcli module publish --version "1.0.0-alpha.1"
tag: "1.0.0+build.123"   # ✅ packcli module publish --version "1.0.0+build.123"
tag: "v2.0.0-alpha.1+build.123"  # ✅ packcli module publish --version "v2.0.0-alpha.1+build.123"

# Invalid tags (will use fallback):
tag: "latest"     # ❌ Will use github.ref_name or default to tag
tag: "dev"        # ❌ Will use github.ref_name or default to tag
```

#### Dependencies

The script will automatically install required dependencies:
- jq (for JSON processing)
- Docker (for building and running the upload tool)

## Output

The script provides the following outputs:
- Release URL
- Source code URL

## Error Handling

The script includes error handling for:
- Missing required parameters
- Invalid repository/tag combinations
- Network issues
- Authentication failures

## Development

To modify the functionality:
1. Edit the main script in `main.sh`
2. Test locally using the provided usage instructions
3. Update the GitHub Action in `action.yml` if needed
