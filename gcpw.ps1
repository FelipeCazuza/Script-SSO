<# Este script baixa o provedor de credenciais do Google para Windows
https://tools.google.com/dlpage/gcpw/, em seguida, instala e configura.
É necessário acesso de administrador do Windows para usar o script.
Se o Chrome Enterprise não estiver presente, ele também fará o download e instalará
e irá inscrevê-los no Chrome Enterprise
#>

<# Especifique um parâmetro -user se quiser vincular a conta do usuário atual a uma conta do Google.
-User contatoseguro.com.br-> especificar e-mail para cadastrar conta atual do windows
-MDMvalue 1 -> para ativar o registro automático de MDM no Google Endpoint Management
-ValidityPeriod 30 -> Para alterar o número de dias que uma conta pode ser usada sem se conectar ao Google
Execute o script como abaixo, certifique-se de verificar os parâmetros:
powershell.exe -ExecutionPolicy Unrestricted -NoLogo -NoProfile -Command "& '. \ gcpw_enrollment.ps1' -Nome de usuário.lastname@domain.com -MDMvalue 1""
#>

<# Parametros padroes #>
param (
    [string]$User = "",
    [int]$MDMvalue = 0,
    [int]$ValidityPeriod = 30
)

<# Adicione domínios para restringir aqui #>
$domainsAllowedToLogin = "contatoseguro.com.br,compliancetotal.com.br"
<# Downloads mais rápidos Invoke-WebRequest #>
$ProgressPreference = 'SilentlyContinue'
<# Chrome Enterprise Enrollment token #>
$enrollmentToken = 'AddTokenHere'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

<# Verifique se um ou mais domínios estão definidos #>
if ($domainsAllowedToLogin.Equals('')) {
    # $msgResult = [System.Windows.MessageBox]::Show('A lista de domínios nao pode estar vazia! .', 'GCPW', 'OK', 'Error')
    Write-Output 'A lista de domínios não pode estar vazia!'
    exit 5
}

function Is-Admin() {
    $admin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match 'S-1-5-32-544')
    return $admin
}

<# Verifique se o usuário atual é um administrador e saia se não for. #>
if (-not (Is-Admin)) {
    # $result = [System.Windows.MessageBox]::Show('Please run as administrator!', 'GCPW', 'OK', 'Error')
    Write-Output 'Por favor, execute como administrador!'
    exit 5
}

if (!(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object { $_.DisplayName -match "Google Chrome" })) {
    <# Escolha o arquivo do Chrome para fazer o download, As versões de 32 bits ou 64 bits. #>
    $chromeFileName = 'googlechromestandaloneenterprise.msi'
    if ([Environment]::Is64BitOperatingSystem) {
        $chromeFileName = 'googlechromestandaloneenterprise64.msi'
    }

    <# Baixe o instalador do Chrome. #>
    $chromeUrlPrefix = 'https://dl.google.com/chrome/install/'
    $chromeUri = $chromeUrlPrefix + $chromeFileName
    Write-Host 'Downloading Chrome from' $chromeUri
    Invoke-WebRequest -Uri $chromeUri -OutFile "$env:temp\$chromeFileName"

    <# Execute o instalador do Chrome e espere a instalação terminar #>
    $arguments = "/i `"$env:temp\$chromeFileName`" /qn"
    $installProcess = (Start-Process msiexec.exe -ArgumentList $arguments -PassThru -Wait)

    <# Verifique se a instalação foi bem sucedida #>
    if ($installProcess.ExitCode -ne 0) {
        # $result = [System.Windows.MessageBox]::Show('Installation failed!', 'Chrome', 'OK', 'Error')
        exit $installProcess.ExitCode
    }
    else {
        Write-Host 'Chrome instalado com sucesso'
        # $result = [System.Windows.MessageBox]::Show('Installation completed successfully!', 'Chrome', 'OK', 'Info')
        # Apply local Chrome Enterprise settings for enrollment
        Write-Output 'Enforcing Chrome Enterprise Config'
        $key = 'HKLM:\SOFTWARE\Policies\Google\Chrome'
        New-Item -Path $key -Force | Out-Null
        New-ItemProperty -Path $key -Name 'CloudManagementEnrollmentMandatory' -Value 1 -PropertyType 'DWord' -Force | Out-Null
        New-ItemProperty -Path $key -Name 'CloudManagementEnrollmentToken' -Value $enrollmentToken -Force | Out-Null
        New-ItemProperty -Path $key -Name 'BrowserSignin' -Value 2 -PropertyType 'DWord' -Force | Out-Null
        New-ItemProperty -Path $key -Name 'RestrictSigninToPattern' -Value '' -Force | Out-Null
        New-ItemProperty -Path $key -Name 'AllowedDomainsForApps' -Value '' -Force | Out-Null
        New-ItemProperty -Path $key -Name 'CloudPolicyOverridesPlatformPolicy' -Value 1 -PropertyType 'DWord' -Force | Out-Null
        New-ItemProperty -Path $key -Name 'DefaultBrowserSettingEnabled' -Value 1 -PropertyType 'DWord' -Force | Out-Null
        New-ItemProperty -Path $key -Name 'PasswordLeakDetectionEnabled' -Value 1 -PropertyType 'DWord' -Force | Out-Null
        New-ItemProperty -Path $key -Name 'RelaunchNotification' -Value 2 -PropertyType 'DWord' -Force | Out-Null

        Write-Output 'Chrome Enterprise instalado .'
    }

}else {
    Write-Output 'Chrome Enterprise instalado...'
}

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
        Write-Output 'Instalação concluída com sucesso!'
    }
} else {
    Write-Output 'GCPW alreaday installed. Skipping...'
}

<# Defina a chave de registro necessária com os domínios permitidos #>
$registryPath = 'HKEY_LOCAL_MACHINE\Software\Google\GCPW'
$name = 'domains_allowed_to_login'
[microsoft.win32.registry]::SetValue($registryPath, $name, $domainsAllowedToLogin)

$domains = Get-ItemPropertyValue HKLM:\Software\Google\GCPW -Name $name

if ($domains -eq $domainsAllowedToLogin) {
    # $msgResult = [System.Windows.MessageBox]::Show('Configuration completed successfully!', 'GCPW', 'OK', 'Info')
    Write-Output 'Domain configuration completed successfully!'
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
    Write-Output 'Configuração de validade concluída com sucesso!'
}
else {
    # $msgResult = [System.Windows.MessageBox]::Show('Could not write to registry. Configuration was not completed.', 'GCPW', 'OK', 'Error')
    Write-Output "Não foi possível gravar a validade no registro, configuração não foi completada. ($domains - $domainsAllowedToLogin)"
}

<# Set MDM enrollment #>
Write-Output "Setting MDM value to $MDMvalue"
$name = 'enable_dm_enrollment'
[microsoft.win32.registry]::SetValue($registryPath, $name, $MDMvalue)

$validity = Get-ItemPropertyValue HKLM:\Software\Google\GCPW -Name $name

if ($validity -eq $MDMvalue) {
    # $msgResult = [System.Windows.MessageBox]::Show('Configuration completed successfully!', 'GCPW', 'OK', 'Info')
    Write-Output 'Configuração de inscrição MDM concluída com sucesso!'
}
else {
    # $msgResult = [System.Windows.MessageBox]::Show('Could not write to registry. Configuration was not completed.', 'GCPW', 'OK', 'Error')
    Write-Output "Não foi possível gravar a inscrição do MDM no registro. A configuração não foi concluída. (MDM -> $MDMvalue)"
}

<# se usuario for definido com uma conta de e-mail válida do Google, a conta atual será vinculada a ela #>
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
        Write-Output 'User configuration completed successfully!'
    }
    else {
        # $msgResult = [System.Windows.MessageBox]::Show('Could not write to registry. Configuration was not completed.', 'GCPW', 'OK', 'Error')
        Write-Output "Não foi possível gravar o usuário no registro. A configuração não foi completada. (User -> $User)"
    }
}
