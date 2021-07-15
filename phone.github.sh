#!/bin/bash

rootDir=$(dirname $(readlink -f "$0"))
logsDir="${rootDir}/py_logs"
htmlDir="${rootDir}/py_html"
logFile="${logsDir}/phone.$(date -d today +'%Y-%m-%d').log"
[[ ! -d "${logsDir}" ]] && (mkdir "${logsDir}")
[[ ! -d "${htmlDir}" ]] && (mkdir "${htmlDir}")
if ! type jq &>/dev/null; then
    if type yum &>/dev/null; then
        yum install jq
    elif type sudo &>/dev/null; then
        sudo apt-get install jq
        sudo snap install jq
    fi
fi

gsd="-"
gsdOld=""
goonNext=0

myEcho () {
    st="$(date '+%Y-%m-%d %H:%M:%S') ${1}"
    echo "${st}"
    echo "${st}" >>${logFile}
}

provinceInBack () {
    province=(安徽 河北 山西 辽宁 吉林 黑龙江 江苏 浙江 福建 江西 山东 河南 湖北 湖南 广东 海南 四川 贵州 云南 陕西 甘肃 青海 台湾 内蒙古 广西 西藏 宁夏 新疆)
    if [[ "${province[@]}" =~ "${1}" ]]; then
        echo "1"
    else
        echo "0"
    fi
}

add0 () {
    num=${1}
    for ((i=0; i<(4-${#1}); i++)); do
        num="0${num}"
    done
    echo "${num}"
}

setNext () {
    echo ${mob_next} >${phoneN}
}

doGsd () {
    i=0
    while ( [ ! -f "${phoneD}" ] && [ ${i} -lt ${phoneNumLimit} ] ); do
        ((i+=1))
        curl -s -o "${phoneD}" -k -G -d "op=insert" -d "val=%7B%22tel%22:%22${phone}%22,%22gsd%22:%22${1}%22%7D" "${API_URL}"
        myEcho "GSD insert 第 ${i} 次 等待 1 秒"
        sleep 1
    done
    strDone=$(cat "${phoneD}")
    rm -f "${phoneD}"
    myEcho "${strDone}"
    if [[ -n "${strDone}" ]]; then
        setNext
    else
        myEcho "本次操作号码 【${phone}】 失败"
    fi
}

curlCHB () {
    i=0
    while ( [ ! -f "${phoneP}" ] && [ ${i} -lt ${phoneNumLimit} ] ); do
        ((i+=1))
        cur_sec=`date '+%s'`
        curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36" \
            -H "Referer: ${API_URL_CHB}%E9%A6%96%E9%A1%B5" \
            -s -o "${phoneP}" -k \
            "${API_URL_CHB}${phone}?${cur_sec}"
        myEcho "CHB ${phone}?${cur_sec} 第 ${i} 次 等待 1 秒"
        sleep 1
        if [[ ! -f "${phoneP}" ]]; then
            if [[ ${i} = 3 ]]; then
                echo >${phoneP}
                myEcho "CHB ${phone}?${cur_sec} 第 ${i} 次 跳过号码【${phone}】"
            else
                chbMin=`awk -v x=0.1 -v y=60 'BEGIN{printf "%.0f\n",x*y}'`
                chbMax=`awk -v x=0.3 -v y=60 'BEGIN{printf "%.0f\n",x*y}'`
                chbRand=$[$RANDOM%$((${chbMax}-${chbMin}+1))+${chbMin}]
                chbNext=$(date --date="${chbRand} second" '+%Y-%m-%d %H:%M:%S')
                myEcho "CHB ${phone}?${cur_sec} 第 ${i} 次 未获取到 等待 ${chbRand} 秒 下次操作: ${chbNext}"
                sleep ${chbRand}
            fi
        else
            myEcho "CHB ${phone}?${cur_sec} 第 ${i} 次 获取到号码【${phone}】GSD"
        fi
    done
}

getGsd () {
    curlCHB
    test_0=$(cat "${phoneP}")
    if [[ "${test_0}" ]]; then
        numSize=$(ls -l "${phoneP}" | awk '{ print $5 }')
        strFound=$(echo ${test_0} | grep "本站中目前没有找到${phone}页面。")
        strCached=$(echo ${test_0} | grep "This is a cached copy of the requested page")
        str400=$(echo ${test_0} | grep "400 Bad Request")
        str4002=$(echo ${test_0} | grep "HTTP Error 400")
        str403=$(echo ${test_0} | grep "403 Forbidden")
        str502=$(echo ${test_0} | grep "502 Bad Gateway")
        str5022=$(echo ${test_0} | grep "网关错误，连接源站失败")
        str521=$(echo ${test_0} | grep "521 Origin Down")
        str522=$(echo ${test_0} | grep "522 Origin Connection Time-out")
        str524=$(echo ${test_0} | grep "524 Origin Time-out")
        str525=$(echo ${test_0} | grep "525 Origin SSL Handshake Error")
        if [[ "${strFound}" ]]; then
            myEcho "未获取到号码【${phone}】GSD，可能号码格式错误"
        else
            if [[ "${strCached}" ]] && [[ ${numSize} -lt 4096 ]]; then
                myEcho "未获取到号码【${phone}】GSD，页面缓存未更新"
            else
                if [[ "${str400}" ]]; then
                    myEcho "未获取到号码【${phone}】GSD，查号吧 400 错误"
                else
                    if [[ "${str4002}" ]]; then
                        myEcho "未获取到号码【${phone}】GSD，查号吧 400 百度云加速 错误"
                    else
                        if [[ "${str403}" ]]; then
                            myEcho "未获取到号码【${phone}】GSD，查号吧 403 错误"
                        else
                            if [[ "${str502}" ]]; then
                                myEcho "未获取到号码【${phone}】GSD，查号吧 502 错误"
                            else
                                if [[ "${str5022}" ]]; then
                                    myEcho "未获取到号码【${phone}】GSD，查号吧 502 百度云加速 错误"
                                else
                                    if [[ "${str521}" ]]; then
                                        myEcho "未获取到号码【${phone}】GSD，查号吧 521 错误"
                                    else
                                        if [[ "${str522}" ]]; then
                                            myEcho "未获取到号码【${phone}】GSD，查号吧 522 错误"
                                        else
                                            if [[ "${str524}" ]]; then
                                                myEcho "未获取到号码【${phone}】GSD，查号吧 524 错误"
                                            else
                                                if [[ "${str525}" ]]; then
                                                    myEcho "未获取到号码【${phone}】GSD，查号吧 525 错误"
                                                else
                                                    test_1=$(echo ${test_0} | sed -r 's/.*归属省份地区：(.*)<\/li> <li> 电信运营商：.*/\1/g')
                                                    if [[ "${test_1}" ]]; then
                                                        strF2=$(echo ${test_1} | grep "、")
                                                        if [[ "${strF2}" = "" ]]; then
                                                            test_2=$(echo ${test_1} | sed -r 's/<a href=".*" class="extiw" title="link:.*">(.*)<\/a>/\1/g')
                                                            gsd="${test_2}-${test_2}"
                                                        else
                                                            #arr=(`echo ${test_1} | tr ' ' '#' | tr '、' ' '`)
                                                            res=()
                                                            oldIFS=$IFS
                                                            IFS=、
                                                            arr=(${test_1})
                                                            for ((i=0; i<${#arr[@]}; i++)); do
                                                                res[i]=$(echo ${arr[$i]} | sed -r 's/<a href=".*" class="extiw" title="link:.*">(.*)<\/a>/\1/g')
                                                            done
                                                            IFS=$oldIFS
                                                            gsd="${res[0]}-${res[1]}"
                                                            if [[ "${res[1]}" != "重庆" ]]; then
                                                                if [[ "${gsd}" != "青海-海南" ]] && [[ "${gsd}" != "吉林-吉林" ]] && [[ $(provinceInBack "${res[1]}") = "1" ]]; then
                                                                    gsd="${res[1]}-${res[0]}"
                                                                fi
                                                            else
                                                                gsd="${res[1]}-${res[0]}"
                                                            fi
                                                        fi
                                                    fi
                                                fi
                                            fi
                                        fi
                                    fi
                                fi
                            fi
                        fi
                    fi
                fi
            fi
        fi
    else
        myEcho "未获取到号码【${phone}】源码"
    fi
    rm -f "${phoneP}"
    myEcho "获取到号码【${phone}】的GSD为【${gsd}】"
    #if [[ "${gsd}" != "-" ]]; then
        #doGsd "${gsd}"
    #fi
    doGsd "${gsd}"
}

goonGsd () {
    goonNext=0
    status=$(echo ${jsonG} | jq ".status")
    msg=$(echo ${jsonG} | jq ".msg")
    gsdOld=${msg}
    myEcho "查询号码 【${phone}】，GSD为【${gsdOld}】"
    if [[ ${status} = '"bad"' ]]; then
        myEcho "bad"
        getGsd
    elif [[ ${status} = '"ok"' ]] && [[ ${msg} = '"-"' ]]; then
        myEcho "ok && -"
        getGsd
    else
        setNext
        goonNext=1
    fi
}

curlPhone () {
    i=0
    while ( [ ! -f "${phoneG}" ] && [ ${i} -lt ${phoneNumLimit} ] ); do
        ((i+=1))
        curl -s -o "${phoneG}" -k -G -d "op=getOne" -d "tel=${phone}" "${API_URL}"
        myEcho "GSD getOne 第 ${i} 次 等待 1 秒"
        sleep 1
    done
}

. phone.inc.sh
((phoneNL=${phoneNumLimit}*5))
phoneI="./phone.i.txt"
[[ ! -f ${phoneI} ]] && (echo 0 >${phoneI})
numI=$(cat "${phoneI}")
if [[ ${numI} -eq ${phoneNL} ]]; then
    rm -f "${phoneI}"
    exit 0
fi
((numI_next=${numI}+1))
myEcho "开始第 ${numI_next} 次操作"

phoneN="./phone.txt"
if [[ "${phoneOrder}" == "asc" ]]; then
    [[ ! -f ${phoneN} ]] && (echo 0 >${phoneN})
    phoneStart=$(cat "${phoneN}")
    if [[ "${phoneStart}" == "10000" ]]; then
        myEcho "号码【${phoneLeft}${phoneCenter}（0000 ---> 9999）】处理完毕"
        exit 0
    fi
    ((mob_next=${phoneStart}+1))
else
    [[ ! -f ${phoneN} ]] && (echo 9999 >${phoneN})
    phoneStart=$(cat "${phoneN}")
    if [[ "${phoneStart}" == "-1" ]]; then
        myEcho "号码【${phoneLeft}${phoneCenter}（9999 ---> 0000）】处理完毕"
        exit 0
    fi
    ((mob_next=${phoneStart}-1))
fi
echo -e >>${logFile}
echo
phone=${phoneLeft}${phoneCenter}$(add0 "${phoneStart}")
phoneG="${htmlDir}/${phone}.get.html"
phoneD="${htmlDir}/${phone}.do.html"
phoneP="${htmlDir}/${phone}.html"
myEcho "开始操作号码 【${phone}】"
curlPhone
jsonG=$(cat "${phoneG}")
myEcho "查询号码 【${phone}】，返回信息 ${jsonG}"
if [[ -z "${jsonG}" ]]; then
    myEcho "查询失败，1 秒后重新查询"
    sleep 1
    curlPhone
    jsonG=$(cat "${phoneG}")
    myEcho "查询号码 【${phone}】，返回信息 ${jsonG}"
    if [[ -z "${jsonG}" ]]; then
        myEcho "查询失败，结束本次操作，期待下次成功~"
    else
        goonGsd
    fi
else
    goonGsd
fi
rm -f "${phoneG}"
if [[ ${goonNext} -ne 1 ]]; then
    echo ${numI_next} >${phoneI}
    if [[ ${numI_next} -lt ${phoneNL} ]]; then
        numMin=`awk -v x=0.1 -v y=60 'BEGIN{printf "%.0f\n",x*y}'`
        numMax=`awk -v x=0.3 -v y=60 'BEGIN{printf "%.0f\n",x*y}'`
        numRand=$[$RANDOM%$((${numMax}-${numMin}+1))+${numMin}]
        timeNext=$(date --date="${numRand} second" '+%Y-%m-%d %H:%M:%S')
        myEcho "下次操作: ${timeNext}"
        echo -e >>${logFile}
        echo
        sleep ${numRand}
    else
        echo -e >>${logFile}
        echo
    fi
else
    echo -e >>${logFile}
    echo
fi
exec ./phone.github.sh
