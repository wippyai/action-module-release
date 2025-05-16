# Module Release Locator

This GitHub Action helps locate and process release source code from GitHub repositories. It's particularly useful for finding specific release versions of modules and their associated source code.

## Inputs

### `repository`

**Required** The repository to locate release from (e.g., `wippyai/module-hello`).

### `tag`

**Required** The release tag to locate (e.g., `v1.0.0`).

### `token`

**Required** GitHub token for authentication. Use `${{ secrets.GITHUB_TOKEN }}` for public repositories or create a Personal Access Token for private repositories.

## Outputs

### `release_url`

The URL of the located release (e.g., `https://github.com/wippyai/module-hello/releases/tag/v1.0.0`).

### `source_code_url`

The URL of the release source code.

## Example usage

```yaml
uses: your-username/module-release-locator@v1
with:
  repository: 'wippyai/module-hello'
  tag: 'v1.0.0'
  token: ${{ secrets.GITHUB_TOKEN }}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
