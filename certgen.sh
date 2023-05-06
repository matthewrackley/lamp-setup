while [ $# -gt 0 ] && [ $# -lt 3 ]; do
    case $1 in
        -d)
            export altDomain=$2
            shift 2
            ;;
        *)
            shift 1
            ;;
    esac
done
while [ $# -gt 2 ]; do
    case $1 in
        -d)
            export ${altDomain[@]}=$2,
            shift 2
            ;;
        *)
            shift 1
            ;;
    esac
done
if [ $# -eq 2 ] && [ $1 == "-d" ]; then
    export ${altDomain[@]}=${altDomain[@]%?}
fi
if [ -d "/opt/server/ca/" ]; then
    clear
else
    mkdir -p /opt/server/ca/
    clear
fi
echo "\033[01;36m###############################################################"
echo "\033[01;36m#####                                                     \033[01;36m#####"
echo "\033[01;36m####  \033[01;31m██████\033[01;33m╗ \033[01;31m█████\033[01;33m╗      \033[01;31m██████\033[01;33m╗ \033[01;31m███████\033[01;33m╗\033[01;31m███\033[01;33m╗   \033[01;31m██\033[01;33m╗       \033[01;36m####"
echo "\033[01;36m###  \033[01;31m██\033[01;33m╔════╝\033[01;31m██\033[01;33m╔══\033[01;31m██\033[01;33m╗    \033[01;31m██\033[01;33m╔════╝ \033[01;31m██\033[01;33m╔════╝\033[01;31m████\033[01;33m╗  \033[01;31m██\033[01;33m║        \033[01;36m###"
echo "\033[01;36m###  \033[01;31m██║     \033[01;31m███████\033[01;33m║    \033[01;31m██\033[01;33m║  \033[01;31m███\033[01;33m╗\033[01;31m█████\033[01;33m╗  \033[01;31m██\033[01;33m╔\033[01;31m██\033[01;33m╗ \033[01;31m██\033[01;33m║  \033[01;33m╔\033[01;31m██\033[01;33m╗  \033[01;36m###"
echo "\033[01;36m###  \033[01;31m██\033[01;33m║     \033[01;31m██\033[01;33m╔══\033[01;31m██\033[01;33m║    \033[01;31m██\033[01;33m║   \033[01;31m██\033[01;33m║\033[01;31m██\033[01;33m╔══╝  \033[01;31m██\033[01;33m║╚\033[01;31m██\033[01;33m╗\033[01;31m██\033[01;33m║ \033[01;31m██████ \033[01;36m###"
echo "\033[01;36m###  \033[01;33m╚\033[01;31m██████\033[01;33m╗\033[01;31m██\033[01;33m║  \033[01;31m██\033[01;33m║    ╚\033[01;31m██████\033[01;33m╔╝\033[01;31m███████\033[01;33m╗\033[01;31m██\033[01;33m║ ╚\033[01;31m████\033[01;33m║  \033[01;33m╚\033[01;31m██\033[01;33m╝  \033[01;36m###"
echo "\033[01;36m####  \033[01;33m╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝╚═╝  ╚═══╝       \033[01;36m####"
echo "\033[01;36m#####  \033[01;37mLet's get you a legit self-signed Certificate!     \033[01;36m#####"
echo "\033[01;36m###############################################################"



# Variable Assignments
echo ""
echo "\033[01;37mPlease provide the following information for the Certificate Signing Request:"
echo ""
read -p "Please provide the requesting user's Country: " Country
read -p "Please provide the requesting user's State: " State
read -p "Please provide the requesting user's City: " Locality
read -p "Please provide the requesting user's Company: " Company
read -p "Please provide the requesting user's Legal Name: " UserRealName
read -p "Please provide the requesting user's Domain: " UserWebSite

# Generate a private key
openssl genrsa -out /opt/server/ca/ca.key 2048

# Generate a Certificate Signing Request
openssl req -new -key /opt/server/ca/ca.key -out /opt/server/ca/ca.csr -subj "/C=US/ST=Texas/L=Silsbee/O=Matthew Rackley/CN=www.rackley.app"

# Generate a self-signed certificate
openssl x509 -req -days 365 -in /opt/server/ca/ca.csr -signkey /opt/server/ca/ca.key -out /opt/server/ca/ca.crt

if [ -z "$altDomain" ]
then
  # Generate a certificate for the server
  openssl genrsa -out /opt/server/ca/server.key 2048
  openssl req -new -key /opt/server/ca/server.key -out /opt/server/ca/server.csr -subj "/C=$Country/ST=$State/L=$Locality/O=$Company/CN=$UserWebSite"
  openssl x509 -req -days 365 -in /opt/server/ca/server.csr -CA /opt/server/ca/ca.crt -CAkey /opt/server/ca/ca.key -set_serial 01 -out /opt/server/ca/server.crt
else
  # Generate a certificate for the server
  openssl genrsa -out /opt/server/ca/server.key 2048
  openssl req -new -key /opt/server/ca/server.key -out /opt/server/ca/server.csr -subj "/C=$Country/ST=$State/L=$Locality/O=$Company/CN=$UserWebSite" -addext "subjectAltName=DNS:$altDomain"
  openssl x509 -req -days 365 -in /opt/server/ca/server.csr -CA /opt/server/ca/ca.crt -CAkey /opt/server/ca/ca.key -set_serial 01 -out /opt/server/ca/server.crt
fi


# Generate a fullchain for the server
cat /opt/server/ca/server.crt /opt/server/ca/ca.crt > /opt/server/ca/fullchain.pem

# Generate a certificate for the client
openssl genrsa -out /opt/server/ca/client.key 2048
openssl req -new -key /opt/server/ca/client.key -out /opt/server/ca/client.csr -subj "/C=$Country/ST=$State/L=$Locality/O=$Company/CN=$UserRealName"
openssl x509 -req -days 365 -in /opt/server/ca/client.csr -CA /opt/server/ca/ca.crt -CAkey /opt/server/ca/ca.key -set_serial 02 -out /opt/server/ca/client.crt

rm /opt/server/ca/ca.csr
rm /opt/server/ca/ca.crt
rm /opt/server/ca/ca.key
rm /opt/server/ca/server.csr
rm /opt/server/ca/client.csr
