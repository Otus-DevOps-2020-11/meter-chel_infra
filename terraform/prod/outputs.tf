output "external_ip_address_app" {
   value = module.app.external_ip_address_app
}

output "external_ip_address_db" {
   value = module.db.external_ip_address_db
}

resource "local_file" "AnsibleInventory" {
 content = templatefile("inventory.tmpl",
 {
  app-extip = module.app.external_ip_address_app,
  db-extip = module.db.external_ip_address_db,
 }
 )
 filename = "../../ansible/inventory.ini"
}
