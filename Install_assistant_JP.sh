#!/bin/bash
#Install assistant(Docker)

Env_inspection(){
    USER=`whoami`
    if [ "${USER}" != "root" ]
        then
			echo >&2 'Restart with root authority.'
        　　su root -c ${0} 
        else
			echo 'Started with root privilege.'
    fi
    architecture=$(uname -m)
	case $architecture in
		x86_64)
			;;
		*)
			echo >&2 'Error: $architecture is not a recognized platform.'
			exit 1
			;;
	esac
}
Install_Docker() {
	echo "既存のDockerを消去中"
	yum -y remove dockere  >/dev/null 2>&1
	yum -y remove docker-engine >/dev/null 2>&1
	echo "yum-utilsをインストール中"
	yum -y install yum-utils >/dev/null 2>&1
	echo "Dockerをインストール中"
	echo -e ' 20%[!----]'"\r\c"
	yum-config-manager \
		--add-repo \
		https://download.docker.com/linux/centos/docker-ce.repo \
		 >/dev/null 2>&1
	echo -e ' 40%[!!---]'"\r\c"
	yum-config-manager --enable docker-main >/dev/null 2>&1
	echo -e ' 60%[!!!--]'"\r\c"
	yum makecache fast >/dev/null 2>&1
	echo -e ' 80%[!!!!-]'"\r\c"
	yum -y install docker-engine >/dev/null 2>&1
	echo -e ' 100%[!!!!!]'
	#yum list docker-engine.x86_64  --showduplicates |sort -r
	echo 'Dockerを起動'
	systemctl start docker >/dev/null 2>&1
	#docker run hello-world
	echo 'Dockerサービスを登録'
	systemctl enable docker.service >/dev/null 2>&1
	echo "インストール完了しました"
}
Remove_Dcoker(){
	echo -e ' 20%[!----]'"\r\c"
	systemctl disable docker.service >/dev/null 2>&1
	echo -e ' 40%[!!---]'"\r\c"
	systemctl stop docker >/dev/null 2>&1
	echo -e ' 60%[!!!--]'"\r\c"
	yum -y remove docker-engine >/dev/null 2>&1
	echo -e ' 80%[!!!!-]'"\r\c"
	yum-config-manager --disable docker-main >/dev/null 2>&1
	echo -e ' 100%[!!!!!]'
	echo "アンインストールが終わりました"
}
update_docker(){
	output=(` yum list docker-engine.x86_64  --showduplicates \
	| grep docker \
	| awk '{print $2;}' \
	| awk -F- '{print $1"."$2 }' \
	| tr -s '\n''' `)
	output_num=(` IFS=$'\n' ; echo "${output[*]}" \
	| awk -F. '{print sprintf("%d%03d%03d%03d",$1,$2,$3,$4)}' \
	| tr -s '\n''' `) 
	output_name=(` IFS=$'\n' ; echo "${output[*]}" \
	| awk -F. '{print sprintf("%s.%s.%s-%s.%s.%s",$1,$2,$3,$4,$5,$6)}' \
	| tr -s '\n''' `) 
	OP_e=$((${#output_num[@]}-1))
	if [[ ${output_num[0]} -lt ${output_num[ $OP_e ]} ]]
		then
			echo "-------------更新があります-------------"
			echo "現在のバージョン＞" ${output_name[0]}
			echo "最新のバージョン＞" ${output_name[ $OP_e ]}
			YN_select
			echo "更新中…"
			yum update -y docker-engine >/dev/null 2>&1
			echo "更新が完了しました"
		else
			echo "----------Dockerは最新状態です----------"
			echo "現在のバージョン" ${output_name[0]}
	fi
}
change_docker(){
	yum makecache fast >/dev/null 2>&1
	output=(` yum list docker-engine.x86_64  --showduplicates \
	| grep docker \
	| awk '{print $2;}' \
	| awk -F- '{print $1"."$2 }' \
	| tr -s '\n''' `)
	output_num=(` IFS=$'\n' ; echo "${output[*]}" \
	| awk -F. '{print sprintf("%d%03d%03d%03d",$1,$2,$3,$4)}' \
	| tr -s '\n''' `) 
	output_code=(` IFS=$'\n' ; echo "${output[*]}" \
	| awk -F. '{print sprintf("%s.%s.%s-%s.%s.%s",$1,$2,$3,$4,$5,$6)}' \
	| tr -s '\n''' `) 
	output_name=(` IFS=$'\n' ; echo "${output[*]}" \
	| awk -F. '{print sprintf("%s.%s.%s-%s",$1,$2,$3,$4)}' \
	| tr -s '\n''' `) 
	OP_e=$((${#output_num[@]}-1))
	now_version=NULL
	for (( i=0; i<${#output_num[@]}; i++ ))
	do
		if (( output_num[0] == output_num[ $i ] )) ; then
				((now_version=$i+1))
		fi
	done
	printf '\n------------------------------現在のバージョンは%sです。------------------------------\n' ${output_name[0]}
	column_count=0
	for (( i=0; i<${#output_num[@]}; i++ ))
	do
		if (( column_count > 5 )) ; then
				echo -e "\n"
				column_count=0
		fi
		echo -n "  "
		if (($i+1 == now_version)) ; then
			printf '\e[37m' #'\e[37m\e[47m'
		elif (($i+1 < now_version)) ; then
			printf '\e[33m'
		elif (($i+1 > now_version)) ; then
			printf '\e[36m'
		fi
		printf '%2d ) ' "$(($i+1))"
		printf '%8s' "${output_name[ $i ]}"
		printf '\e[0m'
		((column_count++))
	done
	echo -e "\n"
	num=GO
	while [[ $num == "GO" ]] ; do
		CV=NULL
		printf '変更したいバージョンを選択してください[1-%d/n]:' ${#output_num[@]} 
		read CV
		if [[ $CV == "n" ]] || [[ $CV == "N" ]] ; then
			num=END
		elif (($CV==now_version)) ; then
			echo "現在のバージョンと同じです。"
			num=END
		elif (($CV > now_version)) && (($CV <= ${#output_num[@]})) ; then
			printf '%sにアップデートします\n(現在のバージョンは%sです)\n' ${output_name[ $CV-1 ]} ${output_name[0]}
			YN_select
			printf '%sにアップデート中\n' ${output_name[ $CV-1 ]}
			yum update -y docker-engine-${output_code[ $CV-1 ]} >/dev/null 2>&1
			echo "アップデートしました。"
			num=END
		elif (($CV < now_version)) && (($CV > 0)) ; then
			printf '%sにダウングレードします\n(現在のバージョンは%sです)\n' ${output_name[ $CV-1 ]} ${output_name[0]}
			YN_select
			printf '%sにダウングレード中\n' ${output_name[ $CV-1 ]}
			yum downgrade -y docker-engine-${output_code[ $CV-1 ]} >/dev/null 2>&1
				echo "ダウングレードしました。"
			num=END
		fi
	done
}
main_ui(){
	cat <<-EOF
	######################################################
	# CentOS用
	# Docker操作ツール :version 1
	# 
	# 1) Docker一式をインストール
	# 2) Dockerのアンインストール
	# 3) Dockerのバージョン確認
	# 4) Dockerのアップデート
	# 5) Dockerを除いてアップデート
	# 6) Dockerのバージョン変更
	# E) 終了
	######################################################
	EOF
}
YN_select(){
	local YN=NULL
	until [[ $YN == "y" ]] ||[[ $YN == "Y" ]] || [[ $YN == "n" ]] || [[ $YN == "N" ]]
		do
			echo -n "上記の処理を行います。よろしいでしょうか？ [y/N]"
			read YN
		done
	case "$YN" in
		y | Y)
		;;
		n | N)
			main
		;;
	esac
}
main(){

	In_Se=NULL
	echo -n "実行したい番号を入力してください:"
    read In_Se
	case "$In_Se" in
		1)
			echo "----------------------------------------------------------"
			echo "Dockerの動作に必要なソフトのインストールや設定を行います。"
			YN_select
			Install_Docker
		;;
		2)
			cat <<-EOF
			-----------------Dockerのアンインストールを行います。-----------------
			＊Dockerをインストールした時に一緒にインストールされたものは消えません。＊
			EOF
			YN_select
			Remove_Dcoker
		;;
		3)
			docker -v >/dev/null 2>&1
			ver=$?
			if [ $ver == 0 ]
				then
					echo "------------現在のバージョン------------"
					docker -v
				else
					echo "------------------------------------"
					echo "Dockerはインストールされていないようです。"
			fi
		;;
		4)
			docker -v >/dev/null 2>&1
			ver=$?
			if [ $ver == 0 ]
				then
					update_docker
				else
					echo "------------------------------------"
					echo "Dockerはインストールされていないようです。"
			fi
		;;
		5)
			echo "Dockerを除いてアップデートを行います。"
			YN_select
			yum update --exclude=docker*
		;;
		6)
			docker -v >/dev/null 2>&1
			ver=$?
			if [ $ver == 0 ]
				then
					change_docker
				else
					echo "------------------------------------"
					echo "Dockerはインストールされていないようです。"
			fi
		;;
		E | e)
			echo "終了します"
			exit 0
		;;
		*)
		;;
	esac
	main
}
Env_inspection
main_ui
main