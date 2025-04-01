# MyPsTools

My personal toolbox for Powershell

## How to install a Powershell module

Clone this repository to a desired location on your computer.
The Powershell modules in this repository are not signed (me lazy) so you need to unblock them before using them.

Example for Windows:

```pwsh
Get-ChildItem '<path to your cloned repo>\PSModules\*' -Recurse | Unblock-File
```

Easiest way to ensure these modules are imported every time powershell starts is to add them to your powershell `$PROFILE`.
Add the following code into your `$PROFILE`:

```pwsh
    Get-ChildItem -File '<path to your cloned repo>\PSModules\*' -Recurse -Include '*.psm1' | ForEach-Object {
        Import-Module $_
    }
```

<!-- I suggest to include the PSModule folder to your PSModulePath environment variable.
Something like this:

```pwsh
[System.Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + 'C:\Repositories\MyPsTools\PSModules', [System.EnvironmentVariableTarget]::User)
``` -->
