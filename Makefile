NAME = fosskiit
FQDN = $(NAME).org
MAIL = contact@$(FQDN)

site:
	@echo Generating website ...
	hugo
	mv public _site
	@echo Done; echo

local: site
	@echo Running website locally ...
	cd _site && python3 -m http.server
	@echo Done; echo

live: site
	@echo Setting up live directory ...
	mv _live _gone || :
	mv _site _live
	rm -rf _gone
	@echo Done; echo

checkroot:
	@echo Checking if current user is root ...
	[ $$(id -u) = 0 ]
	@echo Done; echo

rm: checkroot
	@echo Removing website ...
	rm -f /etc/nginx/sites-enabled/$(FQDN)
	rm -f /var/www/$(FQDN)
	systemctl reload nginx
	sed -i '/$(NAME)/d' /etc/hosts
	#
	# Following crontab entries left intact:
	crontab -l | grep -v "^#" || :
	@echo Done; echo

http: rm live
	@echo Setting up HTTP website ...
	rm -f /etc/nginx/sites-enabled/$(FQDN)
	ln -snf "$$PWD/_live" /var/www/$(FQDN)
	ln -snf "$$PWD/etc/nginx/http.$(FQDN)" /etc/nginx/sites-enabled/$(FQDN)
	systemctl reload nginx
	echo 127.0.0.1 $(NAME) >> /etc/hosts
	@echo Done; echo

https: http
	@echo Setting up HTTPS website ...
	certbot certonly -n --agree-tos -m $(MAIL) --webroot \
	                 -w /var/www/$(FQDN) -d $(FQDN),www.$(FQDN)
	(crontab -l | sed '/certbot/d'; cat etc/crontab) | crontab
	ln -snf "$$PWD/etc/nginx/https.$(FQDN)" /etc/nginx/sites-enabled/$(FQDN)
	systemctl reload nginx
	@echo Done; echo
