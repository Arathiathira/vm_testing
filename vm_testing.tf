terraform {
    required_version = ">= 0.11"
    backend "azurerm"{
      resource_group_name  =  "r1234567abc"
      storage_account_name = "s1234567abc"
      container_name       = "c1234567abc"
      key                  = "terraform.tfstate"
#      access_keys          ="wQeOkNzkMygUusQIdiRD1xNo1Vtl8GzZ2pc3VpFdZLNv+1CXSORrjMbIuEbVP/awZuo1+4W17sXEeMkDMyhQRQ=="
#      connection_string    ="DefaultEndpointsProtocol=https;AccountName=s1234567abc;AccountKey=wQeOkNzkMygUusQIdiRD1xNo1Vtl8GzZ2pc3VpFdZLNv+1CXSORrjMbIuEbVP/awZuo1+4W17sXEeMkDMyhQRQ==;EndpointSuffix=core.windows.net"
        features {}
    }
}

provider "azurerm"{
    version ="=2.46.0"
    features {}
}

resource "azurerm_resource_group" "myrg"{
    name                ="arsrg"
    location            ="East US"
    tags                ={
        owner           = "Arathi"
    }
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.myrg.name
  location            = azurerm_resource_group.myrg.location
  size                = "Standard_E8-2ds v4"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

   admin_ssh_key {
     username   = "adminuser"
     public_key = /home/{username}/.ssh/authorized_keys  //file("~/.ssh/id_rsa.pub")
   }

  os_disk {
    caching              = "ReadOnly"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

