FROM --platform=linux/amd64 ubuntu:20.04 as builder
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential libncurses-dev

ADD . /Corewar
WORKDIR /Corewar
RUN make

RUN mkdir -p /deps
RUN ldd /Corewar/asm | tr -s '[:blank:]' '\n' | grep '^/' | xargs -I % sh -c 'cp % /deps;'

FROM ubuntu:20.04 as package

COPY --from=builder /deps /deps
COPY --from=builder /Corewar/asm /Corewar/asm
ENV LD_LIBRARY_PATH=/deps
