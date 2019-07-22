
#' Title
#'
#' @param specs
#' @param region
#' @param creds
#' @param project
#'
#' @return
#' @export
#'
#' @examples
compute_ecs <- function(project, cluster) {
	structure(list(project = project, cluster = cluster), class = "ecs_compute")
}

#' Title
#'
#' @param fn
#' @param cpu
#' @param memory
#' @param backend
#'
#' @return
#' @export
#'
#' @examples
exec_ecs <- function(fn, cpu, memory, backend = default_compute_backend()) {
	function(...) {
		structure(class = "ecs_stage",
			list(
				name = as.character(match.call()[[1]]),
				backend = backend,
				fn = fn,
				args = list(...),
				cpu = cpu,
				memory = memory
			)
		)
	}
}
