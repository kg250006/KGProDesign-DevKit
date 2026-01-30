#Requires -Version 5.1
<#
.SYNOPSIS
    PRP Batch Runner - Execute multiple PRPs sequentially with process isolation
.DESCRIPTION
    Executes multiple PRPs in sequence, each in its own separate process.
    This ensures complete isolation between PRPs - no context bleed.
.PARAMETER PrpFiles
    One or more PRP files to execute sequentially
.PARAMETER BatchFile
    Path to a file containing PRP paths (one per line)
.PARAMETER MaxRetries
    Max retry attempts per task within each PRP (default: 3)
.PARAMETER Timeout
    Timeout in seconds per task (default: 300)
.PARAMETER DryRun
    Test mode - simulate execution without running Claude
.PARAMETER NoSafety
    Disable safety mode (use standard permissions)
.PARAMETER SkipValidation
    Skip acceptance criteria validation
.EXAMPLE
    .\prp-batch-runner.ps1 PRPs\step1.md PRPs\step2.md PRPs\step3.md
.EXAMPLE
    .\prp-batch-runner.ps1 -BatchFile PRPs\release-1.0.txt
.EXAMPLE
    Get-ChildItem PRPs\*.md | .\prp-batch-runner.ps1 -Timeout 600
#>

param(
    [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ValueFromRemainingArguments=$true)]
    [Alias("FullName")]
    [string[]]$PrpFiles,

    [Alias("batch-file")]
    [string]$BatchFile,

    [Alias("max-retries")]
    [int]$MaxRetries = 3,

    [int]$Timeout = 300,

    [int]$Iterations = 2,

    [Alias("dry-run")]
    [switch]$DryRun,

    [Alias("no-safety")]
    [switch]$NoSafety,

    [Alias("skip-validation")]
    [switch]$SkipValidation,

    [Alias("h")]
    [switch]$Help
)

begin {
    $ErrorActionPreference = "Stop"
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $PluginRoot = Split-Path -Parent $ScriptDir

    # Collect all PRP files from pipeline
    $AllPrpFiles = @()
}

process {
    if ($PrpFiles) {
        $AllPrpFiles += $PrpFiles
    }
}

end {
    # Show help
    if ($Help) {
        $helpText = @"
PRP Batch Runner - Execute multiple PRPs sequentially with process isolation

USAGE:
  .\prp-batch-runner.ps1 <prp1.md> <prp2.md> ... [OPTIONS]
  .\prp-batch-runner.ps1 -BatchFile PRPs\batch.txt [OPTIONS]
  Get-ChildItem PRPs\*.md | .\prp-batch-runner.ps1 [OPTIONS]

ARGUMENTS:
  prp1.md prp2.md ...   One or more PRP files to execute sequentially

OPTIONS:
  -BatchFile FILE       Read PRP paths from a file (one per line)
  -MaxRetries N         Max retry attempts per task within each PRP (default: 3)
  -Timeout M            Timeout in seconds per task (default: 300)
  -Iterations N         Min successful iterations per task (default: 2)
  -DryRun               Test mode - simulate execution without running Claude
  -NoSafety             Disable safety mode (use standard permissions)
  -SkipValidation       Skip acceptance criteria validation
  -Help, -h             Show this help message

DESCRIPTION:
  Executes multiple PRPs sequentially, each in its own separate process.

  The workflow is:
  1. Parse list of PRPs from arguments, pipeline, or batch file
  2. For each PRP:
     a. Spawn new PowerShell process running prp-orchestrator.ps1
     b. Wait for process to complete
     c. Capture exit status and log results
     d. Brief pause, then proceed to next PRP
  3. Aggregate results and generate summary

  This ensures complete isolation between PRPs - no context bleed.

BATCH FILE FORMAT:
  # Comments start with #
  PRPs\feature-auth.md
  PRPs\feature-payments.md
  PRPs\refactor-db.md

EXAMPLE:
  # Execute three PRPs in sequence
  .\prp-batch-runner.ps1 PRPs\step1.md PRPs\step2.md PRPs\step3.md

  # Use a batch file
  .\prp-batch-runner.ps1 -BatchFile PRPs\release-1.0.txt

  # Use wildcard with PowerShell
  Get-ChildItem PRPs\*.md | .\prp-batch-runner.ps1 -Timeout 600

OUTPUT:
  Batch progress: .claude\prp-batch-progress.md
  Individual PRP logs: .claude\prp-progress.md (overwritten per PRP)

"@
        Write-Output $helpText
        exit 0
    }

    # Load PRPs from batch file if specified
    if ($BatchFile) {
        if (-not (Test-Path $BatchFile)) {
            Write-Host "Error: Batch file not found: $BatchFile" -ForegroundColor Red
            exit 1
        }

        $BatchContent = Get-Content -Path $BatchFile
        foreach ($line in $BatchContent) {
            $line = $line.Trim()
            # Skip empty lines and comments
            if ($line -and -not $line.StartsWith("#")) {
                $AllPrpFiles += $line
            }
        }
    }

    # Validate we have PRPs to run
    if ($AllPrpFiles.Count -eq 0) {
        Write-Host "Error: No PRP files specified" -ForegroundColor Red
        Write-Host "Usage: .\prp-batch-runner.ps1 <prp1.md> <prp2.md> ... [OPTIONS]"
        Write-Host "Run with -Help for more information."
        exit 1
    }

    # Validate all PRP files exist
    foreach ($prp in $AllPrpFiles) {
        if (-not (Test-Path $prp)) {
            Write-Host "Error: PRP file not found: $prp" -ForegroundColor Red
            exit 1
        }
    }

    # Create .claude directory
    $claudeDir = ".claude"
    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    }

    # Progress file for batch execution
    $BatchProgress = ".claude\prp-batch-progress.md"
    $Timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    # Initialize batch progress file
    $initContent = @"
# PRP Batch Execution Progress

## Batch Info
- Started: $Timestamp
- Total PRPs: $($AllPrpFiles.Count)
- Max Retries: $MaxRetries
- Timeout: ${Timeout}s per task
- Iterations: $Iterations per task

## PRPs to Execute
"@
    Set-Content -Path $BatchProgress -Value $initContent

    foreach ($prp in $AllPrpFiles) {
        Add-Content -Path $BatchProgress -Value "- [ ] $prp"
    }

    Add-Content -Path $BatchProgress -Value ""
    Add-Content -Path $BatchProgress -Value "## Execution Log"
    Add-Content -Path $BatchProgress -Value ""

    # Banner
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host "  PRP BATCH RUNNER" -ForegroundColor Blue
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host "Total PRPs: $($AllPrpFiles.Count)"
    Write-Host "Max Retries: $MaxRetries"
    Write-Host "Timeout: ${Timeout}s per task"
    Write-Host "Iterations: $Iterations (per task)"
    if ($DryRun) {
        Write-Host "Mode: DRY RUN" -ForegroundColor Yellow
    }
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host ""

    # Stats
    $BatchSucceeded = 0
    $BatchFailed = 0

    # Build orchestrator arguments
    $OrchestratorScript = Join-Path $ScriptDir "prp-orchestrator.ps1"
    $BaseArgs = @("-Iterations", $Iterations, "-MaxRetries", $MaxRetries, "-Timeout", $Timeout)
    if ($DryRun) { $BaseArgs += "-DryRun" }
    if ($NoSafety) { $BaseArgs += "-NoSafety" }
    if ($SkipValidation) { $BaseArgs += "-SkipValidation" }

    # Main batch loop
    for ($i = 0; $i -lt $AllPrpFiles.Count; $i++) {
        $PrpFile = $AllPrpFiles[$i]
        $PrpNum = $i + 1

        Write-Host ""
        Write-Host "==========================================" -ForegroundColor Blue
        Write-Host "  PRP $PrpNum / $($AllPrpFiles.Count)" -ForegroundColor Blue
        Write-Host "  $PrpFile" -ForegroundColor Blue
        Write-Host "==========================================" -ForegroundColor Blue

        # Log to batch progress
        $StartTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        Add-Content -Path $BatchProgress -Value "### PRP $PrpNum`: $PrpFile"
        Add-Content -Path $BatchProgress -Value "- Started: $StartTime"

        # Build full arguments for this PRP
        $FullArgs = @($PrpFile) + $BaseArgs

        Write-Host "Starting PRP execution in separate process..."
        Write-Host "(This window will wait for completion)"

        try {
            # Start the orchestrator in a new console window and wait for it
            # Using -Wait ensures we block until completion
            # Using -PassThru gives us the process object to check exit code
            $processArgs = @{
                FilePath = "powershell.exe"
                ArgumentList = @("-ExecutionPolicy", "Bypass", "-File", $OrchestratorScript) + $FullArgs
                Wait = $true
                PassThru = $true
                NoNewWindow = $false  # Open in new window for visibility
            }

            $process = Start-Process @processArgs

            $ExitCode = $process.ExitCode
            $EndTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

            # Parse the orchestrator's progress file for accurate task counts
            # This provides ground truth regardless of exit code
            $PrpProgressFile = ".claude\prp-progress.md"
            $TasksSucceeded = 0
            $TasksFailed = 0
            $TotalTasks = 0

            if (Test-Path $PrpProgressFile) {
                $progressContent = Get-Content -Path $PrpProgressFile -Raw
                # Extract task counts from summary section
                if ($progressContent -match 'Tasks Succeeded: (\d+) / (\d+)') {
                    $TasksSucceeded = [int]$Matches[1]
                    $TotalTasks = [int]$Matches[2]
                }
                if ($progressContent -match 'Tasks Failed: (\d+)') {
                    $TasksFailed = [int]$Matches[1]
                }
                # Fallback: count FULLY COMPLETE lines if summary not found
                if ($TotalTasks -eq 0) {
                    $TasksSucceeded = ([regex]::Matches($progressContent, 'FULLY COMPLETE')).Count
                    $TasksFailed = ([regex]::Matches($progressContent, 'FAILED after')).Count
                    $TotalTasks = $TasksSucceeded + $TasksFailed
                }
            }

            # Determine actual success based on orchestrator results (not just exit code)
            # A PRP succeeds if: exit code is 0 OR (tasks succeeded > 0 AND tasks failed == 0)
            $PrpActuallySucceeded = ($ExitCode -eq 0) -or (($TasksSucceeded -gt 0) -and ($TasksFailed -eq 0))

            if ($PrpActuallySucceeded) {
                Write-Host "PRP $PrpNum`: SUCCESS" -ForegroundColor Green
                if ($TotalTasks -gt 0) {
                    Write-Host "  Tasks: $TasksSucceeded/$TotalTasks succeeded"
                }
                Add-Content -Path $BatchProgress -Value "- Completed: $EndTime"
                Add-Content -Path $BatchProgress -Value "- Status: SUCCESS"
                if ($TotalTasks -gt 0) {
                    Add-Content -Path $BatchProgress -Value "- Tasks: $TasksSucceeded/$TotalTasks succeeded"
                }
                $BatchSucceeded++
                # Update checkbox to mark as complete
                $content = Get-Content -Path $BatchProgress -Raw
                $content = $content -replace [regex]::Escape("- [ ] $PrpFile"), "- [x] $PrpFile"
                Set-Content -Path $BatchProgress -Value $content -NoNewline
            } else {
                Write-Host "PRP $PrpNum`: FAILED (exit code: $ExitCode)" -ForegroundColor Red
                if ($TotalTasks -gt 0) {
                    Write-Host "  Tasks: $TasksSucceeded/$TotalTasks succeeded, $TasksFailed failed"
                }
                Add-Content -Path $BatchProgress -Value "- Completed: $EndTime"
                Add-Content -Path $BatchProgress -Value "- Status: FAILED (exit code: $ExitCode)"
                if ($TotalTasks -gt 0) {
                    Add-Content -Path $BatchProgress -Value "- Tasks: $TasksSucceeded/$TotalTasks succeeded, $TasksFailed failed"
                }
                $BatchFailed++
                # Update checkbox to mark as failed
                $content = Get-Content -Path $BatchProgress -Raw
                $content = $content -replace [regex]::Escape("- [ ] $PrpFile"), "- [~] $PrpFile (FAILED)"
                Set-Content -Path $BatchProgress -Value $content -NoNewline
            }
        }
        catch {
            $EndTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            Write-Host "PRP $PrpNum`: ERROR - $_" -ForegroundColor Red
            Add-Content -Path $BatchProgress -Value "- Completed: $EndTime"
            Add-Content -Path $BatchProgress -Value "- Status: ERROR ($_)"
            $BatchFailed++
            # Update checkbox to mark as failed
            $content = Get-Content -Path $BatchProgress -Raw
            $content = $content -replace [regex]::Escape("- [ ] $PrpFile"), "- [~] $PrpFile (ERROR)"
            Set-Content -Path $BatchProgress -Value $content -NoNewline
        }

        Add-Content -Path $BatchProgress -Value ""

        # Brief pause between PRPs
        if ($PrpNum -lt $AllPrpFiles.Count) {
            Write-Host "Pausing before next PRP..."
            Start-Sleep -Seconds 2
        }
    }

    # Final summary
    $FinalTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host "  BATCH EXECUTION COMPLETE" -ForegroundColor Blue
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host "Total PRPs: $($AllPrpFiles.Count)"
    Write-Host "Succeeded: $BatchSucceeded" -ForegroundColor Green
    Write-Host "Failed: $BatchFailed" -ForegroundColor $(if ($BatchFailed -gt 0) { "Red" } else { "Green" })
    Write-Host "==========================================" -ForegroundColor Blue

    # Append summary to batch progress
    $summaryContent = @"

## Batch Summary
- Completed: $FinalTime
- Total PRPs: $($AllPrpFiles.Count)
- Succeeded: $BatchSucceeded
- Failed: $BatchFailed
"@
    Add-Content -Path $BatchProgress -Value $summaryContent

    Write-Host ""
    Write-Host "Batch progress saved to: $BatchProgress"

    # Exit with appropriate code
    if ($BatchFailed -gt 0) {
        exit 1
    } else {
        exit 0
    }
}
