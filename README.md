# MyPsTools

My personal toolbox for Powershell

## How to install a Powershell module

The Powershell modules in this repository are not signed (me lazy) so you need to unblock them before using them.
For Windows:

```pwsh
Get-ChildItem PSModules\* -Recurse | Unblock-File
```

I suggest to include the PSModule folder to your PSModulePath environment variable.
Something like this:

```pwsh
[System.Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + 'C:\Repositories\MyPsTools\PSModules', [System.EnvironmentVariableTarget]::User)
```
