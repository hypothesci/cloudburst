
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
compute_ecs <- function(project, cluster, image, execution_role, subnets, task_role, assign_public_ip) {
	structure(class = "ecs_compute",
		list(
			project = project,
			cluster = cluster,
			image = image,
			execution_role = execution_role,
			subnets = subnets,
			task_role = task_role,
			assign_public_ip = assign_public_ip
		)
	)
}

ecs_task_def_name <- function(name, cpu, memory) {
	paste0("cloudburst-", name, "-c", cpu, "-m", memory)
}

compute_prepare_run.ecs_compute <- function(compute, name, stages) {
	resource_requirements <- t(sapply(stages, function(s) s[c("cpu", "memory")]))
	resource_combinations <- unique(as.data.frame(resource_requirements))

	apply(resource_combinations, 1, function(r) {
		aws.ecs::register_task_definition(compute$project$region, ecs_task_def_name(name, r[[1]], r[[2]]),
			compute$image, compute$execution_role, compute$task_role, cpu = r[[1]], memory = r[[2]],
			log_group = "cloudburst", log_stream_prefix = "cloudburst")
	})
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
stage.ecs_compute <- function(fn, cpu, memory, backend = default_compute_backend()) {
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
	res <- aws.ecs::run_task(
		region = stage$backend$project$region,
		family = ecs_task_def_name(name, stage$cpu, stage$memory),
		cluster = stage$backend$cluster,
		subnets = stage$backend$subnets,
		assign_public_ip = stage$backend$assign_public_ip,
		environment = data.frame(name = "CLOUDBURST_BOOTSTRAP", value = bootstrap),
		command = c("Rscript", "-e", "cloudburst::runner()"),
		started_by = "cloudburst"
	)

	res$tasks$taskArn
}

compute_poll_stage.ecs_stage <- function(stage, handle) {
	res <- aws.ecs::describe_tasks(
		region = stage$backend$project$region,
		cluster = stage$backend$cluster,
		tasks = handle
	)

	status <- res$tasks$lastStatus
	container <- res$tasks$containers[[1]]

	if (!is.null(container$exitCode)) {
		if (container$exitCode == 0) "complete" else "failed"
	} else {
		"executing"
	}
}
