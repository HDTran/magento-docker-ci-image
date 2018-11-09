# Deity Falcon Magento 2 CI Docker image 

This is a fully contained docker image created for CI purposes.
It contains 
- MarriaDB
- Mangento Community edition 
- Deity-io/falcon-magento2-module
- Magento Sample Data 

# Build 
The image uses build arguments to configure the environment. All the internal ones are pre-defined. 
The ones that affect the interaction with this image should be provided. 

An example of using these build arguments can be found in the bin/build.sh file with the build_env environment file.

The main argument to be set is the MAGENTO_URL. this is needed if you want to access the backend. The correct bound port should be provided 

The build requires a `auth.json  with the composer credentials to access the magento repo.

And the build requires a id_rsa fiel with a private ssh key to access the deity github repo.

Copy these files to the root folder of the repo before building.
These files will not be availible in the final image, (they are used and then removed) although might be accessablwe in the history. Still need to examine them 


Please note that changes in the magento or in the falcon-magento2-module aren't detected and wont invalidate cache. a build with the no-cache option is needed to be sure you fetched the last one

# Additinal commands 
```bash
`bin/up.sh`
```
Make and bring up a countainer with the ports exposed


```bash
`bin\magento.sh`
```
Proxy to the bin/magento console. 

# Technical dept
- Current image size is to large 2.7GIG (build option -compress doesn't help)
- Not sure is authetication files are viewable from a build image 
- should add labels 
- make it configurabel wich repo's / versions to use 
