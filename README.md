# cloudburst
Cloud-based distributed computing for R.

# Plan

## Cloud infra steps
- [ ] Register base task def with Packrat setup - needs Dockerfile + allowing for custom OS-level deps
  - Should be parameterised per-branch to allow for devs testing upgrades etc
- [ ] Copy project code to S3
  - Need to figure out structure here, how do we differentiate pipeline entrypoints vs stages?
- [ ] Possibly also identify lexically available globals and store in S3?
- [ ] Run task def on ECS/Fargate with customisable spec for a particular pipeline stage
- [ ] Stages should be isolated and communicate only via args and their return values
- [ ] Remote stages should read their args from and writes their return values to S3

## Local dev steps
- [ ] Define a DAG for pipeline stages
- [ ] Easy process for rebuilding the base task def
- [ ] Detect stages with no change to not rerun unnecessarily
- [ ] Need to make sure region propagates through without ~/.Renviron

## Example DAG
```r
# nullary stages running remotely
get_data_first_half <- cloudburst::remote_stage(function() { ... }, cpu = 1024, memory = 1024)
get_data_second_half <- cloudburst::remote_stage(function() { ... }, cpu = 1024, memory = 1024)

# binary stage running remotely
process_data <- cloudburst::remote_stage(function(data1, data2) { ... }, cpu = 4096, memory = 8192)

# unary stage running locally
render_data <- cloudburst::local_stage(function(processed_data) { ... })

# wire up the stages
dag <- process_data(get_data_first_half(), get_data_second_half()) %>%
  render_data()

# execute the DAG
final_results <- cloudburst::run("demoProject", dag)
```
