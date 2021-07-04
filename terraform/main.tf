provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "unyleya" {
  name     = "Unyleya-RG"
  location = "eastus"
}

resource "azurerm_network_security_group" "unyleya_nsg" {
  name                = "unyleya-nsg"
  location            = azurerm_resource_group.unyleya.location
  resource_group_name = azurerm_resource_group.unyleya.name
}

resource "azurerm_network_security_rule" "unyleya_nsg_rule_3389" {
  name                        = "unyleya-allow-3389-inbound"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 3389
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.unyleya.name
  network_security_group_name = azurerm_network_security_group.unyleya_nsg.name
}

resource "azurerm_network_security_rule" "unyleya_nsg_rule_5986" {
  name                        = "unyleya-allow-5986-inbound"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 5986
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.unyleya.name
  network_security_group_name = azurerm_network_security_group.unyleya_nsg.name
}

resource "azurerm_virtual_network" "minhavnet" {
  name                = "unyleya-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.unyleya.location
  resource_group_name = azurerm_resource_group.unyleya.name
}

resource "azurerm_subnet" "minhasubnet" {
  name                 = "unyleya-subnet"
  resource_group_name  = azurerm_resource_group.unyleya.name
  virtual_network_name = azurerm_virtual_network.minhavnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "minhanic" {
  name                = "unyleya-nic"
  location            = azurerm_resource_group.unyleya.location
  resource_group_name = azurerm_resource_group.unyleya.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.minhasubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "minhanic_nsg" {
  network_interface_id      = azurerm_network_interface.minhanic.id
  network_security_group_id = azurerm_network_security_group.unyleya_nsg.id
}


resource "azurerm_windows_virtual_machine" "minhaVM" {
  name                    = "WinServ2019VM"
  location                = azurerm_resource_group.unyleya.location
  resource_group_name     = azurerm_resource_group.unyleya.name
  network_interface_ids   = [azurerm_network_interface.minhanic.id]
  size                    = "Standard_DS1_v2"
  admin_username          = "adminuser"
  admin_password          = "P@$$w0rd1234!"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

}