
#' Title
#'
#' @param project
#' @param bucket
#'
#' @return
#' @export
#'
#' @examples
storage_s3 <- function(project, bucket) {
	structure(list(project = project, bucket = bucket), class = "s3_storage")
}

path_to_s3key <- function(path) paste(path, collapse = "/")

#' Title
#'
#' @param storage
#' @param path
#' @param data
#'
#' @return
#' @export
#'
#' @examples
storage_write.s3_storage <- function(storage, path, data) {
	aws.s3::s3saveRDS(data, region = storage$project$region, bucket = storage$bucket, object = path_to_s3key(path))
}

#' Title
#'
#' @param storage
#' @param path
#'
#' @return
#' @export
#'
#' @examples
storage_read.s3_storage <- function(storage, path) {
	aws.s3::s3readRDS(region = storage$project$region, bucket = storage$bucket, object = path_to_s3key(path))
}
