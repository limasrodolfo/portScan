#!/bin/bash

# Interrompe com Ctrl+C
trap 'echo -e "\n[!] Interrompido pelo usuário."; exit 1' INT

usage() {
  echo "Uso: $0 <host/IP> [host/IP_final] [-p <portas>]"
  echo ""
  echo "  <host/IP>         IP ou hostname para escanear (início)"
  echo "  [host/IP_final]   IP ou hostname final para intervalo (opcional)"
  echo "  -p <portas>       Portas (ex: 22,80 ou 20-25). Padrão: 1-1000"
  echo ""
  echo "Exemplos:"
  echo "  $0 192.168.1.10 -p 22,80"
  echo "  $0 scanme.nmap.org -p 22"
  echo "  $0 192.168.1.10 192.168.1.20 -p 80"
  exit 1
}

# Defaults
ports="1-1000"
ip_start=""
ip_end=""

# Argument parsing robusto
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p)
      shift
      ports="$1"
      ;;
    -h|--help)
      usage
      ;;
    -*)
      echo "[!] Opção desconhecida: $1"
      usage
      ;;
    *)
      if [ -z "$ip_start" ]; then
        ip_start="$1"
      elif [ -z "$ip_end" ]; then
        ip_end="$1"
      else
        echo "[!] Muitos argumentos de IP/host."
        usage
      fi
      ;;
  esac
  shift
done

# Validar argumento obrigatório
if [ -z "$ip_start" ]; then
  usage
fi

# Apenas IPv4
resolve_ip() {
  local input="$1"
  getent ahostsv4 "$input" | awk '{ print $1 }' | head -n1
}

ip_to_int() {
  local ip="$1"
  IFS=. read -r a b c d <<< "$ip"
  echo $(( (a << 24) + (b << 16) + (c << 8) + d ))
}

int_to_ip() {
  local ip_int=$1
  echo "$(( (ip_int >> 24) & 255 )).$(( (ip_int >> 16) & 255 )).$(( (ip_int >> 8) & 255 )).$(( ip_int & 255 ))"
}

check_port() {
  local ip="$1"
  local port="$2"
  if timeout 1 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null; then
    echo "[+] Porta $port aberta em $ip"
  fi
}

expand_ports() {
  local input="$1"
  local result=()
  IFS=',' read -ra items <<< "$input"
  for item in "${items[@]}"; do
    if [[ "$item" == *"-"* ]]; then
      start=${item%-*}
      end=${item#*-}
      for ((i=start; i<=end; i++)); do result+=($i); done
    else
      result+=($item)
    fi
  done
  echo "${result[@]}"
}

scan_ip() {
  local ip="$1"
  read -ra port_list <<< "$(expand_ports "$ports")"
  for port in "${port_list[@]}"; do
    check_port "$ip" "$port"
  done
}

same_subnet() {
  local ip1="$1"
  local ip2="$2"
  IFS=. read -r a1 b1 c1 d1 <<< "$ip1"
  IFS=. read -r a2 b2 c2 d2 <<< "$ip2"
  [[ "$a1.$b1.$c1" == "$a2.$b2.$c2" ]]
}

# Resolve IPs (ou hostnames)
resolved_start=$(resolve_ip "$ip_start")
resolved_end=$(resolve_ip "${ip_end:-$ip_start}")

if [ -z "$resolved_start" ] || [ -z "$resolved_end" ]; then
  echo "[!] Erro: não foi possível resolver o(s) hostname(s)."
  exit 1
fi

# Validação: intervalo deve estar na mesma /24
if [[ "$resolved_start" != "$resolved_end" ]]; then
  if ! same_subnet "$resolved_start" "$resolved_end"; then
    echo "[!] Os IPs '$resolved_start' e '$resolved_end' não estão na mesma sub-rede (/24)."
    exit 1
  fi
fi

# Converte para inteiros
start_int=$(ip_to_int "$resolved_start")
end_int=$(ip_to_int "$resolved_end")

if ((start_int > end_int)); then
  echo "[!] IP final é menor que o inicial."
  exit 1
fi

# Escaneia
for ((ip=start_int; ip<=end_int; ip++)); do
  current_ip=$(int_to_ip "$ip")
  echo "[*] Escaneando $current_ip..."
  scan_ip "$current_ip"
done
