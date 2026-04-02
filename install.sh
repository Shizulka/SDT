
if [ "$EUID" -ne 0 ]; then
  echo "Need sudo"
  exit 1
fi

apt-get update
apt-get install -y mariadb-server nginx python3 python3-pip python3-venv curl sudo


useradd -m -s /bin/bash -G sudo student
echo "student:studentpass" | chpasswd 

useradd -m -s /bin/bash -G sudo teacher
echo "teacher:12345678" | chpasswd
chage -d 0 teacher

useradd -r -s /bin/false app

useradd -m -s /bin/bash operator
echo "operator:12345678" | chpasswd
chage -d 0 operator


cat <<EOF > /etc/sudoers.d/operator
operator ALL=(ALL) NOPASSWD: /bin/systemctl start mywebapp, /bin/systemctl stop mywebapp, /bin/systemctl restart mywebapp, /bin/systemctl status mywebapp, /bin/systemctl reload nginx
EOF
chmod 440 /etc/sudoers.d/operator

mysql -e "CREATE DATABASE IF NOT EXISTS mywebapp;"
mysql -e "CREATE USER IF NOT EXISTS 'app'@'127.0.0.1' IDENTIFIED BY '12345678';"
mysql -e "GRANT ALL PRIVILEGES ON mywebapp.* TO 'app'@'127.0.0.1';"
mysql -e "FLUSH PRIVILEGES;"

APP_DIR="/opt/mywebapp"
mkdir -p $APP_DIR

cp -r ./* $APP_DIR/
chown -R app:app $APP_DIR

python3 -m venv $APP_DIR/venv
$APP_DIR/venv/bin/pip install -r $APP_DIR/requirements.txt
chown -R app:app $APP_DIR/venv

cat <<EOF > /etc/systemd/system/mywebapp.service
[Unit]
Description=MyWebApp Service
After=network.target mysql.service

[Service]
User=app
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python main.py --port 8000 --db-url mysql+pymysql://app:12345678@127.0.0.1:3306/mywebapp
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mywebapp
systemctl start mywebapp


cat <<EOF > /etc/nginx/sites-available/mywebapp
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/
systemctl restart nginx

echo "18" > /home/student/gradebook
chown student:student /home/student/gradebook
chmod 644 /home/student/gradebook

if [ -n "$SUDO_USER" ]; then
    passwd -l $SUDO_USER
fi

