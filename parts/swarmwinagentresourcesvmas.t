    {
      "apiVersion": "[variables('apiVersionDefault')]", 
      "copy": {
        "count": "[variables('{{.Name}}Count')]", 
        "name": "loop"
      }, 
      "dependsOn": [
{{if not .IsCustomVNET}}
      "[variables('vnetID')]"
{{end}}
{{if IsPublic .Ports}}
	  ,"[variables('{{.Name}}LbID')]"
{{end}}
      ], 
      "location": "[resourceGroup().location]", 
      "name": "[concat(variables('{{.Name}}VMNamePrefix'), 'nic-', copyIndex())]", 
      "properties": {
        "ipConfigurations": [
          {
            "name": "ipConfigNode", 
            "properties": {
{{if IsPublic .Ports}}
              "loadBalancerBackendAddressPools": [
                {
                  "id": "[concat('/subscriptions/', subscription().subscriptionId,'/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/loadBalancers/', variables('{{.Name}}LbName'), '/backendAddressPools/',variables('{{.Name}}LbBackendPoolName'))]"
                }
              ],
              "loadBalancerInboundNatPools": [
                {
                  "id": "[concat(variables('{{.Name}}LbID'), '/inboundNatPools/', 'RDP-', variables('{{.Name}}VMNamePrefix'))]"
                }
              ],
{{end}}  
              "privateIPAllocationMethod": "Dynamic", 
              "subnet": {
                "id": "[variables('{{.Name}}VnetSubnetID')]"
             }
            }
          }
        ]
      }, 
      "type": "Microsoft.Network/networkInterfaces"
    },
{{if .IsManagedDisks}}
    {
      "apiVersion": "[variables('apiVersionStorageManagedDisks')]", 
      "location": "[resourceGroup().location]", 
      "name": "[variables('{{.Name}}AvailabilitySet')]", 
      "properties": { 
        "platformFaultDomainCount": "3", 
        "platformUpdateDomainCount": "3",
        "managed": "true"
      },
      "type": "Microsoft.Compute/availabilitySets"
    },
{{else if .IsStorageAccount}}
    {
      "apiVersion": "[variables('apiVersionStorage')]", 
      "copy": {
        "count": "[variables('{{.Name}}StorageAccountsCount')]", 
        "name": "vmLoopNode"
      }, 
      "dependsOn": [
        "[concat('Microsoft.Network/publicIPAddresses/', variables('masterPublicIPAddressName'))]"
      ], 
      "location": "[resourceGroup().location]", 
      "name": "[concat(variables('storageAccountPrefixes')[mod(add(copyIndex(),variables('{{.Name}}StorageAccountOffset')),variables('storageAccountPrefixesCount'))],variables('storageAccountPrefixes')[div(add(copyIndex(),variables('{{.Name}}StorageAccountOffset')),variables('storageAccountPrefixesCount'))],variables('{{.Name}}AccountName'))]", 
      "properties": {
        "accountType": "[variables('vmSizesMap')[variables('{{.Name}}VMSize')].storageAccountType]"
      }, 
      "type": "Microsoft.Storage/storageAccounts"
    },
  {{if .HasDisks}}
      {
        "apiVersion": "[variables('apiVersionStorage')]", 
        "copy": {
          "count": "[variables('{{.Name}}StorageAccountsCount')]", 
          "name": "datadiskLoop"
        }, 
        "dependsOn": [
          "[concat('Microsoft.Network/publicIPAddresses/', variables('masterPublicIPAddressName'))]"
        ], 
        "location": "[resourceGroup().location]", 
        "name": "[concat(variables('storageAccountPrefixes')[mod(add(copyIndex(variables('dataStorageAccountPrefixSeed')),variables('{{.Name}}StorageAccountOffset')),variables('storageAccountPrefixesCount'))],variables('storageAccountPrefixes')[div(add(copyIndex(variables('dataStorageAccountPrefixSeed')),variables('{{.Name}}StorageAccountOffset')),variables('storageAccountPrefixesCount'))],variables('{{.Name}}DataAccountName'))]", 
        "properties": {
          "accountType": "[variables('vmSizesMap')[variables('{{.Name}}VMSize')].storageAccountType]"
        }, 
        "type": "Microsoft.Storage/storageAccounts"
      }, 
  {{end}}
    {
      "apiVersion": "[variables('apiVersionDefault')]", 
      "location": "[resourceGroup().location]", 
      "name": "[variables('{{.Name}}AvailabilitySet')]", 
      "properties": {}, 
      "type": "Microsoft.Compute/availabilitySets"
    },
{{end}}
{{if IsPublic .Ports}}
    {
      "apiVersion": "[variables('apiVersionDefault')]", 
      "location": "[resourceGroup().location]", 
      "name": "[variables('{{.Name}}IPAddressName')]", 
      "properties": {
        "dnsSettings": {
          "domainNameLabel": "[variables('{{.Name}}EndpointDNSNamePrefix')]"
        }, 
        "publicIPAllocationMethod": "Dynamic"
      }, 
      "type": "Microsoft.Network/publicIPAddresses"
    }, 
    {
      "apiVersion": "[variables('apiVersionDefault')]", 
      "dependsOn": [
        "[concat('Microsoft.Network/publicIPAddresses/', variables('{{.Name}}IPAddressName'))]"
      ], 
      "location": "[resourceGroup().location]", 
      "name": "[variables('{{.Name}}LbName')]", 
      "properties": {
        "backendAddressPools": [
          {
            "name": "[variables('{{.Name}}LbBackendPoolName')]"
          }
        ], 
        "frontendIPConfigurations": [
          {
            "name": "[variables('{{.Name}}LbIPConfigName')]", 
            "properties": {
              "publicIPAddress": {
                "id": "[resourceId('Microsoft.Network/publicIPAddresses',variables('{{.Name}}IPAddressName'))]"
              }
            }
          }
        ],
        "inboundNatPools": [
          {
            "name": "[concat('RDP-', variables('{{.Name}}VMNamePrefix'))]",
            "properties": {
              "frontendIPConfiguration": {
                "id": "[variables('{{.Name}}LbIPConfigID')]"
              },
              "protocol": "tcp",
              "frontendPortRangeStart": "[variables('{{.Name}}WindowsRDPNatRangeStart')]",
              "frontendPortRangeEnd": "[variables('{{.Name}}WindowsRDPEndRangeStop')]",
              "backendPort": "[variables('agentWindowsBackendPort')]"
            }
          }
        ], 
        "loadBalancingRules": [
          {{(GetLBRules .Name .Ports)}}
        ], 
        "probes": [
          {{(GetProbes .Ports)}}
        ]
      }, 
      "type": "Microsoft.Network/loadBalancers"
    }, 
{{end}}
    {
{{if .IsManagedDisks}}
    "apiVersion": "[variables('apiVersionStorageManagedDisks')]",
{{else}}
    "apiVersion": "[variables('apiVersionDefault')]",
{{end}}
      "copy": {
        "count": "[variables('{{.Name}}Count')]", 
        "name": "vmLoopNode"
      }, 
      "dependsOn": [
{{if .IsStorageAccount}}
        "[concat('Microsoft.Storage/storageAccounts/',variables('storageAccountPrefixes')[mod(add(div(copyIndex(),variables('maxVMsPerStorageAccount')),variables('{{.Name}}StorageAccountOffset')),variables('storageAccountPrefixesCount'))],variables('storageAccountPrefixes')[div(add(div(copyIndex(),variables('maxVMsPerStorageAccount')),variables('{{.Name}}StorageAccountOffset')),variables('storageAccountPrefixesCount'))],variables('{{.Name}}AccountName'))]",
  {{if .HasDisks}}
          "[concat('Microsoft.Storage/storageAccounts/',variables('storageAccountPrefixes')[mod(add(add(div(copyIndex(),variables('maxVMsPerStorageAccount')),variables('{{.Name}}StorageAccountOffset')),variables('dataStorageAccountPrefixSeed')),variables('storageAccountPrefixesCount'))],variables('storageAccountPrefixes')[div(add(add(div(copyIndex(),variables('maxVMsPerStorageAccount')),variables('{{.Name}}StorageAccountOffset')),variables('dataStorageAccountPrefixSeed')),variables('storageAccountPrefixesCount'))],variables('{{.Name}}DataAccountName'))]",
  {{end}}
{{end}}
        "[concat('Microsoft.Network/networkInterfaces/', variables('{{.Name}}VMNamePrefix'), 'nic-', copyIndex())]", 
        "[concat('Microsoft.Compute/availabilitySets/', variables('{{.Name}}AvailabilitySet'))]"
      ],
      "tags":
      {
        "creationSource" : "[concat('acsengine-', variables('{{.Name}}VMNamePrefix'), copyIndex())]"
      },
      "location": "[resourceGroup().location]", 
      "name": "[concat(variables('{{.Name}}VMNamePrefix'), copyIndex())]", 
      "properties": {
        "availabilitySet": {
          "id": "[resourceId('Microsoft.Compute/availabilitySets',variables('{{.Name}}AvailabilitySet'))]"
        }, 
        "hardwareProfile": {
          "vmSize": "[variables('{{.Name}}VMSize')]"
        }, 
        "networkProfile": {
          "networkInterfaces": [
            {
              "id": "[resourceId('Microsoft.Network/networkInterfaces',concat(variables('{{.Name}}VMNamePrefix'), 'nic-', copyIndex()))]"
            }
          ]
        }, 
        "osProfile": {
          "computername": "[concat(substring(variables('nameSuffix'), 0, 5), 'acs', copyIndex(), add(900,variables('{{.Name}}Index')))]",
          "adminUsername": "[variables('windowsAdminUsername')]",
          "adminPassword": "[variables('windowsAdminPassword')]",
          {{GetWinAgentSwarmCustomData}}
        }, 
        "storageProfile": {
          {{GetDataDisks .}}
          "imageReference": {
            "publisher": "[variables('agentWindowsPublisher')]",
            "offer": "[variables('agentWindowsOffer')]",
            "sku": "[variables('agentWindowsSku')]",
            "version": "latest"
          }
{{if .IsStorageAccount}}
          ,"osDisk": {
            "caching": "ReadOnly", 
            "createOption": "FromImage", 
            "name": "[concat(variables('{{.Name}}VMNamePrefix'), copyIndex(),'-osdisk')]", 
            "vhd": {
              "uri": "[concat(reference(concat('Microsoft.Storage/storageAccounts/',variables('storageAccountPrefixes')[mod(add(div(copyIndex(),variables('maxVMsPerStorageAccount')),variables('{{.Name}}StorageAccountOffset')),variables('storageAccountPrefixesCount'))],variables('storageAccountPrefixes')[div(add(div(copyIndex(),variables('maxVMsPerStorageAccount')),variables('{{.Name}}StorageAccountOffset')),variables('storageAccountPrefixesCount'))],variables('{{.Name}}AccountName')),variables('apiVersionStorage')).primaryEndpoints.blob,'osdisk/', variables('{{.Name}}VMNamePrefix'), copyIndex(), '-osdisk.vhd')]"
            }
          }
{{end}}
        }
      }, 
      "type": "Microsoft.Compute/virtualMachines"
    }, 
    {
      "apiVersion": "[variables('apiVersionDefault')]", 
      "copy": {
        "count": "[variables('{{.Name}}Count')]", 
        "name": "vmLoopNode"
      }, 
      "dependsOn": [
        "[concat('Microsoft.Compute/virtualMachines/', variables('{{.Name}}VMNamePrefix'), copyIndex())]"
      ], 
      "location": "[resourceGroup().location]", 
      "name": "[concat(variables('{{.Name}}VMNamePrefix'), copyIndex(), '/cse')]", 
      "properties": {
        "publisher": "Microsoft.Compute",
        "type": "CustomScriptExtension",
        "typeHandlerVersion": "1.8",
        "autoUpgradeMinorVersion": true,
        "settings": {
          "commandToExecute": "[variables('windowsCustomScript')]"
        }
      }, 
      "type": "Microsoft.Compute/virtualMachines/extensions"
    }
