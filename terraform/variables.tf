# The password for the database
variable "db_password" {
  # A description of the variable
  description = "The password for the database"
  # The type of the variable
  type        = string
  # Whether the variable is sensitive
  sensitive   = true
}
