library(magrittr)

cloudburst::init_aws(
	storage_bucket = "hypothesci-cloudburst",
	compute_cluster = "dev"
)

get_data_1 <- cloudburst::exec_ecs(cpu = 1024, memory = 1024, function() {
	data.frame(x = runif(100), y = rnorm(100))
})

get_data_2 <- cloudburst::exec_ecs(cpu = 1024, memory = 1024, function() {
	data.frame(x = rnorm(100), y = runif(100))
})

process_data <- cloudburst::exec_local(function(data1, data2) {
	rbind(data1, data2)
})

finalise_data <- cloudburst::exec_local(function(data) {
	lm(y ~ x, data)
})

process_data(get_data_1(), get_data_2()) %>%
	finalise_data() %>%
	cloudburst::execute("demo") -> result
