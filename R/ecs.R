
ecs_http <- function(region, verb, operation, body = NULL) {
	creds <- aws.signature::locate_credentials(region = region)

	if (!is.null(body)) {
		body_json <- jsonlite::toJSON(body)
		print(body_json)
	}

	host <- paste0("ecs.", creds$region, ".amazonaws.com")
	date <- format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")
	headers <- list(
		"X-Amz-Target" = paste0("AmazonEC2ContainerServiceV20141113.", operation),
		"X-Amz-Date" = date,
		"Content-Type" = "application/x-amz-json-1.1"
	)

	sig <- aws.signature::signature_v4_auth(
		datetime = date,
		region = creds$region,
		service = "ecs",
		verb = verb,
		action = "/",
		canonical_headers = list("Host" = host, "X-Amz-Date" = date),
		request_body = body_json,
		key = creds$key,
		secret = creds$secret,
		session_token = creds$session_token
	)

	headers[["Authorization"]] <- sig$SignatureHeader

	client <- crul::HttpClient$new(url = paste0("https://", host), headers = headers)
	res <- client$verb(verb, path = "/", body = body_json)

	print(res$parse())

	if (res$status_code != 200) {
		status <- res$status_http()
		stop(paste0(operation, " failed, ", status$message, "(", status$status_code, "): ", res$parse()))
	}

	jsonlite::fromJSON(res$parse(), flatten = T)
}

ecs_run_task <- function(region, family, cluster, subnets, security_groups = list(), assign_public_ip = F,
	revision = NULL, count = 1, cpu = 2048, memory = 4096, environment = list()) {
	task_def <- if (!is.null(revision)) paste0(family, ":", revision) else family

	ecs_http(region, "POST", "RunTask", body = list(
		cluster = jsonlite::unbox(cluster),
		count = jsonlite::unbox(count),
		launchType = jsonlite::unbox("FARGATE"),
		taskDefinition = jsonlite::unbox(task_def),
		overrides = list(
			containerOverrides = list(list(
				name = jsonlite::unbox(family),
				cpu = jsonlite::unbox(cpu),
				memory = jsonlite::unbox(memory),
				environment = environment
			))
		),
		networkConfiguration = list(
			awsvpcConfiguration = list(
				assignPublicIp = jsonlite::unbox(ifelse(assign_public_ip, "ENABLED", "DISABLED")),
				securityGroups = security_groups,
				subnets = subnets
			)
		),
		startedBy = jsonlite::unbox("cloudburst")
	))
}

ecs_describe_tasks <- function(region, tasks, cluster) {
	ecs_http(region, "POST", "DescribeTasks", body = list(
		tasks = tasks,
		cluster = jsonlite::unbox(cluster)
	))
}

ecs_register_task_definition <- function(region, family, image, execution_role, task_role, cpu = 2048, memory = 4096) {
	ecs_http(region, "POST", "RegisterTaskDefinition", body = list(
		networkMode = jsonlite::unbox("awsvpc"),
		containerDefinitions = list(list(
			name = jsonlite::unbox(family),
			image = jsonlite::unbox(image),
			essential = jsonlite::unbox(T),
			cpu = jsonlite::unbox(cpu),
			memory = jsonlite::unbox(memory)
		)),
		family = jsonlite::unbox(family),
		requiresCompatibilities = "FARGATE",
		compatibilities = "FARGATE",
		cpu = jsonlite::unbox(as.character(cpu)),
		memory = jsonlite::unbox(as.character(memory)),
		executionRoleArn = jsonlite::unbox(execution_role),
		taskRoleArn = jsonlite::unbox(task_role)
	))
}
