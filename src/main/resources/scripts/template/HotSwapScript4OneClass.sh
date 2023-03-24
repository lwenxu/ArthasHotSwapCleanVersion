#Copyright (c) 2020, 2021, xxxtai. All rights reserved.
#!/usr/bin/env bash

echo "1. Prepare the workspace*"
if [ ! -d "./arthas-hot-swap" ]
then
  mkdir ./arthas-hot-swap
  echo "> ./arthas-hot-swap create success"
else
  rm -rf ./arthas-hot-swap
  mkdir ./arthas-hot-swap
  echo "> ./arthas-hot-swap recreate"
fi
cd ./arthas-hot-swap
rm -f $(pwd)/arthas-hot-swap-result

echo "2. install openssl"
openssl version > /dev/null
if [[ $? -eq 0 ]]; then
    echo "> openssl has been installed successfully "
else
    echo "> install openssl "
    sudo yum install openssl openssl-devel
fi

echo "3. Download the encrypted file"
curl  %[currentClassOssUrl] >> encrypt-%[className].txt

echo "4. Encrypt the file"
openssl enc -aes-128-cbc -a -d -in encrypt-%[className].txt -out %[className].class -K $1 -iv $2

echo "5. Install arthas"
specifyJavaHome=%[specifyJavaHome]
arthas_start_cmd=''

if [[ ${specifyJavaHome} == '' ]]
then
    curl -L https://arthas.aliyun.com/install.sh | sh
    arthas_start_cmd='./as.sh'
else
    curl -O https://arthas.aliyun.com/arthas-boot.jar
    arthas_start_cmd=${specifyJavaHome}" -jar arthas-boot.jar"
fi

selectJavaProcessName=%[selectJavaProcessName]

if [[ ${selectJavaProcessName} != '' ]]
then
    arthas_start_cmd=${arthas_start_cmd}" --select "${selectJavaProcessName}
fi

echo "6. Create a pipeline"
rm -f tmp_in
mknod tmp_in p
exec 8<> tmp_in
${arthas_start_cmd} <&8 &

echo "7. Choose the java process"
sleep 1s
echo "
" >> tmp_in

echo "8. Redefine the class"
sleep 3s
echo "retransform $(pwd)/%[className].class > $(pwd)/arthas-hot-swap-result" >> tmp_in
sleep 2s
echo "quit" >> tmp_in

swapResult=$(cat $(pwd)/arthas-hot-swap-result | grep "success")
echo $swapResult
if [[ $swapResult != "" ]]
then
echo '%[className].class success'
else
echo '%[className].class fail'
cat $(pwd)/arthas-hot-swap-result
fi

