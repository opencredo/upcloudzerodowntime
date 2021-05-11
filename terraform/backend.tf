terraform {
  backend "remote" {
    organization = "wapbot"

    workspaces {
      name = "upcloudzerodowntime"
    }
  }
}

