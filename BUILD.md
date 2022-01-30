# Building instructions

Simply run:

```bash
source project.version && docker build ./ -t pegi3s/phylogenetic-tree-collapser:${PTC_DOCKER_IMAGE_VERSION} --build-arg PTC_VERSION=${PTC_DOCKER_IMAGE_VERSION} --build-arg PTC_JAR_VERSION=${PTC_JAR_VERSION} && docker tag pegi3s/phylogenetic-tree-collapser:${PTC_DOCKER_IMAGE_VERSION} pegi3s/phylogenetic-tree-collapser
```

# Build log

- 1.1.0 - 30/01/2022 - Hugo López Fernández
- 1.0.3 - 27/01/2022 - Hugo López Fernández
- 1.0.2 - 27/01/2022 - Hugo López Fernández
- 1.0.1 - 25/01/2022 - Hugo López Fernández
- 1.0.0 - 07/01/2022 - Hugo López Fernández
- 0.0.1 - 04/11/2021 - Hugo López Fernández
