
compute_prepare_run <- function(compute, name) {
	UseMethod("compute_prepare_run", compute)
}

compute_run_stage <- function(stage, name, bootstrap) {
	UseMethod("compute_run_stage", stage)
}

compute_poll_stage <- function(stage, handle) {
	UseMethod("compute_poll_stage", stage)
}

#' Title
#'
#' @param final_stage
#' @param storage
#' @param name
#'
#' @return
#' @export
#'
#' @examples
execute <- function(final_stage, name, storage = default_storage_backend(), compute = default_compute_backend()) {
	# FIXME: this should be run elsewhere, no need to spam task defs
	compute_prepare_run(compute, name)

	all_stages <- list(final_stage)

	add_stages <- function(stage) {
		all_stages <<- c(all_stages, unname(stage$args))
		lapply(stage$args, add_stages)
	}

	add_stages(final_stage)

	stages <- unique(all_stages)
	edges <- c()

	# FIXME: this is awful, but works
	find_stage_index <- function(stage) which(sapply(stages, function(s) identical(s, stage)))

	for (stage in stages) {
		to <- find_stage_index(stage)
		for (parent in stage$args) {
			from <- find_stage_index(parent)
			edges <- c(edges, from, to)
		}
	}

	graph <- igraph::make_graph(edges)
	graph <- igraph::set_vertex_attr(graph, "name", value = sapply(stages, function(s) s$name))

	if (!igraph::is_dag(graph)) {
		stop("plan contains cycles")
	}

	run_start <- Sys.time()
	run_id <- paste0(format(run_start, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), "--", uuid::UUIDgenerate(use.time = F))
	stage_storage_prefix <- c(name, run_id, "stages")

	bootstrap_base <- list(
		storage = storage,
		stage_storage_prefix = stage_storage_prefix
	)

	for (i in 1:length(stages)) {
		stage <- stages[[i]]
		storage_write(storage, c(stage_storage_prefix, i, "code.rds"), stage$fn)
		storage_write(storage, c(stage_storage_prefix, i, paste0(".name=", stage$name)), NULL)
	}

	dependencies_by_stage <- sapply(igraph::V(graph), function(x) igraph::neighbors(graph, x, mode = "in"))
	dependents_by_stage <- sapply(igraph::V(graph), function(x) igraph::neighbors(graph, x, mode = "out"))
	next_stages <- which(sapply(dependencies_by_stage, length) == 0)
	completed <- rep(F, length(all_stages))
	executing <- c()
	handles <- list()

	while (length(next_stages) > 0 | length(executing) > 0) {
		newly_ready <- c()
		for (stage_index in next_stages) {
			dependencies <- dependencies_by_stage[[stage_index]]

			if (all(completed[dependencies])) {
				print(paste0("all dependencies completed for stage: ", stage_index))
				newly_ready <- c(newly_ready, stage_index)
			}
		}

		for (stage_index in newly_ready) {
			print(paste0("starting stage: ", stage_index))

			stage <- stages[[stage_index]]

			stage_bootstrap <- bootstrap_base
			stage_bootstrap$stage_id <- stage_index
			stage_bootstrap$dependency_ids <- sapply(stage$args, function(a) find_stage_index(a))

			stage_bootstrap_encoded <- base64enc::base64encode(serialize(stage_bootstrap, connection = NULL))
			handles[[stage_index]] <- compute_run_stage(stage, name, stage_bootstrap_encoded)

			print("handle state:")
			print(handles)
		}

		executing <- unique(c(executing, newly_ready))
		next_stages <- next_stages[!next_stages %in% newly_ready]

		newly_completed <- c()
		for (stage_index in executing) {
			print(paste0("checking on stage: ", stage_index))

			status <- compute_poll_stage(stages[[stage_index]], handles[[stage_index]])

			if (status == "complete") {
				newly_completed <- c(newly_completed, stage_index)
			} else if (status == "failed") {
				stop(paste0("stage failed: ", stage_index))
			} else if (status != "executing") {
				stop(paste0("unknown status for stage: ", stage_index))
			}
		}

		for (stage_index in newly_completed) {
			print(paste0("stage complete: ", stage_index))
			completed[[stage_index]] <- T
		}

		completed[newly_completed] <- T
		next_stages <- unique(c(next_stages, unlist(dependents_by_stage[newly_completed])))
		executing <- executing[!executing %in% newly_completed]

		print("step complete")

		# FIXME: am I really ok shipping this? is this even legal?
		Sys.sleep(1)
	}
}
