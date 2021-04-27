# charts
Helm charts maintained by Improwised Technologies
## Usage

Add helm repo

```bash
helm repo add improwised https://improwised.github.io/charts/
```

## Add charts

1. Package the chart, this will create `chartname-semver.tgz` file.

   ```bash
   helm package <chart-directory-name>
   ```

2. Checkout `gh-pages` branch of this repo and move `chart-name-semver.tgz` to `charts` directory.

3. Index added chart

   ```bash
   helm repo index --url https://improwised.github.io/charts .
   ```

4. Add appropriate commit message and push it
