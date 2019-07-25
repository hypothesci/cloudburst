
#' Title
#'
#' @return
#' @export
#'
#' @examples
runner <- function() {
	bootstrap <- unserialize(base64enc::base64decode(Sys.getenv("CLOUDBURST_BOOTSTRAP")))
	args <- lapply(bootstrap$dependency_ids, function(i) storage_read(bootstrap$storage, c(bootstrap$stage_storage_prefix, i, "result.rds")))
	stage_data <- storage_read(bootstrap$storage, c(bootstrap$stage_storage_prefix, bootstrap$stage_id, "code.rds"))
	attach(stage_data$globals)
	res <- do.call(fn, args)
	storage_write(bootstrap$storage, c(bootstrap$stage_storage_prefix, bootstrap$stage_id, "result.rds"), res)
}
