# Setup
terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "1.7.0"
    }
  }
}


provider "mongodbatlas" {
  public_key  = var.mongodb_atlas_api_pub_key
  private_key = var.mongodb_atlas_api_pri_key
}


data "http" "ip" {
  url = "https://ifconfig.me/ip"
}


locals {
  client_public_ip = data.http.ip.response_body
}


locals {
  username = "admin0"
  password = "admin0"
  database = "database_test"
  collection_name = "collection_test"
}


resource "mongodbatlas_project_ip_access_list" "jpmc-search-index" {
      project_id = var.mongodb_atlas_project_id
      ip_address = local.client_public_ip
      comment    = "jpmc-search-index"
}


resource "mongodbatlas_database_user" "jpmc-search-index" {
  username           = local.username
  password           = local.password
  project_id         = var.mongodb_atlas_project_id
  auth_database_name = "admin"

  roles {
    role_name     = "atlasAdmin"
    database_name = "admin"
  }

  labels {
    key   = "Name"
    value = "jpmc-search-index"
  }

  scopes {
    name   = "jpmc-search-index"
    type = "CLUSTER"
  }

}


resource "mongodbatlas_cluster" "jpmc-search-index" {
  project_id              = var.mongodb_atlas_project_id
  name                    = "jpmc-search-index"

  provider_name           = "AWS"
  provider_region_name    = "EU_WEST_1"
  provider_instance_size_name = "M10"

  mongo_db_major_version  = "5.0"
  auto_scaling_disk_gb_enabled = "false"
}


resource "null_resource" "jpmc-search-index" {
  depends_on = [mongodbatlas_cluster.jpmc-search-index]

  provisioner "local-exec" {
    command = "/bin/bash ./files/mongo.sh ${mongodbatlas_cluster.jpmc-search-index.connection_strings[0].standard_srv} ${mongodbatlas_database_user.jpmc-search-index.username} ${mongodbatlas_database_user.jpmc-search-index.password} ${local.database} ${local.collection_name}"
  }
}


resource "mongodbatlas_search_index" "jpmc-search-index" {
  depends_on = [null_resource.jpmc-search-index]

  name   = "jpmc-search-index"
  project_id = var.mongodb_atlas_project_id
  cluster_name = mongodbatlas_cluster.jpmc-search-index.name

  analyzer = "lucene.standard"
  database = local.database
  collection_name = local.collection_name

  mappings_dynamic = true
  search_analyzer = "lucene.standard"
}
