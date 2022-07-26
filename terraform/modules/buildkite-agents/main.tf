# create linux aws instances (if platform is linux)
resource "aws_instance" "linux" {
  ami                    = data.aws_ami.ami.id
  count                  = var.platform == "linux" ? var.instance_count : 0
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name
  user_data = templatefile("${path.module}/files/linux_bootstrap.tpl.sh", {
    buildkite_agent_token = "${var.buildkite_agent_token}"
    hostname              = "${var.project_id}-${var.id}-${format("%02d", count.index + 1)}"
  })
  root_block_device {
    volume_size = 30
  }
  tags = {
    Name     = "${var.project_id}-${var.id}-${format("%02d", count.index + 1)}"
    hostname = "${var.project_id}-${var.id}-${format("%02d", count.index + 1)}"
  }
}
