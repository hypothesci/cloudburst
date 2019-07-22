
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
compute_ecs <- function(project, cluster, image, execution_role, subnets) {
	structure(class = "ecs_compute",
		list(
			project = project,
			cluster = cluster,
			image = image,
			execution_role = execution_role,
			subnets = subnets
		)
	)
}

compute_prepare_run.ecs_compute <- function(compute, name) {
	ecs_register_task_definition(compute$project$region, paste0("cloudburst-", name), compute$image, compute$execution_role)
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

compute_run_stage.ecs_stage <- function(stage, name, bootstrap) {
	res <- ecs_run_task(
		region = stage$backend$project$region,
		family = paste0("cloudburst-", name),
		cluster = stage$backend$cluster,
		subnets = stage$backend$subnets,
		assign_public_ip = T, # FIXME: should expose public IPs as a config depending on subnet routing
		cpu = stage$cpu,
		memory = stage$memory
	)

	res$tasks$taskArn
}

compute_poll_stage.ecs_stage <- function(stage, handle) {
	res <- ecs_describe_tasks(
		region = stage$backend$project$region,
		cluster = stage$backend$cluster,
		tasks = handle
	)

	status <- res$tasks$lastStatus

	if (status %in% c("PROVISIONING", "PENDING", "ACTIVATING", "RUNNING", "DEACTIVATING", "STOPPING", "DEPROVISIONING")) {
		"executing"
	} else if (status == "STOPPED") {
		container <- res$tasks$containers[[1]]
		if (container$exitCode == 0) "complete" else "failed"
	} else {
		stop(paste0("unrecognised ECS task status: ", status))
	}
}
