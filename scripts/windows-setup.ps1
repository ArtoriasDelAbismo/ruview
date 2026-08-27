<#
Sets up RuView on native Windows (PowerShell): clones the core repo,
creates a venv, and installs the minimal dependencies.

Run from PowerShell:
    powershell -ExecutionPolicy Bypass -File windows-setup.ps1
#>

Write-Host "Cloning RuView..."
git clone https://github.com/ruvnet/RuView.git core

Write-Host "Creating virtual environment..."
python -m venv venv
venv\Scripts\Activate.ps1

Write-Host "Installing minimal dependencies..."
pip install -r requirements-minimal.txt

Write-Host "Done"
