FROM linuxserver/rdesktop:ubuntu-xfce

RUN apt-get update && apt-get install -y \
  openssh-server \
  && rm -rf /var/lib/apt/lists/*

# Configure ssh service using S6 overlay
RUN mkdir -p /etc/s6-overlay/s6-rc.d/svc-ssh/dependencies.d \
  && echo "longrun" > /etc/s6-overlay/s6-rc.d/svc-ssh/type \
  && touch /etc/s6-overlay/s6-rc.d/svc-ssh/dependencies.d/init-services \
  && touch /etc/s6-overlay/s6-rc.d/user/contents.d/svc-ssh \
  && echo "#!/bin/bash\nmkdir -p /run/sshd\nssh-keygen -A\nexec /usr/sbin/sshd -D -e" > /etc/s6-overlay/s6-rc.d/svc-ssh/run \
  && chmod +x /etc/s6-overlay/s6-rc.d/svc-ssh/run
