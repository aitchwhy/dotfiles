# Security Notice

WARNING: PII was historically committed to this repository.

Before making this repository public, run:

```bash
git filter-repo --path config/wispr-flow/ --path config/httpie/sessions/ --invert-paths
```

This will permanently remove sensitive data from git history.
