# CI/CD Integration Guide

## GitHub Actions

### Basic Workflow
```yaml
name: 12-Factor Compliance Check
on: [push, pull_request]

jobs:
  compliance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install 12-Factor Reviewer
        run: |
          git clone https://github.com/phdsystems/12-factor-reviewer.git
          chmod +x 12-factor-reviewer/bin/twelve-factor-reviewer

      - name: Run Assessment
        run: ./12-factor-reviewer/bin/twelve-factor-reviewer . --strict
```

### Advanced Workflow with Reporting
```yaml
name: 12-Factor Compliance Report
on: [push, pull_request]

jobs:
  compliance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install 12-Factor Reviewer
        run: |
          git clone https://github.com/phdsystems/12-factor-reviewer.git
          chmod +x 12-factor-reviewer/bin/twelve-factor-reviewer

      - name: Run Assessment
        id: assessment
        run: |
          ./12-factor-reviewer/bin/twelve-factor-reviewer . -f json > compliance.json
          score=$(jq '.percentage' compliance.json)
          echo "score=$score" >> $GITHUB_OUTPUT
          echo "## 12-Factor Compliance: ${score}%" >> $GITHUB_STEP_SUMMARY

      - name: Upload Report
        uses: actions/upload-artifact@v3
        with:
          name: compliance-report
          path: compliance.json

      - name: Comment on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const score = ${{ steps.assessment.outputs.score }};
            const emoji = score >= 80 ? '✅' : score >= 60 ? '⚠️' : '❌';
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `${emoji} 12-Factor Compliance: ${score}%`
            })
```

## GitLab CI

### Basic Pipeline
```yaml
12factor-compliance:
  stage: test
  script:
    - git clone https://github.com/phdsystems/12-factor-reviewer.git
    - chmod +x 12-factor-reviewer/bin/twelve-factor-reviewer
    - ./12-factor-reviewer/bin/twelve-factor-reviewer . --strict
```

### Advanced Pipeline with Artifacts
```yaml
stages:
  - test
  - report

12factor-assessment:
  stage: test
  script:
    - git clone https://github.com/phdsystems/12-factor-reviewer.git
    - chmod +x 12-factor-reviewer/bin/twelve-factor-reviewer
    - ./12-factor-reviewer/bin/twelve-factor-reviewer . -f json > compliance.json
    - ./12-factor-reviewer/bin/twelve-factor-reviewer . -f markdown > compliance.md
  artifacts:
    reports:
      junit: compliance.json
    paths:
      - compliance.json
      - compliance.md
    expire_in: 30 days

compliance-report:
  stage: report
  dependencies:
    - 12factor-assessment
  script:
    - score=$(jq '.percentage' compliance.json)
    - echo "12-Factor Compliance Score: ${score}%"
    - if [ "$score" -lt 80 ]; then exit 1; fi
```

## Jenkins

### Jenkinsfile (Declarative Pipeline)
```groovy
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('12-Factor Assessment') {
            steps {
                sh '''
                    git clone https://github.com/phdsystems/12-factor-reviewer.git
                    chmod +x 12-factor-reviewer/bin/twelve-factor-reviewer
                    ./12-factor-reviewer/bin/twelve-factor-reviewer . -f json > compliance.json
                '''
            }
        }

        stage('Publish Report') {
            steps {
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: '.',
                    reportFiles: 'compliance.json',
                    reportName: '12-Factor Compliance Report'
                ])
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    def compliance = readJSON file: 'compliance.json'
                    if (compliance.percentage < 80) {
                        error("12-Factor compliance is below 80%: ${compliance.percentage}%")
                    }
                }
            }
        }
    }
}
```

## CircleCI

### .circleci/config.yml
```yaml
version: 2.1

jobs:
  compliance-check:
    docker:
      - image: cimg/base:stable
    steps:
      - checkout
      - run:
          name: Install 12-Factor Reviewer
          command: |
            git clone https://github.com/phdsystems/12-factor-reviewer.git
            chmod +x 12-factor-reviewer/bin/twelve-factor-reviewer
      - run:
          name: Run Assessment
          command: |
            ./12-factor-reviewer/bin/twelve-factor-reviewer . -f json > compliance.json
            cat compliance.json | jq .
      - store_artifacts:
          path: compliance.json
          destination: compliance-report

workflows:
  version: 2
  test:
    jobs:
      - compliance-check
```

## Azure DevOps

### azure-pipelines.yml
```yaml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: Bash@3
  displayName: 'Install 12-Factor Reviewer'
  inputs:
    targetType: 'inline'
    script: |
      git clone https://github.com/phdsystems/12-factor-reviewer.git
      chmod +x 12-factor-reviewer/bin/twelve-factor-reviewer

- task: Bash@3
  displayName: 'Run 12-Factor Assessment'
  inputs:
    targetType: 'inline'
    script: |
      ./12-factor-reviewer/bin/twelve-factor-reviewer . -f json > $(Build.ArtifactStagingDirectory)/compliance.json
      score=$(jq '.percentage' $(Build.ArtifactStagingDirectory)/compliance.json)
      echo "##vso[task.setvariable variable=complianceScore]$score"
      echo "12-Factor Compliance: ${score}%"

- task: PublishBuildArtifacts@1
  inputs:
    PathtoPublish: '$(Build.ArtifactStagingDirectory)/compliance.json'
    ArtifactName: 'compliance-report'

- task: Bash@3
  displayName: 'Quality Gate'
  inputs:
    targetType: 'inline'
    script: |
      if [ $(complianceScore) -lt 80 ]; then
        echo "##vso[task.logissue type=error]12-Factor compliance is below 80%"
        exit 1
      fi
```

## Docker-based CI

For any CI system with Docker support:

```yaml
compliance:
  image: alpine:latest
  script:
    - apk add --no-cache git bash
    - git clone https://github.com/phdsystems/12-factor-reviewer.git
    - ./12-factor-reviewer/bin/twelve-factor-reviewer . --strict
```

## Exit Codes

The tool returns different exit codes for CI/CD integration:

- **0**: Success, compliance meets requirements
- **1**: Failure, compliance below threshold (in strict mode)
- **2**: Error in execution

## Best Practices

1. **Use Strict Mode**: Always use `--strict` in CI/CD pipelines
2. **Store Reports**: Archive JSON/Markdown reports as build artifacts
3. **Track Trends**: Compare scores over time to track improvements
4. **Set Thresholds**: Define minimum compliance levels for different branches
5. **Automate Notifications**: Send alerts when compliance drops below threshold