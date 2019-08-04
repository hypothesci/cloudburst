
#' Title
#'
#' @return
#' @export
#'
#' @examples
runner <- function() {
	print("runner init")

	bootstrap <- unserialize(base64enc::base64decode(Sys.getenv("CLOUDBURST_BOOTSTRAP")))

	print("loaded bootstrap data")

	lapply(bootstrap$loaded_packages, library, character.only = T)

	print("restored packages")

	args <- lapply(bootstrap$dependency_ids, function(i) storage_read(bootstrap$storage, c(bootstrap$stage_storage_prefix, i, "result.rds")))

	print("loaded dependency results for args")

	stage_data <- storage_read(bootstrap$storage, c(bootstrap$stage_storage_prefix, bootstrap$stage_id, "code.rds"))

	print("loaded own code")

	attach(stage_data$globals)

	print("restored globals")

	res <- do.call(stage_data$fn, args)

	print("function eval complete")

	storage_write(bootstrap$storage, c(bootstrap$stage_storage_prefix, bootstrap$stage_id, "result.rds"), res)

	print("result stored")
}
