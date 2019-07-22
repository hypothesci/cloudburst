FROM r-base:3.5.0

RUN apt-get update && apt-get install -y\
	libcurl4-openssl-dev\
	libxml2-dev\
	libssl-dev

RUN Rscript -e "install.packages('remotes'); remotes::install_github('hypothesci/cloudburst')"

CMD [ "Rscript", "-e", "cloudburst::runner()" ]
