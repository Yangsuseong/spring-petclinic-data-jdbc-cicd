openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout ./tls.key -out ./tls.crt -subj "/CN=test.example.com" 

kubectl create secret tls --save-config petclinic-tls --key ./tls.key --cert ./tls.crt
