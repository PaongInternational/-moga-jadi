#!/bin/bash
# XIPSERCLOUD - SKRIP INTI V5.0 (FAIL-PROOF EDITION)
# Perbaikan fundamental Termux: Memperbaiki Repository, Izin Penyimpanan, dan Instalasi Paksa.

# --- KONFIGURASI NGROK & WARNA ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BG_GREEN='\033[42m\033[1;37m'
BG_RED='\033[41m\033[1;37m'
BOLD='\033[1m'
PURPLE='\033[0;35m'

# --- KONFIGURASI UTAMA ---
SERVER_JAR="paper.jar"
MINECRAFT_PORT=25565
MINECRAFT_VERSION="1.20.4"
# TOKEN NGROK ANDA SUDAH DIPASANG DI SINI:
NGROK_TOKEN="33RKXoLi8mLMccvpJbo1LoN3fCg_4AEGykdpBZeXx2TFHaCQj" 
RAM_CONFIG_FILE="config_ram.txt"
DEFAULT_RAM="4096M" # Default 4 GB
SCREEN_SESSION_MC="mc_server"
SCREEN_SESSION_NGROK="ngrok_tunnel"
SCREEN_SESSION_MONITOR="system_monitor"
NGROK_LOG_FILE="ngrok.log"

# ARRAY NAMA ACAK
NAMA_ACAK=("Phoenix" "Dragon" "Nova" "Aether" "Comet" "Titan" "Galaksi")
RANDOM_NAME="${NAMA_ACAK[$RANDOM % ${#NAMA_ACAK[@]}]}"
SERVER_NAME="Xipser-$RANDOM_NAME"

# --- FUNGSI UTILITY KRITIS ---

# Mengambil konfigurasi RAM
function get_ram() {
    if [ -f "$RAM_CONFIG_FILE" ]; then
        local configured_ram=$(cat "$RAM_CONFIG_FILE" | tr -d '\n')
        if [[ "$configured_ram" =~ ^[0-9]+[M]$ ]]; then
            echo "$configured_ram"
            return 0
        fi
    fi
    echo "$DEFAULT_RAM"
    return 0
}

# Fungsi untuk mengubah konfigurasi RAM
function set_ram() {
    local ram_value=$1
    if [[ -z "$ram_value" ]]; then
        echo -e "${RED}❌ ERROR:${NC} Harap masukkan nilai RAM yang valid (contoh: 4G, 6G, atau 8192M)."
        echo -e "Penggunaan: ${YELLOW}./xipsercloud.sh set_ram <nilai_ram>${NC}"
        return 1
    fi

    local clean_ram=$(echo "$ram_value" | tr '[:lower:]' '[:upper:]')
    if [[ "$clean_ram" =~ ^[0-9]+[G]$ ]]; then
        clean_ram=$(echo "$clean_ram" | sed 's/G$//')
        clean_ram=$((clean_ram * 1024))M
    fi
    
    if [[ "$clean_ram" =~ ^[0-9]+[M]$ ]]; then
        echo "$clean_ram" > "$RAM_CONFIG_FILE"
        echo -e "${BG_GREEN}✅ BERHASIL:${NC} RAM server berhasil diatur ke: ${BOLD}$clean_ram${NC}"
        echo "RAM baru akan digunakan pada peluncuran server berikutnya."
    else
        echo -e "${RED}❌ ERROR:${NC} Format RAM tidak valid. Gunakan format seperti ${YELLOW}4G, 6G, atau 8192M${NC}."
        return 1
    fi
}


# --- SHUTDOWN AMAN ---
function safe_shutdown() {
    local reason=$1
    echo -e "${PURPLE}[MONITOR]${NC} Memicu shutdown aman: $reason"
    
    if screen -list | grep -q ".$SCREEN_SESSION_MC"; then
        screen -S $SCREEN_SESSION_MC -X stuff "say §c[SERVER] §4Shutdown & penyimpanan dunia dimulai...\n"
        sleep 5
        screen -S $SCREEN_SESSION_MC -X stuff "save-all\n" 
        sleep 10
        screen -S $SCREEN_SESSION_MC -X stuff "stop\n"
        
        for i in {1..20}; do
            if ! screen -list | grep -q ".$SCREEN_SESSION_MC"; then
                echo -e "${PURPLE}[MONITOR]${NC} Server Minecraft telah mati. Dunia tersimpan aman."
                break
            fi
            sleep 1
        done
    fi

    screen -X -S $SCREEN_SESSION_NGROK quit 2>/dev/null
    screen -X -S $SCREEN_SESSION_MONITOR quit 2>/dev/null
    echo -e "${BG_GREEN}✅ SHUTDOWN LENGKAP. Terima kasih!${NC}"
    
    exit 0
}

# --- MONITORING SYSTEM ---
function monitor_server() {
    MAX_RUNTIME_SECONDS=$((12 * 60 * 60)) 
    LOW_BATTERY_THRESHOLD=5              
    CHECK_INTERVAL_SECONDS=60            
    RUNTIME_START=$(date +%s)
    
    echo -e "${PURPLE}Monitor Otomatis Aktif (Shutdown: 12 jam / Baterai $LOW_BATTERY_THRESHOLD%).${NC}"
    
    while true; do
        if ! screen -list | grep -q ".$SCREEN_SESSION_MC"; then
            echo -e "${PURPLE}[MONITOR]${NC} Sesi server 'mc_server' tidak aktif. Mengakhiri monitor."
            safe_shutdown "Server mati sendiri/crash"
            exit 0
        fi
        
        CURRENT_TIME=$(date +%s)
        RUNTIME=$((CURRENT_TIME - RUNTIME_START))
        if [ $RUNTIME -ge $MAX_RUNTIME_SECONDS ]; then
            safe_shutdown "Waktu maksimal berjalan (12 jam) telah tercapai"
        fi
        
        if command -v termux-battery-status &> /dev/null; then
            BATTERY_INFO=$(termux-battery-status 2>/dev/null)
            BATTERY_PERCENTAGE=$(echo "$BATTERY_INFO" | jq -r '.percentage' 2>/dev/null)
            PLUGGED_STATUS=$(echo "$BATTERY_INFO" | jq -r '.plugged' 2>/dev/null)

            if [ -n "$BATTERY_PERCENTAGE" ] && [ "$BATTERY_PERCENTAGE" -le "$LOW_BATTERY_THRESHOLD" ]; then
                 if [ "$PLUGGED_STATUS" == "UNPLUGGED" ] || [ "$PLUGGED_STATUS" == "UNKNOWN" ]; then
                     safe_shutdown "Baterai perangkat hanya tersisa ${LOW_BATTERY_THRESHOLD}%"
                 fi
            fi
        fi

        sleep $CHECK_INTERVAL_SECONDS
    done
}

# --- MANAJEMEN ADMIN ---
function process_admins() {
    echo -e "${CYAN}MEMPROSES DATABASE ADMIN...${NC}"
    
    if [ -f "admin_database.txt" ]; then
        sleep 5 
        while IFS= read -r player_name; do
            if [[ -n "$player_name" && ! "$player_name" =~ ^# ]]; then
                echo -e "${CYAN} -> ${NC}Mengirim perintah OP untuk: ${BOLD}$player_name${NC}"
                screen -S $SCREEN_SESSION_MC -X stuff "op $player_name\n"
                sleep 0.5 
            fi
        done < admin_database.txt
        echo -e "${BG_GREEN}✅ BERHASIL:${NC} SEMUA ADMIN DARI DATABASE TELAH DIPROSES."
    else
        echo -e "${YELLOW}PERINGATAN:${NC} admin_database.txt tidak ditemukan. Tidak ada admin yang didaftarkan."
    fi
}

function get_external_ip() {
    curl -s icanhazip.com
}

# --- FUNGSI UTAMA: SETUP & START ---
function main_setup_and_start() {
    local MAX_RAM_CURRENT=$(get_ram)
    local AIKAR_FLAGS_CURRENT="-Xms512M -Xmx$MAX_RAM_CURRENT -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+AggressiveOpts -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedSiteCount=4 -XX:G1MixedSiteRatio=3 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://aikar.co/mcflags.html"

    echo -e "${BLUE}==========================================================${NC}"
    echo -e "${BOLD}${CYAN}          [XIPSERCLOUD] Setup & Launch Script V5.0        ${NC}"
    echo -e "${BLUE}==========================================================${NC}"
    echo -e "  ${YELLOW}NAMA SERVER:${NC} ${BOLD}${SERVER_NAME}${NC}"
    echo -e "  ${YELLOW}RAM DIGUNAKAN:${NC} ${BOLD}$MAX_RAM_CURRENT${NC}"
    echo -e "  ${YELLOW}SUPPORT:${NC} ${GREEN}JAVA (PC)${NC} & ${CYAN}BEDROCK (Mobile)${NC}"
    echo -e "${BLUE}==========================================================${NC}"

    # Matikan dan bersihkan semua sesi lama
    echo -e "${GREEN}[SETUP]${NC} Membersihkan sesi screen lama...${NC}"
    screen -X -S $SCREEN_SESSION_MC quit 2>/dev/null
    screen -X -S $SCREEN_SESSION_NGROK quit 2>/dev/null
    screen -X -S $SCREEN_SESSION_MONITOR quit 2>/dev/null
    screen -wipe > /dev/null

    # --- TAHAP 0: PERBAIKAN LINGKUNGAN TERMUX KRITIS (SOLUSI FAIL-PROOF) ---
    echo -e "${RED}--- TAHAP PERBAIKAN KRITIS (SOLUSI UNTUK ERROR INSTALASI) ---${NC}"
    
    # 1. Izin Penyimpanan
    echo -e "${RED}[KRITIS]${NC} Memastikan izin penyimpanan Termux. Harap izinkan pop-up Android!..."
    termux-setup-storage
    
    # 2. Ganti dan Perbarui Sumber Paket (Repo Fix)
    echo -e "${RED}[KRITIS]${NC} Memperbarui dan mensinkronisasi sumber paket Termux..."
    # Ini akan memaksa Termux untuk memilih mirror yang stabil
    termux-change-repo
    pkg update -y

    # --- TAHAP 1: INSTALASI DEPENDENSI (Instalasi Paksa Sekaligus) ---
    echo -e "${GREEN}[SETUP]${NC} Menginstal paket esensial (openjdk-17, screen, ngrok, dll.)...${NC}"
    if ! pkg install openjdk-17 wget screen jq curl termux-api ngrok -y; then
        echo -e "\n${BG_RED}❌ ERROR KRITIS:${NC} Gagal menginstal paket inti. Cek ulang koneksi internet dan coba ulangi perintah ini secara manual!"
        exit 1
    fi
    echo -e "${BG_GREEN}✅ BERHASIL:${NC} Semua paket inti sudah terinstal."


    # 1. Konfigurasi Ngrok (.yml file) - JAMINAN KONEKSI TCP
    echo -e "${GREEN}[SETUP]${NC} Mengkonfigurasi Ngrok untuk tunnel TCP...${NC}"
    mkdir -p ~/.ngrok2
    echo "authtoken: $NGROK_TOKEN" > ~/.ngrok2/ngrok.yml
    echo "tunnels:" >> ~/.ngrok2/ngrok.yml
    echo "  minecraft-tcp:" >> ~/.ngrok2/ngrok.yml
    echo "    proto: tcp" >> ~/.ngrok2/ngrok.yml
    echo "    addr: $MINECRAFT_PORT" >> ~/.ngrok2/ngrok.yml

    # 2. Mengautentikasi Ngrok
    echo -e "${GREEN}[SETUP]${NC} Mengautentikasi Ngrok dengan token Anda...${NC}"
    if ! ngrok authtoken $NGROK_TOKEN &> /dev/null; then
        echo -e "${BG_RED}❌ ERROR NGROK:${NC} Ngrok gagal otentikasi. Cek token: ${NGROK_TOKEN}"
        exit 1
    fi

    # --- TAHAP 2: DOWNLOAD CORE SERVER & KONFIGURASI ---
    echo -e "${GREEN}[SETUP]${NC} Mengunduh/memverifikasi server PaperMC ${MINECRAFT_VERSION}...${NC}"
    API_URL="https://api.papermc.io/v2/projects/paper/versions/$MINECRAFT_VERSION/builds"
    BUILD_INFO=$(wget -qO- "$API_URL" | jq -r '.builds | last')
    BUILD_NUMBER=$(echo "$BUILD_INFO" | jq -r '.build')
    DOWNLOAD_PATH=$(echo "$BUILD_INFO" | jq -r '.downloads.application.name')
    PAPER_URL="https://api.papermc.io/v2/projects/paper/versions/$MINECRAFT_VERSION/builds/$BUILD_NUMBER/downloads/$DOWNLOAD_PATH"
    
    if [ ! -f "$SERVER_JAR" ] || [ "$(du -b "$SERVER_JAR" | cut -f 1)" -lt 1000 ]; then
        echo -e "${GREEN}[SETUP]${NC} File JAR hilang atau korup. Mengunduh ulang..."
        rm -f "$SERVER_JAR"
        wget -O $SERVER_JAR "$PAPER_URL"
    fi

    # EULA dan Konfigurasi Awal
    echo "eula=true" > eula.txt

    if [ ! -f "server.properties" ]; then
         echo -e "${GREEN}[SETUP]${NC} Server.properties tidak ada. Menjalankan sebentar untuk generate...${NC}"
         java -Xms128M -Xmx256M -jar $SERVER_JAR --nogui &
         SERVER_PID=$!
         sleep 20
         kill $SERVER_PID
         wait $SERVER_PID 2>/dev/null
    fi
    
    echo -e "${GREEN}[SETUP]${NC} Mengatur server.properties...${NC}"
    SERVER_MOTD="§l§6${SERVER_NAME} §r§f- §aJava & Bedrock Server Xipser§r"
    sed -i "s/motd=A Minecraft Server/motd=${SERVER_MOTD}/g" server.properties
    sed -i 's/online-mode=true/online-mode=false/' server.properties 
    sed -i 's/^server-ip=.*$/server-ip=/' server.properties 

    # --- TAHAP 3: INSTALASI PLUGIN ---
    echo -e "${YELLOW}--- INSTALASI PLUGIN MULTI-PLATFORM ---${NC}"
    mkdir -p plugins
    
    GP_URL="https://mediafilez.forgecdn.net/files/4908/920/GriefPrevention-1.20.4.jar"
    GEYSER_URL="https://ci.opencdn.xyz/job/GeyserMC/Geyser/master/latest/artifact/bootstrap/build/libs/Geyser-Spigot.jar"
    FLOODGATE_URL="https://ci.opencdn.xyz/job/GeyserMC/Floodgate/master/latest/artifact/spigot/build/libs/floodgate-spigot.jar"
    PLUGINS=("GriefPrevention-1.20.4.jar|$GP_URL" "Geyser-Spigot.jar|$GEYSER_URL" "floodgate-spigot.jar|$FLOODGATE_URL")

    for item in "${PLUGINS[@]}"; do
        PLUGIN_NAME="${item%%|*}"
        PLUGIN_URL="${item##*|}"
        PLUGIN_FILE="plugins/$PLUGIN_NAME"
        if [ ! -f "$PLUGIN_FILE" ]; then
            echo -e "${GREEN}[SETUP]${NC} Mengunduh $PLUGIN_NAME..."
            wget -O "$PLUGIN_FILE" "$PLUGIN_URL"
        fi
    done
    echo -e "${BG_GREEN}✅ SETUP KONFIGURASI PLUGIN SELESAI.${NC}"

    # --- START TAHAP 4: PELUNCURAN SERVER ---

    # 1. Memulai Ngrok 
    rm -f $NGROK_LOG_FILE
    screen -dmS $SCREEN_SESSION_NGROK bash -c "ngrok start --all --config ~/.ngrok2/ngrok.yml --log stdout > $NGROK_LOG_FILE"
    echo -e "${CYAN}Memulai Ngrok (Sesi: ${SCREEN_SESSION_NGROK})...${NC}"
    sleep 5

    # 2. Memulai Monitor
    export -f safe_shutdown monitor_server get_ram get_external_ip process_admins set_ram 
    screen -dmS $SCREEN_SESSION_MONITOR bash -c 'monitor_server'
    echo -e "${CYAN}Memulai Monitor Otomatis (Sesi: ${SCREEN_SESSION_MONITOR})...${NC}"

    # 3. Memulai Server Minecraft
    echo -e "${CYAN}Memulai Server PaperMC (Sesi: ${SCREEN_SESSION_MC}) dengan ${MAX_RAM_CURRENT}...${NC}"
    screen -dmS $SCREEN_SESSION_MC java $AIKAR_FLAGS_CURRENT -jar $SERVER_JAR --nogui

    # 4. Tambahkan Admin
    echo -e "${YELLOW}Menunggu server memuat (60 detik) untuk memproses admin...${NC}"
    sleep 60
    process_admins

    # 5. Menampilkan IP dan Port Ngrok (JAMINAN IP)
    echo -e "${CYAN}Mencari Alamat Publik Ngrok (Maksimal 50 detik)...${NC}"
    NGROK_URL=""
    for i in {1..50}; do 
        NGROK_URL=$(grep -o 'url=[^ ]*' $NGROK_LOG_FILE | grep 'tcp' | tail -1 | cut -d '=' -f 2)
        if [ -n "$NGROK_URL" ]; then
            break
        fi
        sleep 1
    done

    EXTERNAL_IP=$(get_external_ip)

    if [ -z "$NGROK_URL" ]; then
        echo -e "\n${BG_RED}❌ KONEKSI NGROK GAGAL TOTAL!${NC}"
        echo -e "${RED}  Server berjalan di latar belakang, tapi tunneling gagal. Cek ulang koneksi dan log: tail $NGROK_LOG_FILE${NC}"
    else
        echo -e "\n${BG_GREEN}✅ SERVER ONLINE & NGROK TERHUBUNG!${NC}"
        echo -e "  ${BOLD}NAMA SERVER: ${SERVER_NAME}${NC}"
        echo -e "  ${BOLD}----------------------------------------${NC}"
        echo -e "  ${BOLD}${CYAN}1. ALAMAT NGROK (INSTAN):${NC}"
        echo -e "     ${BOLD}${GREEN}JAVA (PC):${NC} $NGROK_URL"
        echo -e "     ${BOLD}${GREEN}BEDROCK (HP):${NC} Host ${NGROK_URL%%:*} Port ${CYAN}19132${NC}"
        echo -e "  ${BOLD}----------------------------------------${NC}"
        echo -e "${CYAN}CATATAN: Server siap. Masuk ke konsol di bawah ini!${NC}"
    fi

    echo -e "${BLUE}==========================================================${NC}"

    # 6. Lampirkan ke konsol server
    echo -e "${CYAN}Melampirkan ke konsol server '$SCREEN_SESSION_MC'...${NC}"
    screen -r $SCREEN_SESSION_MC
}

# --- LOGIKA PENENTUAN MODE ---
if [ "$1" == "set_ram" ]; then
    set_ram "$2"
elif [ "$1" == "start" ] || [ -z "$1" ]; then
    main_setup_and_start
elif [ "$1" == "shutdown" ]; then
    safe_shutdown "Manual command"
else
    echo -e "${RED}❌ ERROR:${NC} Perintah tidak dikenal."
    echo "Penggunaan:"
    echo -e "  1. Jalankan Server: ${YELLOW}./xipsercloud.sh start${NC}"
    echo -e "  2. Matikan Server: ${YELLOW}./xipsercloud.sh shutdown${NC} (Aman)"
    echo -e "  3. Ganti RAM: ${YELLOW}./xipsercloud.sh set_ram <nilai_ram>${NC} (contoh: 6G atau 8192M)"
fi
