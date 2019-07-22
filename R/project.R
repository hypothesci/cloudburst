
global_defaults <- new.env(parent = emptyenv())
global_defaults$backends <- list()

# TODO: checks for
register_backend <- function(type, backend) global_defaults$backends[[type]] <- backend

retrieve_default_backend <- function(type) {
	backend <- global_defaults$backends[[type]]
	if (is.null(backend)) stop(paste0("default backend not set for: ", type))
	backend
}

register_compute_backend <- function(backend) register_backend("compute", backend)
register_storage_backend <- function(backend) register_backend("storage", backend)

#' Title
#'
#' @return
#' @export
#'
#' @examples
default_compute_backend <- function() {
	retrieve_default_backend("compute")
}

#' Title
#'
#' @return
#' @export
#'
#' @examples
default_storage_backend <- function() {
	retrieve_default_backend("storage")
}
