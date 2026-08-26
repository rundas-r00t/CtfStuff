#!/bin/bash

# Define the target directory where tools will be saved
TARGET_DIR="$HOME/security_tools"

# Comprehensive list of GitHub repositories to clone
TOOLS=(
    "https://github.com/Ettercap/ettercap"
    "https://github.com/rundas-r00t/CtfStuff"
    "https://github.com/rundas-r00t/linuxprivchecker"
    "https://github.com/rundas-r00t/scapy"
    "https://github.com/rundas-r00t/scapy-red"
    "https://github.com/rundas-r00t/malicious-pdf"
    "https://github.com/rundas-r00t/sandfly-entropyscan"
    "https://github.com/rundas-r00t/Applocker-CLM-Bypass"
    "https://github.com/rundas-r00t/AutoPentestX"
    "https://github.com/rundas-r00t/powerless"
    "https://github.com/rundas-r00t/cerno"
    "https://github.com/rundas-r00t/defendnot"
    "https://github.com/rundas-r00t/discover"
  #  "https://github.com/rundas-r00t/Titanis"
    "https://github.com/rundas-r00t/evilginx2"
    "https://github.com/rundas-r00t/UACME-compiled"
    "https://github.com/rundas-r00t/Timeroast"
    "https://github.com/rundas-r00t/bashbunny-payloads"
    "https://github.com/rundas-r00t/checksec.sh"
    "https://github.com/rundas-r00t/Responder"
    "https://github.com/rundas-r00t/RunasCs"
    "https://github.com/rundas-r00t/elfloader"
	"https://github.com/StefanosMarinos/MAPG"
	"https://github.com/kahaf-commit/Scripts"
	"https://github.com/Raizo62/Loki_on_Kali"
	
)
# ====================================================================
# HARDENED PRE-INSTALL: Safe Package Verification
# ====================================================================
echo "[*] Verifying critical OS building tools are present..."
MISSING_PKGS=()

# 1. Base command existence checks
command -v cmake &>/dev/null  || MISSING_PKGS+=("cmake" "libpcap-dev" "libnet1-dev" "libssl-dev" "libgtk-3-dev")
command -v go &>/dev/null     || MISSING_PKGS+=("golang-go")
command -v docker &>/dev/null || MISSING_PKGS+=("docker.io")

# 2. Strict package-name query verification checks (Prevents false folder text matching)
dpkg-query -W -f='${Status}' flex 2>/dev/null           | grep -q "ok installed" || MISSING_PKGS+=("flex")
dpkg-query -W -f='${Status}' bison 2>/dev/null          | grep -q "ok installed" || MISSING_PKGS+=("bison")
dpkg-query -W -f='${Status}' libgtk-3-dev 2>/dev/null   | grep -q "ok installed" || MISSING_PKGS+=("libgtk-3-dev")

# 3. Execution Block
if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "[i] Installing missing compilation environments: ${MISSING_PKGS[*]}"
    sudo apt-get update && sudo apt-get install -y "${MISSING_PKGS[@]}"
fi



# Create the target directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    echo "[+] Creating directory: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
fi

# Move into the target directory
cd "$TARGET_DIR" || exit 1

echo "[*] Starting the cloning process..."
echo "---------------------------------"

# Loop through the array and clone each tool
for REPO in "${TOOLS[@]}"; do
    # Extract the repository name from the URL
    REPO_NAME=$(basename "$REPO" .git)

    if [ -d "$REPO_NAME" ]; then
        echo "[!] $REPO_NAME already exists. Skipping..."
    else
        echo "[+] Cloning $REPO_NAME..."
        git clone "$REPO"
    fi
done

# ====================================================================
# FIX #1: Organized GitHub Release Downloader for EvilGinX2
# ====================================================================
echo "[*] Fetching pre-compiled release files for evilginx2..."
EVILGINX_DIST="$TARGET_DIR/evilginx2/compiled_releases"
mkdir -p "$EVILGINX_DIST" && cd "$EVILGINX_DIST" || exit 1

# Correctly query GitHub API endpoints to pull project release archives
curl -s "https://api.github.com/repos/kgretzky/evilginx2/releases/tags/v3.3.0" | grep -o '"browser_download_url": "[^"]*' | sed 's/"browser_download_url": "//' | grep '\.zip$' | while read -r url; do
    echo "Downloading: $url"
    curl -L -O "$url"
done

# Return safely to the main toolkit path
			# cd "$TARGET_DIR" || exit 1
			# # Target repository and the specific version tag
			# REPO="kgretzky/evilginx2"
			# TAG="v3.3.0"

			# # 1. Fetch release info for the specific tag
			# # 2. Extract download URLs
			# # 3. Filter only for URLs ending in '.zip'
			# # 4. Download each matching file
			# curl -s "https://github.com/rundas-r00t/evilginx2" | grep -o '"browser_download_url": "[^"]*' | sed 's/"browser_download_url": "//' | grep '\.zip$' | 
			# while read -r url; do
				# echo "Downloading: $url"
				# curl -L -O "$url"
			# done


echo "---------------------------------"
echo "[*] Checking for commercial/installer-based tools..."
echo "---------------------------------"



# Check for Nessus
if ! command -v nessuscli &> /dev/null && [ ! -d "/opt/nessus" ]; then
    echo "[i] Nessus is not detected. Download manually if needed:"
    echo "    -> https://tenable.com"
else
    echo "[+] Nessus installation detected."
fi

# Check for Burp Suite
if ! command -v burpsuite &> /dev/null && [ ! -d "$HOME/BurpSuitePro" ]; then
    echo "[i] Burp Suite is not detected. Download manually if needed:"
    echo "    -> https://portswigger.net"
else
    echo "[+] Burp Suite installation detected."
fi

echo "---------------------------------"

# ====================================================================
# FIXED: Checking Root and Local Bin Directories for NeuroSploit
# ====================================================================
if command -v neurosploit &> /dev/null || [ -d "/root/.neurosploit-app" ] || [ -d "$HOME/.neurosploit" ]; then
    echo "[+] NeuroSploit installation detected."
else
    echo "[i] NeuroSploit is not detected. Attempting to install..."
    curl -fsSL https://raw.githubusercontent.com/JoasASantos/NeuroSploit/main/setup.sh | sudo bash
fi  
 
	
echo "---------------------------------"
echo "[+] All tools downloaded successfully! Check your folder at: $TARGET_DIR"
echo "---------------------------------"

echo "---------------------------------"
echo "[*] Installing open-sourced tools"
echo "---------------------------------"

echo "[+] Beginning tool installations..."
#building docker container for Loki_on_Kali

# ====================================================================
# FIX #2: Correct Path Declarations and Navigation
# ====================================================================
echo "[+] Installing Loki"
if [ -d "$TARGET_DIR/Loki_on_Kali/Docker" ]; then
    cd "$TARGET_DIR/Loki_on_Kali/Docker" || exit 1
    if command -v docker &>/dev/null; then
        sudo sh ./build.sh
        chmod u+x run_loki_*.sh
        sudo cp run_loki_*.sh /usr/local/sbin 2>/dev/null
	echo "[+] Loki installed successfully. use with 'sudo run_loki_gtk.sh'"
    else
        echo "[-] Skipping Loki Docker compilation: Docker service not active."
    fi
fi

# ====================================================================
# FIX 2: Protected Ettercap Compiling Blocks
# ====================================================================
echo "[+] Installing Ettercap"
if command -v ettercap &>/dev/null; then
    echo "[+] Ettercap is already installed globally. Skipping compilation..."
else
    if [ -d "$TARGET_DIR/ettercap" ]; then
        cd "$TARGET_DIR/ettercap" || exit 1
        
        # CRITICAL: Clean out old corrupted CMake cache states completely
        rm -rf build && mkdir build && cd build || exit 1
        
        # Force compilation with completely suppressed GeoIP module bindings
        cmake -DENABLE_GEOIP=OFF .. && make && sudo make install
    fi
fi



#check for .NET 8 SDK
if command -v dotnet &>/dev/null && dotnet --list-sdks | grep -q "^8\."; then
	echo "[+] .NET 8 SDK installation detected."
else	
	echo "[i] .NET 8 SDK is not detected. This is required for Titanis to work properly. Installing now"
	wget https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
	sudo dpkg -i packages-microsoft-prod.deb
	rm packages-microsoft-prod.deb
	sudo apt-get update && sudo apt-get install -y dotnet-sdk-8.0
fi


echo "[i] Titanis installation is currently paused until C# v13 is released."
# i'm removing this block for Titanis as a temporary measure since it's still under development and currently utilizing an unreleased C# 13 preview. i'll add this back in once the C# version is fully released.
# ====================================================================
# HARDENED TITANIS BUILD: Force Preview Support for C# 13 Syntax
# ====================================================================
#if command -v Smb2Client &>/dev/null || [ -d "/opt/Smb2Client" ]; then
#	echo "[+] Titanis installation detected."	
#else
#	echo "[i] Compiling Titanis framework now..."
#	cd "$TARGET_DIR/Titanis" || exit 1
    
    # Maintain preview syntax compatibility for C# 13 components
#    find . -type f -name "*.csproj" -exec sed -i 's/<LangVersion>[^<]*<\/LangVersion>/<LangVersion>preview<\/LangVersion>/g' {} +
    
    # Force the local compiler target settings to drop documentation generation steps
#    find . -type f -name "*.csproj" -exec sed -i 's/<\/PropertyGroup>/  <BuildDocs>false<\/BuildDocs>\n  <TreatWarningsAsErrors>false<\/TreatWarningsAsErrors>\n<\/PropertyGroup>/g' {} +
    
    # Suppress broken help/man target generators and build execution files cleanly
#	dotnet build --configuration Release -p:BuildDocs=false -p:TreatWarningsAsErrors=false -p:WarningsAsErrors=""
#fi




#unpacking defendnot zips
echo "installing defendnot"
if [ -d "$TARGET_DIR/defendnot" ]; then
	cd "$TARGET_DIR/defendnot" ; mkdir -p compiled ; cd compiled ; 
	wget https://github.com/es3n1n/defendnot/releases/download/v1.6.0/x64.zip
	wget https://github.com/es3n1n/defendnot/releases/download/v1.6.0/x86.zip

# Extract them into separate subfolders to keep them clean
unzip -q -o x86.zip -d x86/
unzip -q -o x64.zip -d x64/

# Clean up the downloaded zips
	rm x86.zip x64.zip
fi
# Check if pipx is installed
if command -v pipx &>/dev/null; then
    echo "[+] pipx is already installed. Skipping..."
else
    echo "[i] pipx not found. pipx is required for Cerno. Installing now..."
    sudo apt update && sudo apt install pipx -y
    
    # Ensure pipx paths are injected into user profile files for future sessions
    pipx ensurepath
    
    # CRITICAL FIX: Force the current running script session to see pipx and its path immediately
    export PATH="$PATH:$HOME/.local/bin"
fi

#installing cerno
# ====================================================================
# FIX 4: Prevent Redundant Pipx Deployments for Cerno
# ====================================================================
if command -v cerno &>/dev/null; then
    echo "[+] Cerno is already installed globally. Skipping..."
else
	echo "[i] Installing Cerno via pipx..."
	pipx install git+https://github.com/ridgebackinfosec/cerno.git
fi


# ====================================================================
# FIXED: Corrected Command Checks and Silent Pipeline Execution
# ====================================================================
if command -v autopentestx &>/dev/null || [ -d "$TARGET_DIR/AutoPentestX" ] || [ -f "/usr/local/bin/autopentestx" ]; then
    echo "[+] AutoPentestX is already installed. Skipping..."
else
    echo "[i] Installing AutoPentestX..."
    cd "$TARGET_DIR/AutoPentestX" || exit 1
    chmod +x install.sh
    
    # Pass 'no' automatically to any interactive user setup prompts
    ./install.sh <<< "n"


# ====================================================================
# FIX #4A: Aligned AutoPentestX Global Command Wrapper
# ====================================================================
echo "[i] Creating global wrapper for autopentestx..."
sudo tee /usr/local/bin/autopentestx > /dev/null << EOF
#!/bin/bash
cd "$TARGET_DIR/AutoPentestX" || exit 1
./autopentestx.sh "\$@"
EOF
sudo chmod +x /usr/local/bin/autopentestx


			# echo "[i] Creating global wrapper for autopentestx..."

			# # Create a small execution wrapper in /usr/local/bin
			# sudo tee /usr/local/bin/autopentestx > /dev/null << 'EOF'
			# #!/bin/bash
			# # Automatically navigate to the AutoPentestX folder before running
			# cd "/opt/AutoPentestX" || exit 1

			# # Execute the script and pass ALL arguments ("$@") directly to it
			# ./autopentestx.sh "$@"
			# EOF

			# # Make the new global command executable
			# sudo chmod +x /usr/local/bin/autopentestx

echo "[+] Success! You can now run 'autopentestx <IP_ADDRESS>' globally."

fi

# ====================================================================
# FIX #3: Safe Sandfly Navigation without Global Path Corruptions
# ====================================================================
if command -v sandfly-entropyscan &>/dev/null && command -v rundas-prompter &>/dev/null; then
    echo "[+] sandfly-entropyscan framework already globally installed. Skipping..."
else
    echo "[i] sandfly-entropyscan not found. Installing toolkit now..."
    
    # Enter the subfolder safely without breaking the main target variable path
    cd "$TARGET_DIR/sandfly-entropyscan" || exit 1
    
    echo "[i] Compiling Go framework..."
    go build
    
    echo "[i] Patching prompter file paths..."
    sed -i 's|\./sandfly-entropyscan|sandfly-entropyscan|g' rundas-prompter.sh
    
    sudo cp sandfly-entropyscan /usr/local/bin/
    sudo chmod +x /usr/local/bin/sandfly-entropyscan
    sudo cp rundas-prompter.sh /usr/local/bin/rundas-prompter
    sudo chmod +x /usr/local/bin/rundas-prompter
    echo "[+] Success! You can now run 'sandfly-entropyscan' or 'rundas-prompter' from anywhere."
fi


				# #installing sandfly-entropyscan
				# # Check if the global command is already accessible
				# if command -v sandfly-entropyscan &>/dev/null && command -v rundas-prompter &>/dev/null; then
					# echo "[+] sandfly-entropyscan framework already globally installed. Skipping..."
				# else
					# echo "[i] sandfly-entropyscan not found. Installing toolkit now..."
					
					# # 1. Clone the repository if the folder doesn't exist
					# if [ ! -d "$TARGET_DIR/sandfly-entropyscan" ]; then
						# git clone https://github.com/rundas-r00t/sandfly-entropyscan "$TARGET_DIR/sandfly-entropyscan"
					# fi
					
					# cd "$TARGET_DIR/sandfly-entropyscan" || exit 1
					
					# # 2. Compile the Go binary
					# echo "[i] Compiling Go framework..."
					# go build
					
					# # 3. CRITICAL PATCH: Remove the "./" relative path lock from the prompter script
					# # This transforms "./sandfly-entropyscan" inside the code to just "sandfly-entropyscan"
					# echo "[i] Patching prompter file paths..."
					# sed -i 's|\./sandfly-entropyscan|sandfly-entropyscan|g' rundas-prompter.sh
					
					# # 4. Copy the compiled core engine to the system PATH
					# sudo cp sandfly-entropyscan /usr/local/bin/
					# sudo chmod +x /usr/local/bin/sandfly-entropyscan
					
					# # 5. Copy the prompter script, renaming it to a clean command name (dropping .sh)
					# sudo cp rundas-prompter.sh /usr/local/bin/rundas-prompter
					# sudo chmod +x /usr/local/bin/rundas-prompter
					
					# echo "[+] Success! You can now run 'sandfly-entropyscan' or 'rundas-prompter' from anywhere."
				# fi



#install scapy and scapy-red
# Define target path for the environment
ENV_DIR="/opt/scapy_env"

if command -v scapy &>/dev/null; then
    echo "[+] Global 'scapy' command is already available. Skipping..."
else
    echo "[i] Structuring Scapy execution environment..."
    
    # 1. Guarantee Python virtual environment tools are installed on Kali
    sudo apt-get update && sudo apt-get install python3-venv -y
    
    # 2. Establish the isolated virtual environment folder
    sudo mkdir -p "$ENV_DIR"
    sudo chown -R $USER:$USER "$ENV_DIR"
    python3 -m venv "$ENV_DIR"
    
    # 3. Step into your cloned git folder
    cd "$TARGET_DIR/scapy" || { echo "[-] Error: Cloned directory $TARGET_DIR not found."; exit 1; }
    
    # 4. Install Scapy, plus the required matplotlib and cryptography dependencies inside the environment
    echo "[i] Installing Scapy alongside matplotlib and cryptography..."
    "$ENV_DIR/bin/pip" install --upgrade pip
    "$ENV_DIR/bin/pip" install -e .
    "$ENV_DIR/bin/pip" install matplotlib cryptography
    
    # 5. Create a global binary execution wrapper in your system PATH
    echo "[i] Creating global execution hook..."
    sudo tee /usr/local/bin/scapy > /dev/null << 'EOF'
#!/bin/bash
# Force the system to use the isolated scapy installation context
# and pass all trailing parameters directly to it
exec "/opt/scapy_env/bin/scapy" "$@"
EOF

    # 6. Adjust permissions so any console shell can call it
    sudo chmod +x /usr/local/bin/scapy
    
    echo "[+] Done! You can now type 'scapy' from any folder to launch the interactive framework."
fi

if [ -f "$ENV_DIR/bin/scapy-smbscan" ]; then
    echo "[+] scapy-red tools already installed. Skipping..."
else
    echo "[i] Creating isolated Python environment for scapy-red..."
fi    
    # 1. Stand up the python virtual environment structure
			#this may not be necessary since the venv was created with scapy above
			# sudo mkdir -p "$ENV_DIR"
			# sudo chown -R $USER:$USER "$ENV_DIR"
			# python3 -m venv "$ENV_DIR"
    
    # 2. Upgrade pip and install the fork directly from GitHub in one go
if [ -f "$ENV_DIR/bin/scapy-smbscan" ]; then
    echo "[+] scapy-red tools already installed. Skipping..."
else
	echo "[i] Installing scapy-red fork into environment..."
	# Fix #3: Ensure the core environment workspace is actually present before appending packages
    if [ ! -d "$ENV_DIR" ]; then
        sudo mkdir -p "$ENV_DIR"
        sudo chown -R $USER:$USER "$ENV_DIR"
        python3 -m venv "$ENV_DIR"
    fi
    "$ENV_DIR/bin/pip" install --upgrade pip
    "$ENV_DIR/bin/pip" install git+https://github.com/rundas-r00t/scapy-red.git
    
    # 3. Create global symlinks for all the built-in commands listed in the repo
    echo "[i] Exposing scapy-red commands globally..."
    sudo ln -sf "$ENV_DIR/bin/scapy-dominfo" /usr/local/bin/scapy-dominfo
    sudo ln -sf "$ENV_DIR/bin/scapy-smbscan" /usr/local/bin/scapy-smbscan
    sudo ln -sf "$ENV_DIR/bin/scapy-listips" /usr/local/bin/scapy-listips
    sudo ln -sf "$ENV_DIR/bin/scapy-smbclient" /usr/local/bin/scapy-smbclient
    sudo ln -sf "$ENV_DIR/bin/scapy-ldaphero" /usr/local/bin/scapy-ldaphero
    sudo ln -sf "$ENV_DIR/bin/scapy-winreg" /usr/local/bin/scapy-winreg
    
    echo "[+] Success! All scapy-red standalone commands are now globally callable."
fi

# ====================================================================
# FIX #4B: Aligned LinuxPrivChecker Global Command Wrapper
# ====================================================================
if command -v linuxprivchecker &>/dev/null; then
    echo "[+] 'linuxprivchecker' command is already available. Skipping..."
else
    echo "[i] Setting up global wrapper for linuxprivchecker..."
    
    if [ ! -f "$TARGET_DIR/linuxprivchecker/py3-version.py" ]; then
        echo "[-] Error: $TARGET_DIR/linuxprivchecker/py3-version.py not found."
        exit 1
    fi

    sudo tee /usr/local/bin/linuxprivchecker > /dev/null << EOF
#!/bin/bash
exec python3 "$TARGET_DIR/linuxprivchecker/py3-version.py" "\$@"
EOF
    sudo chmod +x /usr/local/bin/linuxprivchecker
	echo "[+] Success! You can now run 'linuxprivchecker' with any options from anywhere."
fi


			# # Define target path where your script cloned the repository
			# TARGET_DIR2="/opt/linuxprivchecker"

			# # Check if the global command is already accessible
			# if command -v linuxprivchecker &>/dev/null; then
				# echo "[+] 'linuxprivchecker' command is already available. Skipping..."
			# else
				# echo "[i] Setting up global wrapper for linuxprivchecker..."

				# # 1. Double check that the target Python 3 script file actually exists
				# if [ ! -f "$TARGET_DIR2/py3-version.py" ]; then
					# echo "[-] Error: $TARGET_DIR/py3-version.py not found. Please ensure git clone ran successfully."
					# exit 1
				# fi

				# # 2. Create a clean global execution wrapper in your system PATH (dropping the .py extension)
				# sudo tee /usr/local/bin/linuxprivchecker > /dev/null << 'EOF'
			# #!/bin/bash
			# # Force execution using the system Python 3 engine and pass all flags/arguments ("$@") through
			# exec python3 "/opt/linuxprivchecker/py3-version.py" "$@"
			# EOF

				# # 3. Make the wrapper command executable by any user
				# sudo chmod +x /usr/local/bin/linuxprivchecker

 echo "[+] All tools were installed successfully! Hooray!"   

