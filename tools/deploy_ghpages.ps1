$ErrorActionPreference = 'Stop'

$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class CredMan {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public UInt32 Flags;
        public UInt32 Type;
        public IntPtr TargetName;
        public IntPtr Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public UInt32 CredentialBlobSize;
        public IntPtr CredentialBlob;
        public UInt32 Persist;
        public UInt32 AttributeCount;
        public IntPtr Attributes;
        public IntPtr TargetAlias;
        public IntPtr UserName;
    }
    [DllImport("advapi32.dll", EntryPoint="CredReadW", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern bool CredRead(string target, UInt32 type, UInt32 reservedFlag, out IntPtr credentialPtr);
    [DllImport("advapi32.dll", EntryPoint="CredFree", SetLastError=true)]
    public static extern void CredFree(IntPtr buffer);
}
'@

$credPtr = [IntPtr]::Zero
[CredMan]::CredRead("git:https://github.com", 1, 0, [ref]$credPtr) | Out-Null
$cred = [System.Runtime.InteropServices.Marshal]::PtrToStructure($credPtr, [type][CredMan+CREDENTIAL])
$passwordBytes = New-Object byte[] $cred.CredentialBlobSize
[System.Runtime.InteropServices.Marshal]::Copy($cred.CredentialBlob, $passwordBytes, 0, $cred.CredentialBlobSize)
$env:GIT_TOKEN = [System.Text.Encoding]::Unicode.GetString($passwordBytes)
[CredMan]::CredFree($credPtr)
Write-Host "Loaded GitHub token from Credential Manager"

$adminDir = 'D:\codes\streetlore_admin'
$workTree = Join-Path $env:TEMP 'streetlore-admin-ghpages-worktree'
$gitDir = Join-Path $workTree '.git'

if (Test-Path $workTree) {
    Write-Host "Removing previous worktree at $workTree..."
    Remove-Item -LiteralPath $workTree -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $workTree -Force | Out-Null

Write-Host "Fetching gh-pages branch..."
git -C $adminDir fetch origin gh-pages --force 2>&1 | Select-Object -Last 2

# Check if gh-pages exists remotely
$hasGhPages = (git -C $adminDir branch -r | Select-String 'origin/gh-pages')
if (-not $hasGhPages) {
    Write-Host "Remote gh-pages doesn't exist yet; creating from main..."
    git -C $adminDir checkout --orphan gh-pages main 2>&1 | Select-Object -Last 2
    git -C $adminDir commit --allow-empty -m "chore: initialize gh-pages branch" 2>&1 | Select-Object -Last 2
    git -C $adminDir push origin gh-pages --force 2>&1 | Select-Object -Last 3
    git -C $adminDir checkout main 2>&1 | Select-Object -Last 1
}

# Set up a temp worktree
Write-Host "Creating worktree at $workTree..."
git -C $adminDir worktree add --force $workTree gh-pages 2>&1 | Select-Object -Last 3

# Wipe everything in the worktree (we're publishing a fresh build)
Write-Host "Cleaning old build artifacts..."
Get-ChildItem -Force $workTree | Where-Object { $_.Name -ne '.git' } | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Recurse -Force
}

# Copy the new build into the worktree
Write-Host "Copying build\web\* -> worktree..."
Copy-Item -Path (Join-Path $adminDir 'build\web\*') -Destination $workTree -Recurse -Force

# Ensure .nojekyll so GitHub Pages doesn't ignore underscore-prefixed dirs
'' | Out-File -FilePath (Join-Path $workTree '.nojekyll') -Encoding utf8

# Commit and force push
git -C $workTree add -A 2>&1 | Select-Object -Last 2
$diff = git -C $workTree status --porcelain
if ($diff) {
    Write-Host "Committing..."
    git -C $workTree commit -m "deploy: refresh streetlore-admin with current build" 2>&1 | Select-Object -Last 3
}
Write-Host "Pushing gh-pages..."
git -C $workTree push origin gh-pages --force 2>&1 | Select-Object -Last 4

# Tear down worktree
git -C $adminDir worktree remove $workTree --force 2>&1 | Select-Object -Last 2

Write-Host "Done. Live URL: https://mohamedsabae50-prog.github.io/streetlore-admin/"
