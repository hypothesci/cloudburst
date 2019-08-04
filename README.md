# cloudburst
Cloudburst brings cloud compute resources to your R project, allowing data scientists and engineers to build complex data processing pipelines with whatever resources are required.

There's no requirement to pre-provision clusters of machines, or configure auto-scaling to keep costs down for variable workloads; compute resources are spun up exactly as necessary, and stopped once their work is done.

You can split your work up into stages that look just like functions, flowing data through your process, and Cloudburst will automatically wire them up into a DAG for optimal parallel execution where possible.

Currently, Amazon Web Services (AWS) is the only supported provider, leveraging Fargate/ECS for compute and S3 for transient storage.

## Demo
```r
library(magrittr)

# you need to initialise a provider; we'll use AWS for this example
cloudburst::init_aws(
   # s3 is the default storage backend for AWS; we need this to marshal results between stages
  storage_bucket = "my-s3-bucket",
   # let's indicate which cluster we're running in and which subnets to use for ECS
  compute_cluster = "data",
  compute_subnets = c("subnet-abcdef", "subnet-ghijkl"),
  compute_assign_public_ip = T,
  # you need a Docker image, see the "Managing Dependencies" section below
  compute_image = "12345.dkr.ecr.us-east-1.amazonaws.com/my-cloudburst-image:latest",
  # the execution role can just be the default ECS execution role for your account
  compute_execution_role = "arn:aws:iam::12345.role/ecsTaskExecutionRole",
  # the task role gives your R code access to any AWS services it might need, like S3
  compute_task_role = "arn:aws:iam::12345:role/my-cloudburst-role"
)

# variables are transparently made available to stages as needed
num_observations <- 1000

# let's pretend we've got two stages that build large datasets somehow
get_data_x <- cloudburst::stage(cpu = 1024, memory = 2048, function() {
  data.frame(x = runif(num_observations))
})

get_data_y <- cloudburst::stage(cpu = 1024, memory = 2048, function() {
  data.frame(y = rnorm(num_observations))
})

# and a third stage that does some "intensive" computation over the two
build_model <- cloudburst::stage(cpu = 2048, memory = 4096, function(data_x, data_y) {
  data <- cbind(data_x, data_y)
  lm(y ~ x, data)
})

# stages are called just like regular functions
# we just have to call 'execute' at the end to bring the result back to R
build_model(get_data_x(), get_data_y()) %>%
  cloudburst::execute("super-complex-pipeline") -> result
```

This would spin up two tasks to run `get_data_x` and `get_data_y` in parallel, each with 1 vCPU and 2GB of RAM, and then a third task on completion of both those stages to build the linear model, with 2 vCPUs and 4GB of RAM.

On completion, if we were to inspect `result`, we'd see a standard linear model, just as we'd expect from running `lm` in a normal R process.

## Managing Dependencies
Most projects aren't just base R; they require packages installed from CRAN or elsewhere, so we need to make sure that those same packages are available, no matter where your R code is being executed. To do this, we can use [Packrat](https://rstudio.github.io/packrat) to track our dependencies, and [Docker](https://www.docker.com) to bundle up an R environment with all the same packages as you're using locally.

We can tie this all together and automate it using the [containr](https://github.com/hypothesci/containr) package.

You can use `containr::docker_deploy` to automatically create a Docker image based on your installed version of R with all your Packrat dependencies, and push it to a Docker repository of your choosing. For example, with the example above in which we used AWS ECR to store our container, we could just run `containr::docker_deploy("12345.dkr.ecr.us-east-1.amazonaws.com/my-cloudburst-image:latest")` from inside our project to bundle up all our required packages alongside the correct version of R.
