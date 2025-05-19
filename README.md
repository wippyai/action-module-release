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
          repository: ${{ github.repository }}
          tag: ${{ github.ref_name }}
          token: ${{ secrets.GITHUB_TOKEN }}
          module_id: "your-module-uuid"
```

### Local Testing

1. Clone the repository:
```bash
git clone https://github.com/wippyai/module-release-locator.git
cd module-release-locator
```

2. Make the scripts executable:
```bash
chmod +x scripts/*.sh
```

3. Run the script:
```bash
./scripts/main.sh \
  --repository "owner/repo" \
  --tag "v1.0.0" \
  --token "your-github-token" \
  --module-id "your-module-uuid"
```

#### Required Parameters

- `--repository`: GitHub repository in format `owner/repo` (e.g., `wippyai/module-hello`)
- `--tag`: Release tag to locate (e.g., `v1.0.0`)
- `--token`: GitHub token for authentication
- `--module-id`: UUID of the module to upload to

#### Dependencies

The script will automatically install required dependencies:
- grpcurl (for gRPC communication)
- jq (for JSON processing)

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
1. Edit the utility functions in `scripts/utils.sh`
2. Update the main script in `scripts/main.sh`
3. Test locally using the provided usage instructions
4. Update the GitHub Action in `action.yml` if needed
