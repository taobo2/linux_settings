FROM ubuntu:20.04

COPY * /root/setting/

RUN cd /root/setting/ && ./setup.sh -f && ./tools.sh

CMD ["bash"]
