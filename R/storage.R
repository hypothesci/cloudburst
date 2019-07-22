
#' Title
#'
#' @param storage_backend
#' @param path
#' @param data
#'
#' @return
#' @export
#'
#' @examples
storage_write <- function(storage_backend, path, data) {
	UseMethod("storage_write", storage_backend)
}

#' Title
#'
#' @param storage_backend
#' @param path
#'
#' @return
#' @export
#'
#' @examples
storage_read <- function(storage_backend, path) {
	UseMethod("storage_read", storage_backend)
}
