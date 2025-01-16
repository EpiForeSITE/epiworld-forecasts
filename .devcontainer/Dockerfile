# Use rocker/tidyverse as a base to get:
# - R, quarto, data.table, ggplot2
FROM rocker/tidyverse:4.4.1

# Install epiworldR
RUN installGithub.r UofUEpiBio/epiworldR@30afdce

RUN install2.r languageserver

# Run Bash
CMD ["bash"]
