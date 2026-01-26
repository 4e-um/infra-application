# =============================================================================
# Cloud Workflows - Batch Job Synchronous Executor
# =============================================================================
# Cloud Run Job의 비동기 실행을 동기(완료 대기)로 변환
# Cloud Tasks와 조합하여 완전한 직렬 Batch 실행 보장

resource "google_workflows_workflow" "batch_executor" {
  name            = "${var.project_name}-batch-executor"
  project         = local.project_id
  region          = local.region
  service_account = google_service_account.app.email
  description     = "Executes Cloud Run Job and waits for completion"

  labels = local.common_labels

  source_contents = <<-YAML
main:
  params: [input]
  steps:
    - init:
        assign:
          - project: '$${sys.get_env("GOOGLE_CLOUD_PROJECT_ID")}'
          - location: "${local.region}"
          - jobName: "${var.project_name}-batch-core"
          - jobArgs: '$${input.args}'
          - maxWaitTime: ${var.workflow_job_timeout}
          - pollInterval: ${var.workflow_poll_interval}

    - runJob:
        call: googleapis.run.v2.projects.locations.jobs.run
        args:
          name: '$${"projects/" + project + "/locations/" + location + "/jobs/" + jobName}'
          body:
            overrides:
              containerOverrides:
                - args: '$${jobArgs}'
        result: execution

    - extractExecutionName:
        assign:
          - executionName: '$${execution.metadata.name}'

    - waitForCompletion:
        call: sys.sleep
        args:
          seconds: '$${pollInterval}'

    - checkStatus:
        call: googleapis.run.v2.projects.locations.jobs.executions.get
        args:
          name: '$${executionName}'
        result: executionStatus

    - evaluateStatus:
        switch:
          - condition: '$${executionStatus.completionTime != null}'
            next: checkResult
          - condition: true
            next: waitForCompletion

    - checkResult:
        switch:
          - condition: '$${executionStatus.succeededCount > 0}'
            return:
              status: "SUCCEEDED"
              executionName: '$${executionName}'
          - condition: true
            raise:
              code: "JOB_FAILED"
              message: '$${"Job execution failed: " + executionName}'
YAML

  depends_on = [
    google_project_iam_member.app_workflows_invoker
  ]
}
