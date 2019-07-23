
#' Title
#'
#' @param image
#'
#' @return
#' @export
#'
#' @examples
docker_deploy <- function(image) {
	version <- paste0(version$major, ".", version$minor)

	base <- paste0("r-base:", version)
	apt_deps <- c("libcurl4-openssl-dev", "libxml2-dev", "libssl-dev")

	lines <- c(
		paste0("FROM ", base),
		paste0("RUN apt-get update && apt-get install -y ", paste(apt_deps, collapse = " ")),
		"RUN Rscript -e \"install.packages('remotes'); remotes::install_github('hypothesci/cloudburst')\"",
		"CMD [ \"Rscript\", \"-e\", '\"cloudburst::runner()\""
	)

	dockerfile <- paste(lines, collapse = "\n")
	build_status <- system(paste0("docker build -t ", image,  " -"), input = dockerfile)
	if (build_status != 0) stop("docker build failed")

	push_status <- system(paste0("docker push ", image))
	if (push_status != 0) stop("docker push failed")
}
