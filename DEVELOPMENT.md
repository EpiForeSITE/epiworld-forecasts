# Development documentation

## Contributing

If you are thinking about contributing to this project (thank you!) we would like you to follow these guidelines:

- Before submitting a pull request, make sure you have read the [../CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md) file.
- Pull requests must be attached to an issue. If there is no issue, create one.
- Make sure you install the pre-commit hooks by running `pre-commit install` in the root of the project. If you don't have pre-commit in your computer, you can follow the installation instructions in the [pre-commit website](https://pre-commit.com/). When you commit locally, if pre-commit finds any errors it will abort the commit and make corrections. You will then need to commit again, adding the corrected files. Pre-commit will also run automatically as part of the PR checks and changes won't be merged unless the PR passes all checks.

## Building Container Image
Use the Dockerfile in [`../.devcontainer/`](../.devcontainer/) to build the `epiworld-forecasts` image.
The image includes [`rocker/tidyverse`](https://rocker-project.org/images/versioned/rstudio.html) and [`epiworldR`](https://github.com/UofUEpiBio/epiworldR).
It is stored on the Github Container Registry (`ghcr.io/`).

> [!IMPORTANT]
> **Note for macOS users (M-series chip):** Pulling and building the `rocker/tidyverse` image may require specifying the platform with `--platform=linux/amd64`
