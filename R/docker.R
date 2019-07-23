
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

	rscript <- function(code) {
		paste0("RUN Rscript -e \"", code, "\"")
	}

	context_dir <- tempdir()

	using_packrat <- requireNamespace("packrat", quietly = T) && any(grepl("packrat", packrat::search_path()$lib.dir))

	if (using_packrat) {
		target_packrat_dir <- file.path(context_dir, "packrat")
		src_packrat_dir <- file.path(getwd(), "packrat")

		packrat_files <- sapply(c("packrat.lock", "init.R"), function(f) file.path(src_packrat_dir, f))

		dir.create(target_packrat_dir)
		file.copy(packrat_files, target_packrat_dir)

		docker_operations <- c(
			"COPY packrat packrat"
		)

		bootstrap_operations <- c(
			"install.packages('packrat')",
			"packrat::restore()",
			"packrat::packify()"
		)
	} else {
		bootstrap_operations <- c(
			"install.packages('remotes')",
			"remotes::install_github('hypothesci/cloudburst')"
		)
	}

	lines <- c(
		paste0("FROM ", base),
		paste0("RUN apt-get update && apt-get install -y ", paste(apt_deps, collapse = " ")),
		docker_operations,
		rscript(paste(bootstrap_operations, collapse = "; ")),
		"CMD [ \"Rscript\", \"-e\", '\"cloudburst::runner()\""
	)

	writeLines(lines, con = file.path(context_dir, "Dockerfile"))

	build_status <- system(paste0("docker build -t ", image,  " ", context_dir))
	if (build_status != 0) stop("docker build failed")

	push_status <- system(paste0("docker push ", image))
	if (push_status != 0) stop("docker push failed")
}
