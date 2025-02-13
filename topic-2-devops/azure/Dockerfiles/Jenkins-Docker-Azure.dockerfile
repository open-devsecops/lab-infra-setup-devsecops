# 1. 
# FROM jenkins/jenkins:lts
# USER root

# # Install Docker Client
# RUN apt-get update -qq \
#     && apt-get install -qqy apt-transport-https ca-certificates curl gnupg2 software-properties-common
# RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
# RUN add-apt-repository \
#    "deb [arch=amd64] https://download.docker.com/linux/debian \
#    $(lsb_release -cs) \
#    stable"
# RUN apt-get update  -qq \
#     && apt-get -y install docker-ce

# RUN usermod -aG docker jenkins

# # Install Azure CLI
# RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# 2. 
# FROM jenkins/jenkins:lts
# USER root

# # 安装基础工具
# RUN apt-get update -qq && \
#     apt-get install -qqy \
#     apt-transport-https \
#     ca-certificates \
#     curl \
#     gnupg2 \
#     software-properties-common

# # 添加 Docker 官方 GPG 密钥
# RUN mkdir -m 0755 -p /etc/apt/keyrings && \
#     curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# # 设置 Docker 仓库
# RUN echo \
#     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
#     $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
#     tee /etc/apt/sources.list.d/docker.list > /dev/null

# # 安装 Docker 组件
# RUN apt-get update -qq && \
#     apt-get install -y \
#     docker-ce-cli \
#     containerd.io \
#     docker-buildx-plugin

# # 将 jenkins 用户加入 docker 组
# RUN usermod -aG docker jenkins

# # 安装 Azure CLI
# RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

FROM --platform=linux/amd64 jenkins/jenkins:lts
USER root

# 1. 安装基础工具
RUN apt-get update -qq && \
    apt-get install -qqy \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common

# 2. 添加 Docker 官方存储库
RUN mkdir -m 0755 -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 3. 配置 Docker 源列表
RUN echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. 安装 Docker 组件（包含组创建）
RUN apt-get update -qq && \
    apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin

# 5. 创建 docker 组（可选安全步骤）
RUN groupadd -r docker || true

# 6. 将 jenkins 用户加入 docker 组
RUN usermod -aG docker jenkins

# 7. 安装 Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash