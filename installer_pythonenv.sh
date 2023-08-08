#!/bin/bash

main() {
    # 按照步骤依次执行
    detect_os # 检测操作系统的函数
    python_binary_status=$(detect_python_binary)
    required_version="3.9.0"
    python_binary="python"
    new_path="/usr/local"
    base_binary="/usr/bin"
    
    packagenames=("zlib-devel" "gcc" "make" "libffi-devel" "bzip2-devel" "ncurses-devel" "gdbm-devel" "sqlite-devel" "tk-devel" "uuid-devel" "readline-devel")
    for pkg in "${packagenames[@]}"; do
        if rpm -qa | grep -q "$pkg"; then
            echo "$pkg is already installed."
        else
            install_pack "$pkg"
        fi
    done

    if [ "$python_binary_status" -eq 0 ]; then
        echo "Python3 is not installed."
    elif [ "$python_binary_status" -eq 1 ]; then
        echo "Python3 is installed,Starting checking the version of python3,Plz wait"
        version_compare
    fi

    download_package
}

# 检测Python版本
# 测试用例 传常数 3.6.8
version_compare() {
    python_version=$(python3 --version 2>&1 | awk '{print $2}')
    if [ "$(version_compare_internal "$python_version" "$required_version")" -eq 1 ]; then
        echo "Current Python version is $python_version, upgrading to $required_version..."

    else
        echo "Python is up to date ($python_version). No need to upgrade."
    fi
}

# 检测Python3解释器是否存在的函数
detect_python_binary() {
    if [ ! -e /usr/bin/python3 ]; then
        echo 0 # Python3解释器不存在
    else
        echo 1 # Python3解释器存在
    fi
}

# 比较版本号函数
version_compare_internal() {
    v1=$1
    v2=$2
    if [[ $(echo -e "$v1\n$v2" | sort -V | head -n1) == "$v1" ]]; then
        echo 1 # 如果等于版本1 调用第一个变量
    elif [[ $(echo -e "$v1\n$v2" | sort -V | head -n1) == "$v2" ]]; then
        echo -1 # 如果等于版本2 调用第二个变量
    else
        echo 0 # 
    fi
}

# 检测操作系统类型的函数
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=${ID}
    elif [ -f /etc/centos-release ]; then
        OS_NAME="centos"
    else
        OS_NAME="unknown"
    fi
}

# 安装包的函数
install_pack() {
    package="$1"
    if [ "$OS_NAME" == "ubuntu" ]; then
        echo "apt-get install $package on $OS_NAME..."
        # 在这里执行Ubuntu系统下的安装操作，例如：
        # sudo apt-get install "$package"
    elif [ "$OS_NAME" == "centos" ] || [ "$OS_NAME" == "alinux" ]; then
        echo "yum install $package on $OS_NAME..."
        # 在这里执行CentOS或Alibaba Linux系统下的安装操作，例如：
        sudo yum install -y "$package"
    else
        echo "Unsupported operating system: $OS_NAME"
    fi
}

# 下载Python3.9函数
download_package() {
    convert_name=$(echo "$python_binary" | cut -c1 | tr 'a-z' 'A-Z')
    rest_name=$(echo "$python_binary" | cut -c2-)
    mix_name="$convert_name$rest_name"
    tar_ball="$mix_name-$required_version.tar.xz"

    wget "https://www.python.org/ftp/$python_binary/$required_version/$tar_ball"
    xz -d "$tar_ball"

    TAR_RELEASE=$(tar xvf "$mix_name-$required_version.tar")
    echo "TAR_RELEASE: $TAR_RELEASE"
    echo "$mix_name-$required_version $python_binary-$required_version"

    mv $mix_name-$required_version $new_path/$python_binary-$required_version
    cd $new_path/$python_binary-$required_version

    # 编译安装
    ./configure
    make && make install

    if [ "$python_binary_status" -eq 1 ]; then
        echo "Start to remove the python3 binary symlinks..."
        rm $base_binary/python3
    fi

    ln -s "$new_path/bin/python3.9" "/usr/bin/python3"

    python3 -m ensurepip
    python3 -m pip install --upgrade pip
    pip3 install --upgrade setuptools

    version_command="$new_path/bin/python3 -V"
    eval "$version_command"
}

# 调用主函数
main
