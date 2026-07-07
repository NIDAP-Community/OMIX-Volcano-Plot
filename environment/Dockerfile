# hash:sha256:bbfa38171f82ae8064568f11d435ad90466eb7c03b8806f46dde4c31a5b2e748
ARG REGISTRY_HOST
FROM $REGISTRY_HOST/codeocean/py-r:python3.10.12-R4.2.3-IRkernel-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG GIT_ASKPASS
COPY git-ask-pass /

ARG RCACHE_OPTIONS
RUN echo $RCACHE_OPTIONS >> $(Rscript -e 'cat(R.home())')/etc/Rprofile.site
RUN Rscript -e 'remotes::install_version("dplyr", "1.2.1")' \
    && Rscript -e 'remotes::install_version("ggplot2", "4.0.3")' \
    && Rscript -e 'remotes::install_version("ggrepel", "0.9.8")' \
    && Rscript -e 'remotes::install_version("jsonlite", "2.0.0")' \
    && Rscript -e 'remotes::install_version("optparse", "1.8.2")' \
    && Rscript -e 'remotes::install_version("stringr", "1.6.0")' \
    && Rscript -e 'remotes::install_version("tidyr", "1.3.2")'
