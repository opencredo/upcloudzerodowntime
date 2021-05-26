# Reducing Terraform Deployment Downtime

This GitHub repo demonstrates the usage of a couple Terraform features that can reduce the downtime or
unavailability of Terraform managed resources. For this demonstration we've built an extremely simple
Go HTTP server. We package this server into a custom machine image using [Packer](https://www.packer.io)
and the [UpCloud](https://upcloud.com) Packer [plugin](https://github.com/UpCloudLtd/packer-plugin-upcloud).
This custom image is deployed on to an UpCloud server using Terraform.

## Repo Structure

This is a monorepo and all code is available here. These are the directories of interest:

* `go` - Our Go HTTP server.
* `packer` - Our Packer configuration
  * `packer/artefact` - Artefacts (scripts and systemd units) that are installed on the custom
    machine image.
* `terraform` - Our Terraform configuration
* `.github/workflows` - Our [GitHub Actions](https://github.com/features/actions) workflow

###  CI/CD

This project makes use of GitHub Actions and [Terraform Cloud](https://www.terraform.io/cloud) to deploy new version
of the demo application after every commit.

#### GitHub Action

GitHub Actions is a CI/CD tool baked into GitHub allowing us to define workflows for our code in the same
repository as the code itself.

The GitHub Action workflow doesn't change throughout the demo. It consists of 4 jobs:

* `build` - Build the Go HTTP server and push the artefact to GitHub Artifact cache. This is a fairly vanilla
  Go build job.
* `image` - Build the custom machine image using Packer. We are using the
  [`hashicorp-contib/setup-packer`](https://github.com/hashicorp-contrib/setup-packer) action as we also install a
  Packer plugin manually.
* `terraform` - This is a fairly vanilla Terraform build job but we do use the [`upctl`](https://github.com/UpCloudLtd/upcloud-cli) CLI tool to determine the latest custom machine image name.
* `image_tidy` - This use the `upctl` CLI tool to delete all but that last 5 images.

To replicate this workflow you will need to do the following in a fork of this repo:

* Edit `.github/workflows/build.yaml` and change `UPCLOUD_USERNAME` environment variables to a user that exists
  in your UpCloud account. I recommend creating a new user.
* Set the `UPCLOUD_API_PASSWORD` GitHub secret to the password for the above UpCloud user.
* Edit `terraform/backend.tf` and change the `organization` and `workspace/name` values to those that match your
  Terraform Cloud setup.
* Set the `TF_API_TOKEN` secret to your Terraform Cloud API token.

#### Terraform Cloud

Terraform Cloud is a managed service from HasiCorp that will run our Terraforom applies and manage and secure our
infrastructure state. It eliminates the need for custom tooling to manage Terraform in production. When running Terraform
in a CI/CD pipeline we need to be able to store our remote state, this is one of the reasons we are using Terrafrom Cloud.

To replicate this workflow you will need to do the following (assuming you've signed up to Terrafrom Cloud):

* Optionally, create a new organisation. You will need this to configure GitHub Actions.
* Create a new workspace. You will need this to configure GitHub Actions.
* Create a new Terraform Cloud API token for your user. You will also need this to configure GitHub Actions.
* In the workspace variable tab set these environment variables:
  * `UPCLOUD_USERNAME` - The name of a user within your account. I recommend creating a new user.
  * `UPCLOUD_PASSWORD` - The password of the above user. Remember to tick the 'sensitive' checkbox.

#### Packer

If you are following along the Packer configuration installs an SSH public key `packer/artefact/id_rsa_upcloud.pub`
which is useful for my debugging but you should replace this with the public part of a private SSH key you generate.

#### CI/CD Conclusion

With the above changes you should be able use the GitHub Action workflow to build and run your own experiments.

## Initial State (tag: [1.0](https://github.com/opencredo/upcloudzerodowntime/tree/1.0))

### Go HTTP Server

In this initial state we only ever respond with a simple "`(1.0) Hello, "/"`" message. This is a snippet of the code
that does this:

```go
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "(%s) Hello, %q", Version, html.EscapeString(r.URL.Path))
	})
```

### Packer

In the initial state we are using the file `provisioner` to copy across the following pertinent files:
* `demoapp` - Our HTTP server.
* `demoapp.service` - A systemd unit that starts the HTTP server when the machine comes up.

We then use a shell `provisioner` to:
* Update the server to the latest available packages.
* Copy the files above to their correct locations and give them the correct ownership and permissions
* Enable the `demoapp.service` systemd unit

Finally, a [Goss](https://goss.rocks/) provisioner is used that will use the `packer/artefact/goss.yaml` server
specification file to ensure that the resultant image matches what we are expecting.

### Terraform

The initial Terraform is really simple:

```terraform
resource "upcloud_server" "app" {
  hostname = "myapplication.com"
  zone     = "uk-lon1"
  plan     = "1xCPU-1GB"

  template {
    storage = var.template_id
    size    = 25
  }

  network_interface {
    type = "public"
  }
}
```

We are simply deploying an UpCloud server in the London region with a public IP using our newly create machine image.

### Experiment

If we were commit our code and config at this point it should all deploy nicely. We can determine the IP address of our
server by using the `upctl` CLI tool (this snippet assumes you only have 1 server in your account):

```bash
$ upctl server show $(upctl server list -o json | jq '.[0] | .uuid' -r)

  
  Common
    UUID:          0099b58a-c5f5-4a39-b63e-f6120d701f74     
    Hostname:      myapplication.com                        
    Title:         myapplication.com (managed by terraform) 
    Plan:          1xCPU-1GB                                
    Zone:          uk-lon1                                  
    State:         started                                  
    Simple Backup: no                                       
    Licence:       0                                        
    Metadata:      True                                     
    Timezone:      UTC                                      
    Host ID:       5767971459                               
    Tags:                                                   

  Storage: (Flags: B = bootdisk, P = part of plan)

     UUID                                   Title                              Type   Address   Size (GiB)   Flags 
    ────────────────────────────────────── ────────────────────────────────── ────── ───────── ──────────── ───────
     01bda3be-ad76-44d3-afc8-fe3d2489ae57   terraform-myapplication.com-disk   disk   ide:0:0           25   P     
    
  NICs: (Flags: S = source IP filtering, B = bootable)

     #   Type     IP Address                 MAC Address         Network                                Flags 
    ─── ──────── ────────────────────────── ─────────────────── ────────────────────────────────────── ───────
     1   public   IPv4: 94.237.121.69        ee:1b:db:ca:61:ee   03000000-0000-4000-8100-000000000000   S
```

If we curl that endpoint:

```bash
$ curl http://94.237.121.69:8080
(1.0) Hello, "/"
```

At this point it is probably worth starting something to monitor this endpoint. For this experiment I've used
[pinghttp](https://git.sr.ht/~yoink00/pinghttp) but anything allows you to see the up/down time of the
endpoint will work:

```bash
$ pinghttp -freq 1s -url http://94.237.121.69:8080

┌────────────────────────────────────────────────┐
│    Up Time     │      15s       │(1.0) Hello,  │
│────────────────────────────────────────────────│
│   Down Time    │       0s       │              │                                       └────────────────────────────────────────────────┘
```

If we bump the version number (change `const Version = "1.0"` in `go/main.go`) and push that code to GitHub
we will see our endpoint go down and never return.



