# Improwised Helm Charts

This repository contains Helm charts maintained by Improwised Technologies Pvt. Ltd.

## Usage

### Adding the Helm Repository

To add the Improwised Helm repository to your Helm configuration, execute:

```bash
helm repo add improwised https://improwised.github.io/charts/
```

## Adding Charts

To add a new chart to this repository, follow these steps:

1. **Package the Chart**  
   Navigate to your chart's directory and package it using Helm. This command creates a `.tgz` file with the format `<chart-name>-<version>.tgz`:

   ```bash
   helm package <chart-directory-name>
   ```

2. **Switch to the `gh-pages` Branch**  
   Checkout the `gh-pages` branch of this repository:

   ```bash
   git checkout gh-pages
   ```

   Then, move the packaged chart to the `charts` directory:

   ```bash
   mv <chart-name>-<version>.tgz charts/
   ```

3. **Update the Chart Index**  
   Navigate to the `charts` directory and update the Helm repository index:

   ```bash
   cd charts
   helm repo index --url https://improwised.github.io/charts .
   ```

   **Note:** If you're adding the chart directly to releases without a pull request to the `charts` directory, ensure that existing entries in `index.yaml` are not removed. After generating the new `index.yaml`, compare the changes. If other charts are missing, manually append the new chart's entry to the existing `index.yaml` to preserve all entries.

4. **Commit and Push Changes**  
   Add and commit your changes with an appropriate message, then push to the `gh-pages` branch:

   ```bash
   git add charts/<chart-name>-<version>.tgz index.yaml
   git commit -m "Add <chart-name> version <version>"
   git push origin gh-pages
   ```

## Notes

- Ensure that the `semver` in the filename follows semantic versioning standards (e.g., `1.0.0`).
- Verify the repository after updating the index by running `helm repo update` on your system.
