<# Este script baixa o provedor de credenciais do Google para Windows e o Google Chrome
em seguida, instala e configura o dominio.#>


param (
    [string]$User = "",
    [int]$MDMvalue = 0,
    [int]$ValidityPeriod = 30
)

<# Adicione os dominios para restringir aqui #>
$domainsAllowedToLogin = "teste@meudominio"
<# Downloads mais rÃ¡pidos Invoke-WebRequest #>
$ProgressPreference = 'SilentlyContinue'
<# Chrome Enterprise Enrollment token #>
$enrollmentToken = 'AddTokenHere'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

<# Verifique se um ou mais dominios estao definidos #>
if ($domainsAllowedToLogin.Equals('')) {
    # $msgResult = [System.Windows.MessageBox]::Show('A lista de dominios nao pode estar vazia! .', 'GCPW', 'OK', 'Error')
    Write-Output 'A lista de dominios não pode estar vazia!'
    exit 5
}

function Is-Admin() {
    $admin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match 'S-1-5-32-544')
    return $admin
}

<# Verifique se o usuario atual é um administrador e saia se não for. #>
if (-not (Is-Admin)) {
    # $result = [System.Windows.MessageBox]::Show('Please run as administrator!', 'GCPW', 'OK', 'Error')
    Write-Output 'Por favor, execute como administrador!'
    exit 5
}
<# Baixe o instalador do Chrome. #>

$LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).
DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller");
 & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor = "ChromeInstaller"; Do { $ProcessesFound = Get-Process | Where-Object {$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; 
 
 If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2
 
} else{ Remove-Item "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)


    Write-Output 'Chrome instalado...'


if (!(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object { $_.DisplayName -match "Google Credential Provider for Windows" })) {
    <# Escolha o arquivo GCPW para fazer o download. As versões de 32 bits ou 64 bits #>
    $gcpwFileName = 'gcpwstandaloneenterprise.msi'
    if ([Environment]::Is64BitOperatingSystem) {
        $gcpwFileName = 'gcpwstandaloneenterprise64.msi'
    }

    <# Baixe o instalador GCPW. #>
    $gcpwUrlPrefix = 'https://dl.google.com/credentialprovider/'
    $gcpwUri = $gcpwUrlPrefix + $gcpwFileName
    Write-Host 'Downloading GCPW from' $gcpwUri
    Invoke-WebRequest -Uri $gcpwUri -OutFile "$env:temp\$gcpwFileName"

    <# Execute o instalador GCPW e aguarde a conclusão da instalação #>
    $arguments = "/i `"$env:temp\$gcpwFileName`" /quiet"
    $installProcess = (Start-Process msiexec.exe -ArgumentList $arguments -PassThru -Wait)

    <# Verifique se a instalação foi bem sucedida #>
    if ($installProcess.ExitCode -ne 0) {
        # $result = [System.Windows.MessageBox]::Show('Installation failed!', 'GCPW', 'OK', 'Error')
        Write-Output 'Instalação falho!'
        exit $installProcess.ExitCode
    }
    else {
        # $result = [System.Windows.MessageBox]::Show('Installation completed successfully!', 'GCPW', 'OK', 'Info')
        Write-Output 'Instalação concluida com sucesso!'
    }
} else {
    Write-Output 'GCPW alreaday installed. Skipping...'
}

<# Defina a chave de registro com os dominios permitidos #>
$registryPath = 'HKEY_LOCAL_MACHINE\Software\Google\GCPW'
$name = 'domains_allowed_to_login'
[microsoft.win32.registry]::SetValue($registryPath, $name, $domainsAllowedToLogin)

$domains = Get-ItemPropertyValue HKLM:\Software\Google\GCPW -Name $name

if ($domains -eq $domainsAllowedToLogin) {
    # $msgResult = [System.Windows.MessageBox]::Show('Configuration completed successfully!', 'GCPW', 'OK', 'Info')
    Write-Output 'Dominio configurado com sucesso!'
}
else {
    # $msgResult = [System.Windows.MessageBox]::Show('Could not write to registry. Configuration was not completed.', 'GCPW', 'OK', 'Error')
    Write-Output "Could not write domain configuration to registry. Configuration was not completed. ($domains - $domainsAllowedToLogin)"
}

<# Defina a validade, as contas de tempos podem ficar offline #>
$name = 'validity_period_in_days'
$value = $ValidityPeriod
[microsoft.win32.registry]::SetValue($registryPath, $name, $value)

$validity = Get-ItemPropertyValue HKLM:\Software\Google\GCPW -Name $name

if ($validity -eq $value) {
    # $msgResult = [System.Windows.MessageBox]::Show('Configuration completed successfully!', 'GCPW', 'OK', 'Info')
    Write-Output 'Configuração de validade concluida com sucesso!'
}
else {
    # $msgResult = [System.Windows.MessageBox]::Show('Could not write to registry. Configuration was not completed.', 'GCPW', 'OK', 'Error')
    Write-Output "Não foi possivel gravar a validade no registro, configuração não foi completada. ($domains - $domainsAllowedToLogin)"
}

<# Set MDM enrollment #>
Write-Output "Setting MDM value to $MDMvalue"
$name = 'enable_dm_enrollment'
[microsoft.win32.registry]::SetValue($registryPath, $name, $MDMvalue)

$validity = Get-ItemPropertyValue HKLM:\Software\Google\GCPW -Name $name

if ($validity -eq $MDMvalue) {
    # $msgResult = [System.Windows.MessageBox]::Show('Configuration completed successfully!', 'GCPW', 'OK', 'Info')
    Write-Output 'Configuração de inscrição MDM concluida com sucesso!'
}
else {
    # $msgResult = [System.Windows.MessageBox]::Show('Could not write to registry. Configuration was not completed.', 'GCPW', 'OK', 'Error')
    Write-Output "Não foi posssivel gravar a inscrição do MDM no registro. A configuração não foi concluida. (MDM -> $MDMvalue)"
}

<# se usuario for definido com uma conta de e-mail valida do Google, a conta atual sera vinculada a ela #>
if ($User) {
    Write-Output "Setting user to $User"
    $currentSid = Get-CimInstance Win32_UserAccount -Filter "Name = '$env:USERNAME'" | Select-Object -ExpandProperty SID
    $registryPath = "HKEY_LOCAL_MACHINE\Software\Google\GCPW\Users\" + $currentSid
    $name = 'email'
    [microsoft.win32.registry]::SetValue($registryPath, $name, $User)

    $path = "HKLM:\Software\Google\GCPW\Users\" + $currentSid
    $userCheck = Get-ItemPropertyValue $path -Name $name

    if ($userCheck -eq $User) {
        # $msgResult = [System.Windows.MessageBox]::Show('Configuration completed successfully!', 'GCPW', 'OK', 'Info')
        Write-Output 'Configuração do usuário concluída com sucesso!'
    }
    else {
        # $msgResult = [System.Windows.MessageBox]::Show('Could not write to registry. Configuration was not completed.', 'GCPW', 'OK', 'Error')
        Write-Output "Não foi possivel gravar o usuario no registro. A configuração não foi completada. (User -> $User)"
    }
}
