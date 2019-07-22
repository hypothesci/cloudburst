
#' Title
#'
#' @return
#' @export
#'
#' @examples
runner <- function() {
	bootstrap <- unserialize(base64enc::base64decode(Sys.getenv("CLOUDBURST_BOOTSTRAP")))

	fn <- storage_read(bootstrap$storage, c(bootstrap$stage_storage_prefix, bootstrap$stage_id, "code.rds"))
	res <- fn()
	storage_write(bootstrap$storage, c(bootstrap$stage_storage_prefix, bootstrap$stage_id, "result.rds"))
}
