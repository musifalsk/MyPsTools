# MyPsTools

My personal toolbox for Powershell

## How to install a Powershell module

Clone this repository to a desired location on your computer.

Example using GitHub CLI:

```cmd
gh repo clone musifalsk/MyPsTools
```

The Powershell modules in this repository are not signed (yes me lazy) so you might need to unblock them before using them.

### Example for Windows

```pwsh
Get-ChildItem '<path to your local cloned repo>\PSModules\*' -Recurse | Unblock-File
```

The easiest way to ensure these modules are imported every time powershell starts is to add some code to your powershell `$PROFILE`.

Add the following code into your `$PROFILE`:

```pwsh
    Get-ChildItem -File '<path to your cloned repo>\PSModules\*' -Recurse -Include '*.psm1' | ForEach-Object {
        Import-Module $_
    }
```

An alternative is to include the PSModules folder to your `Path` environment variable.

### Example for WSL (Ubuntu)

#### Prerequisites

- Powershell
- Make sure you have [Az pwsh module](https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows?view=azps-12.5.0&tabs=powershell&pivots=windows-psgallery#installation) installed.  
- Install `ConsoleGuiTools`: `Install-Module Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser`  

> NOTE: `Az` and `ConsoleGuiTools` modules need to be installed in a pwsh session on WSL. Enter `pwsh` to start powershell session.

#### Import modules

1. Open `pwsh` session
2. Open the `$PROFILE` file in a text editor. (Example: `code $PROFILE`)
3. Add following line to the end of the file

 ```pwsh
Get-ChildItem -File '<path to your cloned repo>\PSModules\*' -Recurse -Include '*.psm1' | ForEach-Object {
    Import-Module $_
}
```

4. Save and close
5. Open new pwsh session and try writing PIM