# xraycaddy

```
docker run -d --name xraycaddy \
	-v /path/to/xraycaddy:/srv \
	-p 8443:443 -p 8080:80 \
	-e PUID={uid} -e PGID={gid} \
	-e TZ={time zone} \
	-e DOMAIN={domain} \
	-e CFKEY={cloudflare global api key} \
	-e UUID={uuid} \
	bibugo/xraycaddy
```
