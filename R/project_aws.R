
#' Title
#'
#' @param region
#'
#' @return
#' @export
#'
#' @examples
project_aws <- function(region = aws.signature::locate_credentials()$region) {
	structure(list(region = region), class = "aws_project")
}

#' Title
#'
#' @param storage_bucket
#' @param region
#' @param compute_cluster
#'
#' @return
#' @export
#'
#' @examples
init_aws <- function(storage_bucket, compute_cluster, compute_image, compute_execution_role, compute_subnets,
	region = aws.signature::locate_credentials()$region) {
	project <- project_aws(region)
	register_compute_backend(compute_ecs(project, compute_cluster, compute_image, compute_execution_role, compute_subnets))
	register_storage_backend(storage_s3(project, storage_bucket))
	invisible(project)
}
