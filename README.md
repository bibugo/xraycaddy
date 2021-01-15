# xraycaddy

```
docker run -d --name xraycaddy \
	-v /path/to/xraycaddy:/srv \
	-p 8443:443 -p 8080:80 \
	-e PUID={uid} -e PGID={gid} \
	-e DOMAIN={your domain} \
	-e CFKEY={your cloudflare global api token} \
	-e UUID={uuid} \
	bibugo/xraycaddy
```
