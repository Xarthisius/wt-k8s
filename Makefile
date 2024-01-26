.PHONY: clean dirs dev prep

prep:
	kubectl create namespace wt
	kubectl create secret -n wt docker-registry local-registry-secret \
		--docker-server=registry.wt.xarthisius.xyz \
		--docker-username=fido \
		--docker-password=secretpass \
		--docker-email=xarthisius.kk@gmail.com
	kubectl apply -f volumes/
	kubectl label node tns-multi-test-worker smarter-device-manager=enabled || /bin/true
	kubectl apply -f device-manager-setup/01-smarter-device-manager-ns.yaml
	kubectl apply -f device-manager-setup/02-smarter-device-manager-configmap.yaml
	kubectl apply -f device-manager-setup/03-smarter-device-manager-ds-with-configmap.yaml

dev:
	kubectl exec -n wt -ti $$(kubectl get pods -n wt -l app=girder -o name) girder-install plugin \
		plugins/wt_data_manager \
		plugins/wholetale \
		plugins/wt_home_dir \
		plugins/globus_handler \
		plugins/virtual_resources \
		plugins/wt_versioning \
		plugins/sem_viewer \
		plugins/dataflows \
		plugins/table_view
	kubectl exec -n wt -ti $$(kubectl get pods -n wt  -l app=girder -o name) -- girder-install web --dev --plugins=oauth,gravatar,jobs,worker,wt_data_manager,wholetale,wt_home_dir,globus_handler,sem_viewer,table_view,dataflows
	kubectl exec -n wt -ti $$(kubectl get pods -n wt  -l app=girder -o name) -- pip install -r /gwvolman/requirements.txt -e /gwvolman
	kubectl exec -n wt -ti $$(kubectl get pods -n wt  -l app=girder -o name) -- pip install -e /girderfs
	./setup_girder.py

clean:
	kubectl delete -f volumes/
	kubectl delete -f device-manager-setup/03-smarter-device-manager-ds-with-configmap.yaml
	kubectl delete -f device-manager-setup/02-smarter-device-manager-configmap.yaml
	kubectl delete -f device-manager-setup/01-smarter-device-manager-ns.yaml
	kubectl delete secret -n wt local-registry-secret
	kubectl delete namespace wt

reset_girder:
	kubectl exec -n wt -ti $$(kubectl get pods -n wt  -l app=girder -o name) -- \
		python3 -c 'from girder.models import getDbConnection;getDbConnection().drop_database("girder")'
	kubectl exec -n wt -ti $$(kubectl get pods -n wt  -l app=girder -o name) -- \
	  touch /girder/girder/__init__.py
