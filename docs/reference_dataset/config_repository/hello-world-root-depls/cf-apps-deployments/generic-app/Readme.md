# Generic-App 

This is a deployable CF application

## Dir structure
```
.
├── enable-cf-app.yml                    ==> marker file with CF required info to deploy application (api url, org, space, etc...)
├── secrets                              ==>
│   └── secrets.yml                      ==> use to defined *configuration* values used by spruce (prefer credhub for sensitive data)
└── spruce-file-sample-from-secrets.txt  ==> file to illustrate spruce file command ((file ...)) from config repository
```
