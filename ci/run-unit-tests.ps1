param (
    [Parameter(Mandatory = $true)]
    [string]$RepoName
)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

# The link lint is the real check this repository has. Every 51degrees.com
# link a specification carries must follow the tagging convention, or the
# reader is lost to the wrong page and the campaign attribution is wrong.
# utm-link-lint.yml runs the same script on each pull request, and running it
# here as well proves it still passes once the change is merged into main.
./scripts/utm-lint.ps1 -RepoRoot ./$RepoName -Campaign $RepoName

exit $LASTEXITCODE
