# portScan.sh

Um scanner de portas simples escrito em Bash, usando recursos nativos (`/dev/tcp`).

Permite escanear um IP único ou um intervalo de IPs (na mesma sub-rede), especificando portas individuais ou intervalos.

---

## Funcionalidades

-  Escaneia portas **TCP** usando Bash puro (`/dev/tcp`)
-  Aceita **IP ou hostname**
-  Permite escanear **intervalo de IPs (mesma /24)**
-  Aceita portas separadas por vírgula ou intervalos (`22,80,100-110`)
-  Exibe apenas **portas abertas**
-  Suporta interrupção com `Ctrl+C`
-  Validação de entrada e mensagens de erro claras
-  Compatível com Linux (inclusive via WSL)

---

## Uso

```bash
./portScan.sh <host/IP> [host/IP_final] [-p <portas>]
```

### Parâmetros

| Parâmetro         | Descrição                                               |
|-------------------|---------------------------------------------------------|
| `<host/IP>`       | Hostname ou IP inicial a ser escaneado                  |
| `[host/IP_final]` | (opcional) IP ou hostname final para escanear intervalo |
| `-p <portas>`     | Portas (ex: `22,80`, `20-25`). Padrão: `1-1000`         |

---

## Exemplos

### Escanear IP único
```bash
./portScan.sh 192.168.1.10 -p 22,80
```

### Escanear hostname (com IPv4)
```bash
./portScan.sh scanme.nmap.org -p 22,80
```

### Escanear intervalo de IPs na mesma sub-rede
```bash
./portScan.sh 192.168.1.10 192.168.1.15 -p 80,443
```

### Escanear dois hostnames na mesma sub-rede (exige DNS interno)
```bash
./portScan.sh host1.local host2.local -p 8080
```

---

## Restrições

- **Apenas IPv4** é suportado
- **Não escaneia entre sub-redes diferentes**
  - Exemplo inválido:
    ```bash
    ./portScan.sh scanme.nmap.org google.com -p 80
    ```
    Saída:
    ```
    [!] Os IPs '45.33.32.156' e '142.250.78.14' não estão na mesma sub-rede (/24).
    ```

---

## Implementação

- Conversão IP ↔ int para controle de intervalos
- Uso de `timeout` e `/dev/tcp` para conexão TCP
- Validação de argumentos e tratamento de erros
- Uso de `getent ahostsv4` para resolução de hostnames com IPv4
- Formato de portas flexível:
  - `22,80,443`
  - `20-25`
  - Mistos: `22,80-85,443`

---

## Requisitos

- Bash (Linux ou WSL)
- Permissões para executar scripts (`chmod +x portScan.sh`)
- Conexão com o host/target

---

## Licença

Distribuído sob a [Licença MIT](LICENSE).

Este script é fornecido como está, sem garantias. Uso livre para fins educacionais e profissionais. :)

---

## Autor

Rodolfo Lima — baseado em projetos de automação de redes e labs CTF.
