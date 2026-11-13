#!/bin/bash
ORANGE='\033[38;5;208m'
CYAN='\033[38;5;45m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'

init_connect(){
        printf "$GREEN Conectado..\n"
        sleep 1
        read -p "ip conexão: " connectip
        read -p "porta conexão: " connectport
        adb connect $connectip:$connectport
        if [ $? -eq 0 ]; then
            printf "$GREEN [!] Conectado\n"
            sleep 1
            python autoclickForMobile.py
        else
            printf "$RED [!] Ouve uma falha na conexão..\n"
            sleep 1
        fi
}
if command -v adb > /dev/null 2>&1; then
    printf "adb instalado..\n"
    sleep 2
    printf "iniciando conexão...\n"
    read -p "Ja existe uma conexão? s/n: " option
    if [ "$option" = "s" ]; then
        init_connect
    else
       printf "$ORANGE [!] Tente dividir a tela do termux com as da configurações para estabelecer a conexão\n"
       read -p "Digite o ip a conectar: " ip
       read -p "Digite a porta a conectar: " port
       adb pair $ip:$port
       if [ $? -eq 0 ]; then
           init_connect
        else
           printf "$RED [!] falha ao estabelecer conexão.."
        fi
    fi
fi
