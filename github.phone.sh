#!/bin/bash

rootDir=$(dirname $(readlink -f "$0"))
logsDir="${rootDir}/py_logs"
htmlDir="${rootDir}/py_html"
logFile="${logsDir}/phone.$(date -d today +'%Y-%m-%d').log"
[[ ! -d "${logsDir}" ]] && (mkdir "${logsDir}")
[[ ! -d "${htmlDir}" ]] && (mkdir "${htmlDir}")
if ! type jq &>/dev/null; then
    if type yum &>/dev/null; then
        yum install -y jq
    elif type sudo &>/dev/null; then
        sudo apt install -y jq
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
        myEcho "GSD insert 第 ${i} 次 等待 3 秒"
        sleep 3
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

getUA () {
    tmpUA=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:107.0) Gecko/20100101 Firefox/107.0"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:106.0) Gecko/20100101 Firefox/106.0"
        "Mozilla/5.0 (Windows NT 10.0; rv:106.0) Gecko/20100101 Firefox/106.0"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:106.0) Gecko/20100101 Firefox/106.0"
        "Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:106.0) Gecko/20100101 Firefox/106.0"
        "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:106.0) Gecko/20100101 Firefox/106.0"
        "Mozilla/5.0 (Windows NT 6.1; rv:106.0) Gecko/20100101 Firefox/106.0"
        "Mozilla/5.0 (X11; Ubuntu; Linux aarch64; rv:106.0) Gecko/20100101 Firefox/106.0"
        "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:106.0) Gecko/20100101 Firefox/106.0"
        "Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Gecko/20100101 Firefox/106.0"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:105.0) Gecko/20100101 Firefox/105.0"
        "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:105.0) Gecko/20100101 Firefox/105.0"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:102.0) Gecko/20100101 Firefox/102.0"
        "Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0"
        "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:101.0) Gecko/20100101 Firefox/101.0"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:100.0) Gecko/20100101 Firefox/100.0"
        "Mozilla/5.0 (Windows NT 10.0; rv:100.0) Gecko/20100101 Firefox/100.0"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:98.0) Gecko/20100101 Firefox/98.0"
        "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Linux; Android 12; 2203129G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Mobile Safari/537.36"
        "Mozilla/5.0 (Linux; Android 12; SM-F926B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Linux; Android 11; M2003J15SC) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Mobile Safari/537.36"
        "Mozilla/5.0 (Linux; Android 8.1.0; vivo 1850) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Mobile Safari/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
        "Mozilla/5.0 (X11; CrOS x86_64 15054.115.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36"
        "Mozilla/5.0 (X11; CrOS x86_64 14909.132.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.114 Safari/537.36"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.84 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36"
        "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36"
        "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.82 Safari/537.36"
        "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.93 Safari/537.36"
        "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.93 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.54 Safari/537.36"
        "Mozilla/5.0 (X11; CrOS x86_64 14092.77.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.107 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.26"
        "Mozilla/5.0 (Windows NT 6.3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.26"
        "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.26"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.28"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36 Edg/106.0.1370.52"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36 Edg/106.0.1370.52"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36 Edg/105.0.1343.50"
        "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.124 YaBrowser/22.9.4.866 Yowser/2.5 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.124 YaBrowser/22.9.4.863 Yowser/2.5 Safari/537.36"
        "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.124 YaBrowser/22.9.4.864 Yowser/2.5 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.4.904 Yowser/2.5 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36 OPR/92.0.0.0"
        "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36 OPR/92.0.0.0"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36 OPR/91.0.4516.106"
        "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36 OPR/91.0.4516.77"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36 OPR/90.0.4480.117"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.134 Safari/537.36 OPR/89.0.4447.83"
        "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.115 Safari/537.36 OPR/88.0.4412.40"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36 OPR/86.0.4363.59"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.5249.114 Whale/3.17.145.12 Safari/537.36"
    )
    uaMin=0
    uaMax=${#tmpUA[*]}-1
    uaRand=$[$RANDOM%$((${uaMax}-${uaMin}+1))+${uaMin}]
    API_UA=${tmpUA[${uaRand}]}
}

curlCHB () {
    i=0
    while ( [ ! -f "${phoneP}" ] && [ ${i} -lt ${phoneNumLimit} ] ); do
        ((i+=1))
        cur_sec=`date '+%s'`
        curl -H "User-Agent: ${API_UA}" \
            -H "Referer: ${API_URL_CHB}%E9%A6%96%E9%A1%B5" \
            -s -o "${phoneP}" -k \
            "${API_URL_CHB}${phone}"
        myEcho "CHB ${phone}?${cur_sec} 第 ${i} 次 等待 3 秒"
        sleep 3
        if [[ ! -f "${phoneP}" ]]; then
            if [[ ${i} = 3 ]]; then
                echo >${phoneP}
                myEcho "CHB ${phone}?${cur_sec} 第 ${i} 次 跳过号码【${phone}】"
            else
                chbMin=`awk -v x=${waitMin} -v y=60 'BEGIN{printf "%.0f\n",x*y}'`
                chbMax=`awk -v x=${waitMax} -v y=60 'BEGIN{printf "%.0f\n",x*y}'`
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
        #strFound=$(echo ${test_0} | grep "本站中目前没有找到${phone}页面。")
        strError=$(echo ${test_0} | grep "源站错误")
        strFound=$(echo ${test_0} | grep "页面未找到")
        strFound2=$(echo ${test_0} | grep "号码：${phone}")
        strCached=$(echo ${test_0} | grep "This is a cached copy of the requested page")
        str400=$(echo ${test_0} | grep "400 Bad Request")
        str4002=$(echo ${test_0} | grep "HTTP Error 400")
        str403=$(echo ${test_0} | grep "403 Forbidden")
        str500=$(echo ${test_0} | grep "500 - 内部服务器错误")
        str502=$(echo ${test_0} | grep "502 Bad Gateway")
        str5022=$(echo ${test_0} | grep "网关错误，连接源站失败")
        str521=$(echo ${test_0} | grep "521 Origin Down")
        str522=$(echo ${test_0} | grep "522 Origin Connection Time-out")
        str524=$(echo ${test_0} | grep "524 Origin Time-out")
        str525=$(echo ${test_0} | grep "525 Origin SSL Handshake Error")
        if [[ "${strError}" ]]; then
            myEcho "未获取到号码【${phone}】GSD，源站错误"
        else
            if [[ "${strFound}" ]]; then
                myEcho "未获取到号码【${phone}】GSD，可能号码格式错误"
            else
                if [[ "${strFound2}" ]]; then
                    myEcho "未获取到号码【${phone}】GSD，可能号码格式错误2"
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
                                    if [[ "${str500}" ]]; then
                                        myEcho "未获取到号码【${phone}】GSD，查号吧 500 错误"
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
                                                                test_1=$(echo ${test_0} | sed -r 's/.*归属省份地区<\/th><td>(.*)<\/td><\/tr> <tr><th>电信运营商.*/\1/g')
                                                                if [[ "${test_1}" ]]; then
                                                                    strF2=$(echo ${test_1} | grep "、")
                                                                    if [[ "${strF2}" = "" ]]; then
                                                                        test_2=$(echo ${test_1} | sed -r 's/<a href=".*" class="extiw" title="link:.*">(.*)<\/a>/\1/g')
                                                                        gsd="${test_2}-${test_2}"
                                                                    else
                                                                        #arr=(`echo ${test_1} | tr ' ' '#' | tr '、' ' '`)
                                                                        res=()
                                                                        oldIFS=${IFS}
                                                                        IFS=、
                                                                        arr=(${test_1})
                                                                        for ((i=0; i<${#arr[@]}; i++)); do
                                                                            res[${i}]=$(echo ${arr[${i}]} | sed -r 's/<a href=".*" class="extiw" title="link:.*">(.*)<\/a>/\1/g')
                                                                            if [[ "${res[${i}]}" = "吉林省" ]]; then
                                                                                res[${i}]="吉林"
                                                                            elif [[ "${res[${i}]}" = "海南省" ]]; then
                                                                                res[${i}]="海南"
                                                                            fi
                                                                        done
                                                                        IFS=${oldIFS}
                                                                        gsd="${res[0]}-${res[1]}"
                                                                        myEcho "0: ${gsd}"
                                                                        if [[ "${res[1]}" != "重庆" ]]; then
                                                                            if [[ "${gsd}" != "青海-海南" ]] && [[ "${gsd}" != "吉林-吉林" ]] && [[ $(provinceInBack "${res[1]}") = "1" ]]; then
                                                                                gsd="${res[1]}-${res[0]}"
                                                                                myEcho "1: ${gsd}"
                                                                            fi
                                                                        else
                                                                            gsd="${res[1]}-${res[0]}"
                                                                            myEcho "2: ${gsd}"
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
        myEcho "GSD getOne 第 ${i} 次 等待 3 秒"
        sleep 3
    done
}

. phone.inc.sh
getUA
((phoneNL=${phoneNumLimit}*${phoneStep}))
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
if [[ "${phoneOrder}" = "asc" ]]; then
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
    if [[ ${phoneStart} -gt 9999 ]]; then phoneStart=9999; fi
    if [[ "${phoneStart}" = "-1" ]]; then
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
    myEcho "查询失败，3 秒后重新查询"
    sleep 3
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
tmpI="./tmp.i.txt"
[[ ! -f ${tmpI} ]] && (echo 0 >${tmpI})
tmpII=$(cat "${tmpI}")
echo ${numI_next} >${phoneI}
if [[ ${numI_next} -lt ${phoneNL} ]]; then
    if [[ ${goonNext} -ne 1 ]]; then
        if [[ ${tmpII} -ne 3 ]]; then
            numMin=`awk -v x=${waitMin} -v y=60 'BEGIN{printf "%.0f\n",x*y}'`
            numMax=`awk -v x=${waitMax} -v y=60 'BEGIN{printf "%.0f\n",x*y}'`
            numRand=$[$RANDOM%$((${numMax}-${numMin}+1))+${numMin}]
            timeNext=$(date --date="${numRand} second" '+%Y-%m-%d %H:%M:%S')
            myEcho "随机等待 ${numRand} 秒，约 $[numRand/60] 分钟"
            myEcho "下次操作: ${timeNext}"
        else
            numRand=1
        fi
    else
        numRand=1
    fi
else
    numRand=1
fi
echo -e >>${logFile}
echo
sleep ${numRand}
if [[ ${tmpII} -eq 3 ]]; then
    rm -f "${tmpI}"
    exit 0
fi
((tmpII_next=${tmpII}+1))
echo ${tmpII_next} >${tmpI}
bash ./github.phone.sh
#exec ./github.phone.sh
