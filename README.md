# security-tools

Generating a token
https://access.redhat.com/management/api

Information on the Red Hat APIs
https://access.redhat.com/articles/3626371
https://access.redhat.com/management/api/rhsm#/errata/listErratumPackages
https://access.redhat.com/articles/3626371#bresources-for-downloads-and-swagger-documentationb-8

API Test Curl
curl https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token -d grant_type=refresh_token -d client_id=rhsm-api -d refresh_token=$offline_token

