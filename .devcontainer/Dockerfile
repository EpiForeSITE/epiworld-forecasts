# Use rocker/tidyverse as a base to get:
# - R, quarto, data.table, ggplot2
FROM rocker/tidyverse:4.4.1

# To enable Git from within the container
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git ssh

# Install epiworldR
RUN installGithub.r UofUEpiBio/epiworldR@30afdce

RUN install2.r languageserver

# Run Bash
CMD ["bash"]
