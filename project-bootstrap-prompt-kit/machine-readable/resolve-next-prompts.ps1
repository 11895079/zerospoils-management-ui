param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("mobile", "web", "backend", "data-ai", "saas", "devtool-platform", "other")]
    [string]$ProjectType = "other",

    [Parameter(Mandatory = $false)]
    [string]$RegistryPath = ".\\prompt-registry.json",

    [Parameter(Mandatory = $false)]
    [string]$WorkflowPath = ".\\workflow.json",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeGovernance
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-JsonFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "File not found: $Path"
    }

    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Resolve-PromptOrder {
    param([object[]]$Prompts)

    $idToPrompt = @{}
    foreach ($prompt in $Prompts) {
        $idToPrompt[$prompt.id] = $prompt
    }

    $visited = @{}
    $visiting = @{}
    $order = New-Object System.Collections.Generic.List[object]

    function Visit {
        param([string]$PromptId)

        if ($visited.ContainsKey($PromptId)) { return }
        if ($visiting.ContainsKey($PromptId)) {
            throw "Circular dependency detected at prompt: $PromptId"
        }

        if (-not $idToPrompt.ContainsKey($PromptId)) {
            throw "Prompt dependency not found in registry: $PromptId"
        }

        $visiting[$PromptId] = $true
        $prompt = $idToPrompt[$PromptId]

        foreach ($dep in @($prompt.dependsOn)) {
            Visit -PromptId $dep
        }

        $null = $visiting.Remove($PromptId)
        $visited[$PromptId] = $true
        $order.Add($prompt)
    }

    foreach ($prompt in $Prompts) {
        Visit -PromptId $prompt.id
    }

    return $order
}

$registry = Read-JsonFile -Path $RegistryPath
$workflow = Read-JsonFile -Path $WorkflowPath

$allPrompts = @($registry.prompts)
$basePrompts = @($allPrompts | Where-Object { $_.id -ne "governance.weekly.v1" })
$orderedBasePrompts = Resolve-PromptOrder -Prompts $basePrompts

Write-Output "Prompt Kit: $($registry.kitName) v$($registry.version)"
Write-Output "Workflow Initial State: $($workflow.initialState)"
Write-Output ""
Write-Output "Suggested Execution Sequence"
Write-Output "----------------------------"

$index = 1
foreach ($prompt in $orderedBasePrompts) {
    Write-Output (("{0}. {1} [{2}] -> {3}") -f $index, $prompt.id, $prompt.phase, $prompt.file)
    $index++
}

if ($IncludeGovernance) {
    $gov = $allPrompts | Where-Object { $_.id -eq "governance.weekly.v1" }
    if ($gov) {
        Write-Output ""
        Write-Output "Parallel Track"
        Write-Output "--------------"
        Write-Output (("- {0} [{1}] cadence: weekly") -f $gov.id, $gov.phase)
    }
}

Write-Output ""
Write-Output "Project Type Follow-On"
Write-Output "----------------------"

$route = $null
if ($registry.projectTypeRouting.PSObject.Properties.Name -contains $ProjectType) {
    $route = $registry.projectTypeRouting.$ProjectType
}

if ($route) {
    Write-Output (("Project type: {0}") -f $ProjectType)
    Write-Output (("Follow-on prompt location: {0}") -f $route)
}
else {
    Write-Output (("Project type: {0}") -f $ProjectType)
    Write-Output "No project-specific route found. Use orchestrator + lifecycle baseline prompts."
}
