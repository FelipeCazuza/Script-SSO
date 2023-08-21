# Script para acessar  estação de trabalho com  sistema operacional windows com a conta do Google <h1>

* Primeiro passo é alterar $domainsAllowedToLogin = "teste@meudominio" para o seu dominio
* Segundo passo é converter o programa para extensão EXE. 
* Para converter um script PowerShell (.ps1) para um arquivo executável (.exe), você pode usar o módulo "PS2EXE". Este módulo permite criar um arquivo  executável a partir de um script PowerShell.

* Abra o PowerShell como administrador.
* Instale o módulo "PS2EXE" digitando o seguinte comando:

* Install-Module -Name PS2EXE

* Carregue o módulo digitando o seguinte comando:
Import-Module PS2EXE

* Use o comando "New-ExeShortcut" para criar um arquivo executável. Por exemplo, se o seu script PowerShell se chama "meu_script.ps1" e você deseja criar um arquivo executável chamado "meu_executavel.exe", digite o seguinte comando:

* New-ExeShortcut -Filepath C:\caminho\para\meu_script.ps1 -OutputFile C:\caminho\para\meu_executavel.exe



