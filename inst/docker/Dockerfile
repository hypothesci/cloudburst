FROM r-base:3.5.0
RUN Rscript -e "install.packages('devtools'); devtools::install_github('hypothesci/cloudburst')"
CMD [ "Rscript", "-e", "cloudburst::runner()" ]
