# Building instructions

Simply run:

```bash
ptc_version=$(cat project.version) && docker build ./ -t pegi3s/phylogenetic-tree-collapser:${ptc_version} --build-arg PTC_VERSION=${ptc_version}
```

# Build log

- 0.0.1 - 04/11/2021 - Hugo López Fernández
- 1.0.0 - 07/01/2022 - Hugo López Fernández
