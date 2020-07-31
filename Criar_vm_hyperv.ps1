<#Criar vm - 09 05 20- v1.3
tarefas:
1 - testar conexão de vm após start
2 - se qtd vm 1 entao preservar nome

Próximas etapas:
- Implementar criacao de vm apenas com imagem padrão(sem discos diferenciais).
#>
echo "`n---------Bem vindo ao Script para criação automatizada de VM(s)---------`n"

$qtd_vms= Read-Host "Quantidade de VM(s) a serem criadas"
$vmname=  Read-Host "Nome base da(s) máquina(s)"
$processador= Read-Host "Quantidade de processadores da(s) máquina(s)"
$memoria= Read-Host "Quantidade de memória da(s) máquina(s) em MB"
$memoria= $memoria +"MB"
$rede= Get-VMSwitch -name "*internet - wifi" 
$pasta_padrao = "C:\VMS - HYPERV"
$sair="`n=> Script interrompindo. Nenhuma máquina criada."

$disco_diferencial= Read-Host "Utilizar discos diferenciais(s/n)"
if ($disco_diferencial -eq "s"){
    echo "`n=> Listando discos pré-formatados disponíveis:" 
    ls $pasta_padrao *pai* | format-table FullName
    $disco_pai= Read-Host "Copie e cole o caminho completo do disco que deseja utilizar"  
    $tipo_SO=  ($disco_pai.Substring($disco_pai.IndexOfAny("\",3)+1,1) -eq "L") ? 1:2            
}else{
    echo "`n=> Opção não implementada nesta versão."
    echo $sair
    Break
}


echo "`n=> Sumário:"
echo "Será(ão) criada(s) $qtd_vms vm(s), com nome base '$vmname', $processador processador(es) e $memoria de memória."
echo "Obs.: Será utilizado o disco diferencial '$disco_pai'. " 

#convertendo formato de memoria
$memoria=($memoria/1)

$continuar= Read-Host "Deseja continuar(s/n)"
if ($continuar -eq "s") {

    for ($i=1; $i -le $qtd_vms; $i++) { 
    echo "`n=> Criando Máquina Virtual $vmname$i...`n"     
       New-vm -Name $vmname$i -MemoryStartupBytes $memoria -Switchname $rede.name -PATH "$pasta_padrao\" -Generation $tipo_SO 
       New-VHD -ParentPath $disco_pai -Path "$pasta_padrao\$vmname$i\$vmname$i.vhdx" -Differencing    
       Add-VMHardDiskDrive $vmname$i -Path "$pasta_padrao\$vmname$i\$vmname$i.vhdx"
       Set-VMMemory -MaximumBytes $memoria -MinimumBytes 512MB -VMName $vmname$i 
       set-vm -Name $vmname$i -CheckpointType Production -ProcessorCount $processador #-bootdevice VHD
       
       # configurando o boot - vm windows
       if ($tipo_SO -eq 2){
            $vm = Get-VM -Name $vmname$i
            $firmware = Get-VMFirmware -VM $vm
            $bootorder = $firmware.BootOrder
                foreach ($bootdev in $bootorder) {
                    if ($bootdev.FirmwarePath.Contains("Scsi(0,0)")) {
                        Set-VMFirmware -Test-VMNetworkAdapterFirstBootDevice $bootdev -VM $vm
                    }
                }
        }
       Start-VM -Name $vmname$i   
       set-vm -Name $vmname$i -CheckpointType Disabled        
    }
    echo "`n=> Nova(s) Vm(s) - Status:"
    get-vm -name "$vmname*" | Format-Table name,state,status    
}else {
   echo $sair  
   
} 
