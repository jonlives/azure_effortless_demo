$baseline_path = Invoke-Expression "C:\ProgramData\chocolatey\bin\hab.exe pkg path effortless/config-baseline"
$client_config_path = [IO.Path]::Combine($baseline_path, "config", "client-config.rb")
Add-Content -Path $client_config_path -Value "verify_api_cert false"