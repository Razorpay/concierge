package ingress_driver

import (
	"concierge/config"
	"concierge/pkg"
	"errors"
	log "github.com/sirupsen/logrus"
)

type LookerIngressDriver struct {
	ingress pkg.IngressList
}

var lookerIngressDriver *LookerIngressDriver

func getLookerIngressDriver() IngressDriver {
	host := config.LookerConfig.BaseUrl

	if lookerIngressDriver == nil {
		lookerIngressDriver = &LookerIngressDriver{ingress: struct {
			Name           string
			Namespace      string
			Context        string
			Host           string
			Class          string
			WhitelistedIps []string
		}{Name: Looker, Namespace: Looker, Context: DefaultContext, Host: host, Class: DefaultClass, WhitelistedIps: nil}}

	}
	return lookerIngressDriver
}

func (k *LookerIngressDriver) ShowAllowedIngress(ShowAllowedIngressRequest) (ShowAllowedIngressResponse, error) {
	resp := ShowAllowedIngressResponse{
		Ingresses: []pkg.IngressList{k.ingress},
	}

	return resp, nil
}

func (k *LookerIngressDriver) EnableUser(req EnableUserRequest) (EnableUserResponse, error) {
	log.Infof("Received Looker EnableUserRequest %v", req.User.Name)
	resp := EnableUserResponse{
		Ingress:    k.ingress,
		Identifier: req.User.Email,
	}

	client := pkg.GetLookerClient()

	users, searchErr := client.SearchUser(pkg.LookerSearchUserRequest{Email: req.User.Email})

	if searchErr != nil {
		return resp, searchErr
	}

	if len(users) == 0 {
		return resp, errors.New("You dont have a looker account. Please contact Looker admins")
	}

	if len(users) > 1 {
		return resp, errors.New("You have multiple looker accounts. Please contact looker admins")
	}

	user := users[0]

	if user.IsDisabled == false {
		return resp, errors.New("Looker user already enabled for user. Please visit looker.")
	}

	patchedUser, patchErr := client.PatchUser(user.Id, pkg.LookerPatchUserRequest{IsDisabled: false})

	if patchErr != nil {
		return resp, patchErr
	}

	if patchedUser.IsDisabled == true {
		return resp, errors.New("Failed to enable user. please contact admin")
	}

	resp.UpdateStatusFlag = true

	return resp, nil
}

func (k *LookerIngressDriver) DisableUser(req DisableUserRequest) (DisableUserResponse, error) {
	log.Infof("Received Looker DisableUserRequest %v", req.LeaseIdentifier)
	response := DisableUserResponse{}

	client := pkg.GetLookerClient()

	users, searchErr := client.SearchUser(pkg.LookerSearchUserRequest{Email: req.LeaseIdentifier})

	if searchErr != nil {
		return DisableUserResponse{Ingress: k.ingress}, searchErr
	}

	for _, user := range users {
		if user.IsDisabled {
			continue
		}

		patchedUser, patchErr := client.PatchUser(user.Id, pkg.LookerPatchUserRequest{IsDisabled: true})

		if patchErr != nil || patchedUser.IsDisabled == false {
			return response, errors.New("failed to delete lease. contact looker admin")
		}
	}

	response.UpdateStatusFlag = true

	return response, nil
}

func (k *LookerIngressDriver) ShowIngressDetails(ShowIngressDetailsRequest) (ShowIngressDetailsResponse, error) {
	return ShowIngressDetailsResponse{Ingress: k.ingress}, nil
}

func (k *LookerIngressDriver) GetName() string {
	return Looker
}

func (k *LookerIngressDriver) isEnabled() bool {
	return config.LookerConfig.IsEnabled
}
