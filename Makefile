include ./.env
export

init::
	@terraform -chdir=tf init

deploy::
	terraform -chdir=tf apply --auto-approve

deploy-k8s::
	terraform -chdir=tf apply --target=module.k8s --auto-approve

deploy-mdb::
	terraform -chdir=tf apply --target=module.mdb --auto-approve

destroy::
	terraform -chdir=tf destroy --auto-approve

apply-k8s::
	kubectl apply -f k8s/