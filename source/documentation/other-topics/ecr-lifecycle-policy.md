### ECR Lifecycle Policy

#### Overview
ECR repositories created for use in the Cloud Platform will have a default lifecycle policy applied.

Due to some applications having a constant rate of images being pushed to their ECR repo, we found that the AWS limit of 1000 images was being hit by some teams.

After consulting with application teams, we decided to implement a lifecycle policy of *40 images* per ECR repo.

If you feel that you have a need to archive more than the last 40 images, please contact the Cloud Platform team, who can adjust or remove the lifecycle policy.
